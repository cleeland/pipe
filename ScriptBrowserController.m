#import "ScriptBrowserController.h"
#import "KwikiController.h"
#import "ScriptBrowserDocument.h"
#import "ScriptEditorDocument.h"
#import "ScriptReference.h"
#import "DataView.h"
#import "ScriptDocument+Running.h"
#import "UserDefaults.h"
#import "VariablesTableController.h"

#import <JaguarAppKit/JaguarAppKit.h>

@implementation ScriptBrowserController

static NSString * const ScriptBrowserToolbarIdentifier = @"ScriptBrowserToolbarIdentifier";
static NSString * const ScriptBrowserOpenHomePageItemIdentifier = @"ScriptBrowserOpenHomePageItemIdentifier";
static NSString * const ScriptBrowserToggleUsageInformationItemIdentifier = @"ScriptBrowserToggleUsageInformationItemIdentifier";

static NSString * const ScriptModificationDateContext = @"ScriptModificationDateContext";
static NSString * const ScriptSelectionContext = @"ScriptSelectionContext";

#pragma mark Init and Cleanup

- (id)init
{
	if ((self = [super initWithWindowNibName:@"ScriptBrowser"])) {
		[self setShouldCloseDocument:NO];
	}
	return self;
}

- (NSString *)toolbarIdentifier
{
	return ScriptBrowserToolbarIdentifier;
}

- (void)windowDidLoad
{
	NSNumber *lastScriptSelectionIndex;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:NSApp];

	[[self window] setFrameAutosaveName:@"ScriptBrowser"];
	[self restoreWindowLayout];
	
	[scriptBrowserTableView setDoubleAction:@selector(scriptDoubleClicked:)];
	[scriptBrowserTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	[scriptBrowserTableView setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
	[[[scriptBrowserTableView tableColumnWithIdentifier:@"name"] dataCell] setMenu:scriptContextualMenu];
	[scriptBrowserTableView setMenu:scriptContextualMenu];
	[scriptBrowserTableView setSelectsRowOnRightMouseDown:YES];
	
	if ((lastScriptSelectionIndex = JGUserDefaultValue(PipeLastSelectedScriptBrowserIndexDefaultKey))) {
		if ([lastScriptSelectionIndex unsignedCharValue] < [[scriptsController arrangedObjects] count]) {
			[scriptsController setSelectionIndex:[lastScriptSelectionIndex unsignedIntValue]];
		}
	}

	[super windowDidLoad];
	
	[variablesTableController setEditable:NO];
	
	[[self window] makeFirstResponder:inputTextView];

	[scriptsController addObserver:self forKeyPath:@"selectionIndex" options:0 context:ScriptSelectionContext];
	[scriptsController addObserver:self forKeyPath:@"selection.lastModificationDate" options:0 context:ScriptModificationDateContext];
	[self loadSelectedScript:self];
}

- (void)dealloc
{
	[scriptsController removeObserver:self forKeyPath:@"selectionIndex"];
	[scriptsController removeObserver:self forKeyPath:@"selection.lastModificationDate"];
	[super dealloc];
}

#pragma mark Accessors

- (KwikiController *)kwikiController
{
	return [KwikiController sharedController];
}

#pragma mark Actions

- (IBAction)showWindow:(id)sender
{
	if (shouldRestoreInfoDrawer)
		[infoDrawer open];
	[super showWindow:sender];
}

- (IBAction)addToScriptBrowser:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSEnumerator *fileEnumerator;
	NSString *currentFile;
	KwikiController *kwikiController = [KwikiController sharedController];
	ScriptReference *newReference;
	
	[openPanel setMessage:NSLocalizedString(@"Add Script to Browser", @"Script browser open panel")];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"pipe", @"fpipe", nil]];
	[openPanel setAllowsMultipleSelection:YES];
	if ([openPanel runModal] == NSOKButton) {
		fileEnumerator = [[openPanel filenames] objectEnumerator];
		while ((currentFile = [fileEnumerator nextObject])) {
			if ([kwikiController indexOfKwikiWithPath:currentFile] == NSNotFound) {
				newReference = [[ScriptReference alloc] initWithPath:currentFile];
				[kwikiController insertObject:newReference inKwikisAtIndex:[kwikiController countOfKwikis]];
				[newReference release];
			}
		}
	}
}

- (IBAction)delete:(id)sender
{
	[scriptsController remove:self];
}

- (IBAction)focusScript:(id)sender
{
	[[self window] makeFirstResponder:scriptBrowserTableView];
}

- (void)scriptDoubleClicked:(id)sender
{
	if (![sender currentEventIsInHeaderView])
		[[self document] openLoadedScript:self];
}

- (void)loadSelectedScript:(id)sender
{
	ScriptReference *newReference;
	NSString *fileName;
	unsigned int selectionIndex;
	NSAlert *alert;
	
	// Check if there is a selection.
	selectionIndex = [scriptsController selectionIndex];
	if (selectionIndex != NSNotFound) {
		newReference = [[scriptsController arrangedObjects] objectAtIndex:selectionIndex];
		// Find the file name of this script reference.
		fileName = [newReference path];
		if (fileName == nil || JGPathIsInTrash(fileName)) {
			// The script was probably deleted. Ask the user if they want to remove it from their favorites list.
			alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setMessageText:NSLocalizedString(@"Could not find script", @"Script browser error message")];
			[alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The script named \"%@\" seems to have been deleted. Would you like to remove it from your list?", @"Script browser error message"), [newReference name]]];
			[alert addButtonWithTitle:NSLocalizedString(@"Remove", @"Script browser 'script not found' alert dialog button")];
			[alert addButtonWithTitle:NSLocalizedString(@"Keep", @"Script browser 'script not found' alert dialog button")];
			if ([alert runModal] == NSAlertFirstButtonReturn) {
				// Remove the script.
				[scriptsController removeObjectAtArrangedObjectIndex:selectionIndex];
				return;
			}
			[alert release];
		} else {
			ScriptDocument *newDocument;
			NSString *docType;
						
			docType = [[NSDocumentController sharedDocumentController] typeFromFileExtension:[fileName pathExtension]];
			if (docType != nil) {
				newDocument = [[ScriptEditorDocument alloc] initWithContentsOfFile:fileName ofType:docType];

				[[self document] loadScript:newDocument];
				[newDocument release];
				[[self document] autoRunScript:self];
			}
		}
	}
}

- (IBAction)revealScriptInFinder:(id)sender
{
	NSString *scriptPath;
	
	scriptPath = [[[self document] lastScriptAlias] path];
	if (scriptPath != nil) 
		[[NSWorkspace sharedWorkspace] selectFile:scriptPath inFileViewerRootedAtPath:@""]; 
}

- (IBAction)renameScript:(id)sender
{
	ScriptReference *selectedReference;
	unsigned selectionIndex;
	NSString *name;
	JGInputRequest *request;
	
	selectionIndex = [scriptsController selectionIndex];
	if (selectionIndex != NSNotFound) {
		selectedReference = [[scriptsController arrangedObjects] objectAtIndex:selectionIndex];
		
		name = [[[selectedReference path] lastPathComponent] stringByDeletingPathExtension];
		request = [[JGInputRequest alloc] init];
		[request setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Rename script '%@' to:", @"Rename script dialog message"), name]];
		[request setInputString:name];
		[request setAllowsEmptyInputString:NO];
		[request beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(renameScriptDidEnd:returnCode:contextInfo:) contextInfo:selectedReference];
	}
}

- (void)renameScriptDidEnd:(JGInputRequest *)request returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	ScriptReference *selectedReference;
	NSString *newName;
	NSString *pathExtension;
	BOOL exists, success;
	NSAlert *alert;
	
	NSParameterAssert(contextInfo != NULL);
	
	if (returnCode == NSOKButton) {
		selectedReference = (ScriptReference *)contextInfo;
		pathExtension = [[selectedReference path] pathExtension];
		newName = [[[[selectedReference path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[request inputString]] stringByAppendingPathExtension:pathExtension];
		
		exists = [[NSFileManager defaultManager] fileExistsAtPath:newName];
		if (!exists) {
			success = [[NSFileManager defaultManager] movePath:[selectedReference path] toPath:newName handler:nil];
			if (success)
				[selectedReference updateFromPath:newName];
			[scriptsController rearrangeObjects];
		}
		else {
			alert = [[NSAlert alloc] init];
			[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Failed to rename script '%@'", @"Script browser error message"), [[NSFileManager defaultManager] displayNameAtPath:[selectedReference path]]]];
			[alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"A script with the name '%@' already exists in the directory '%@'.", @"Script browser error message"), [[NSFileManager defaultManager] displayNameAtPath:newName], [newName stringByDeletingLastPathComponent]]];
			[alert addButtonWithTitle:NSLocalizedString(@"OK", @"Script browser rename error dialog button")];
			[alert runModal];
			[alert release];
		}
	}
}

#pragma mark User Interface Validation

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(addToScriptBrowser:)) {
		[anItem setTitle:NSLocalizedString(@"Add to Script Browser...", "Menu item for choosing a script to add to the script browser")];
		return YES;
	}
	else if (action == @selector(renameScript:)) {
		return [scriptsController selectionIndex] != NSNotFound;
	}
	else return YES;
}

#pragma mark Notifications

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	[[scriptsController selectedObjects] makeObjectsPerformSelector:@selector(checkForUpdate)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == ScriptSelectionContext) {
		JGSetUserDefaultValue(PipeLastSelectedScriptBrowserIndexDefaultKey, [NSNumber numberWithInt:[scriptsController selectionIndex]]);
		[self loadSelectedScript:self];
//		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadSelectedScript:) object:self];
//		[self performSelector:@selector(loadSelectedScript:) withObject:self afterDelay:0.2];
	}
	else if (context == ScriptModificationDateContext) {
		[self loadSelectedScript:self];
//		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadSelectedScript:) object:self];
//		[self performSelector:@selector(loadSelectedScript:) withObject:self afterDelay:0.2];
	}
}

#pragma mark Drag & Drop

- (NSArray *)validFileNamesFromDraggingInfo:(id <NSDraggingInfo>)info
{
    NSPasteboard *pboard;
	NSEnumerator *fileEnumerator;
	NSString *currentFile;
	NSMutableArray *validFileNames;
		
	pboard = [info draggingPasteboard];
	validFileNames = [NSMutableArray array];

    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		fileEnumerator = [[pboard propertyListForType:NSFilenamesPboardType] objectEnumerator];
		while ((currentFile = [fileEnumerator nextObject])) {
			if ([[KwikiController sharedController] indexOfKwikiWithPath:currentFile] == NSNotFound) {
				[validFileNames addObject:currentFile];
			}
		}
    }
	
	return validFileNames;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSArray *validFileNames;
	
	validFileNames = [self validFileNamesFromDraggingInfo:info];
	if ([validFileNames count] > 0) {
		[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
		return NSDragOperationLink;
	}
	else
		return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSArray *validFileNames;
	
	validFileNames = [self validFileNamesFromDraggingInfo:info];
	NSEnumerator *fileEnumerator;
	NSString *currentFile;
	ScriptReference *reference;
	
	if (row < 0)
		row = 0;
	
	fileEnumerator = [validFileNames objectEnumerator];
	while ((currentFile = [fileEnumerator nextObject])) {
		reference = [[ScriptReference alloc] initWithPath:currentFile];
		[scriptsController insertObject:reference atArrangedObjectIndex:row];
		[reference release];
    }
	[scriptsController rearrangeObjects];
	
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
	NSMutableArray *fileNames = [NSMutableArray array];
	NSEnumerator *rowEnumerator;
	NSNumber *currentRow;
	ScriptReference *reference;
	
	rowEnumerator = [rows objectEnumerator];
	while ((currentRow = [rowEnumerator nextObject])) {
		reference = [[scriptsController arrangedObjects] objectAtIndex:[currentRow unsignedIntValue]];
		[fileNames addObject:[reference path]];
	}
	
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
	[pboard setPropertyList:[[fileNames copy] autorelease] forType:NSFilenamesPboardType];

	return YES;
}

- (unsigned int)extendedTableView:(JGExtendedTableView *)aTableView draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if (isLocal)
		return NSDragOperationNone;
	else
		return NSDragOperationCopy | NSDragOperationLink | NSDragOperationMove;
}

#pragma mark Window Delegate

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self saveWindowLayout];
	shouldRestoreInfoDrawer = ([infoDrawer state] == NSDrawerOpenState);
	[infoDrawer close];
}

- (void)restoreWindowLayout
{
	id defaults;
	id property;
	
	defaults = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"browserWindowLayout"];
	
	if (defaults != nil) {
		if ((property = [defaults objectForKey:@"horizontalSplitRatio"])) 
			[horizontalSplitView adjustSubviewsWithRatio:[property floatValue]];
		if ((property = [defaults objectForKey:@"verticalSplitRatio"])) 
			[verticalSplitView adjustSubviewsWithRatio:[property floatValue]];
	}
}

- (void)saveWindowLayout
{
	NSMutableDictionary *defaults;
	
	defaults = [NSMutableDictionary dictionary];
	[defaults setValue:[NSNumber numberWithFloat:[horizontalSplitView subviewRatio]] forKey:@"horizontalSplitRatio"];
	[defaults setValue:[NSNumber numberWithFloat:[verticalSplitView subviewRatio]] forKey:@"verticalSplitRatio"];
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:defaults forKey:@"browserWindowLayout"];
	[[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
}

#pragma mark Table View Delegate

- (BOOL)extendedTableView:(JGExtendedTableView *)aTableView shouldHandleKeyDown:(NSEvent *)event
{
	if (aTableView == scriptBrowserTableView) {
		if ([[event characters] characterAtIndex:0] == NSDeleteFunctionKey) {
			[scriptsController remove:self];
			return NO;
		}
	}
	return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSDictionary *stringAttributes;
	NSMutableParagraphStyle *paragraphStyle;
	NSAttributedString *attributedString;
	
	if ([[aTableColumn identifier] isEqualToString:@"name"]) {
		paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
		
		stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			paragraphStyle, NSParagraphStyleAttributeName,
			nil];
		[paragraphStyle release];
		
		attributedString = [[NSAttributedString alloc] initWithString:[aCell stringValue] attributes:stringAttributes];
		[aCell setWraps:YES];
		[aCell setAttributedStringValue:attributedString];
		[attributedString release];
	}
}

#pragma mark Toolbar

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [[super toolbarAllowedItemIdentifiers:toolbar] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
		ScriptBrowserOpenHomePageItemIdentifier,
		ScriptBrowserToggleUsageInformationItemIdentifier,
		nil]];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		ScriptRunToolbarItemIdentifier,
		ScriptStopToolbarItemIdentifier,
		ScriptReverseTransformationToolbarItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		ScriptOutputToInputToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		ScriptBrowserOpenHomePageItemIdentifier,
		ScriptToggleInfoToolbarItemIdentifier,
		nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item;
	
	item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	if ([itemIdentifier isEqualToString:ScriptBrowserOpenHomePageItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Script Home Page", @"Script browser toolbar button")];
		[item setImage:[NSImage imageNamed:@"Home Page Icon"]];
		[item setAction:@selector(openScriptHomePage:)];
		[item setTarget:nil];
	}
	else return [super toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
	
	if ([item paletteLabel] == nil || [[item paletteLabel] isEqualToString:@""])
		[item setPaletteLabel:[item label]];
	
	return item;
}

@end
