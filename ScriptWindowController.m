#import "ScriptWindowController.h"
#import "ScriptBrowserDocument.h"
#import "ScriptEditorDocument.h"
#import "ScriptDocument+Running.h"
#import "ScriptReference.h"
#import "KwikiController.h"
#import "ScriptPropertyEditingController.h"
#import "DataView.h"
#import "UserDefaults.h"
#import "VariablesTableController.h"
#import "ScriptVariable.h"
#import "SupportFilesWindowController.h"

#import <JaguarFoundation/JaguarFoundation.h>
#import <JaguarAppKit/JaguarAppKit.h>

@implementation ScriptWindowController

static NSString * const ScriptWindowToolbarIdentifier = @"ScriptWindowToolbarIdentifier";
static NSString * const ScriptWindowToggleErrorsDrawerItemIdentifier = @"ScriptWindowToggleErrorsDrawerItemIdentifier";

#pragma mark Init and Cleanup

- (id)init
{
	if ((self = [super initWithWindowNibName:@"ScriptWindow"])) {
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString *)toolbarIdentifier
{
	return ScriptWindowToolbarIdentifier;
}

- (void)windowDidLoad
{
	id newView;
	NSPopUpButton *cornerButton;
	NSMenu *variablesMenu, *variableTypesMenu;
	NSMenuItem *menuItem;
	float width, height;
	
	[errorsTextView setRichText:NO];
	[errorsTextView setUsesFontPanel:NO];
	[errorsTextView setUsesRuler:NO];
	[errorsTextView setUsesFindPanel:YES];

	// Configure the input text view
	newView = [JGExtendedTextView fullyConfiguredTextView];
	[newView setFrame:[scriptTextView frame]];
	[[scriptTextView superview] replaceSubview:scriptTextView with:newView];
	scriptTextView = [newView documentView];
	[scriptTextView setDelegate:self];
	[scriptTextView setRichText:NO];
	[scriptTextView setUsesFontPanel:NO];
	[scriptTextView setUsesFindPanel:YES];
	[scriptTextView setUsesRuler:NO];
	[scriptTextView setAllowsUndo:YES];
	[scriptTextView bind:@"lineNumbersVisible" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeLineNumbersDefaultKey] options:nil];
	[scriptTextView bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey] options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	[scriptTextView bind:@"value" toObject:documentController withKeyPath:@"selection.script" options:nil];
	[scriptTextView bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeScriptBackgroundColorDefaultKey] options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	[scriptTextView bind:@"autoIndents" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeAutoIndentDefaultKey] options:nil];
	[scriptTextView bind:@"softWraps" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeSoftWrapDefaultKey] options:nil];
	[[scriptTextView enclosingScrollView] bind:@"verticalLineScroll" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey] options:[NSDictionary dictionaryWithObject:JGFontLineHeightTransformerName forKey:@"NSValueTransformerName"]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidUpdateFromExternalEditor:) name:JGExtendedTextViewDidUpdateFromExternalEditorNotification object:scriptTextView];
	
	[variablesTableController setEditable:YES];
	
	[super windowDidLoad];
	
	variableTypesMenu = [[NSMenu alloc] initWithTitle:@"Variable Types"];
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTitle:NSLocalizedString(@"Text", @"Variable type")];
	[menuItem setAction:@selector(switchVariableType:)];
	[menuItem setTarget:variablesTableController];
	[menuItem setTag:ScriptTextVariableType];
	[variableTypesMenu addItem:menuItem];
	[menuItem release];
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTitle:NSLocalizedString(@"Password", @"Variable type")];
	[menuItem setAction:@selector(switchVariableType:)];
	[menuItem setTarget:variablesTableController];
	[menuItem setTag:ScriptPasswordVariableType];
	[variableTypesMenu addItem:menuItem];
	[menuItem release];
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTitle:NSLocalizedString(@"Boolean", @"Variable type")];
	[menuItem setAction:@selector(switchVariableType:)];
	[menuItem setTarget:variablesTableController];
	[menuItem setTag:ScriptBooleanVariableType];
	[variableTypesMenu addItem:menuItem];
	[menuItem release];
	menuItem = [[NSMenuItem alloc] init];
	[menuItem setTitle:NSLocalizedString(@"Enumeration", @"Variable type")];
	[menuItem setAction:@selector(switchVariableType:)];
	[menuItem setTarget:variablesTableController];
	[menuItem setTag:ScriptEnumVariableType];
	[variableTypesMenu addItem:menuItem];
	[menuItem release];
	[variableTypesMenu autorelease];
	
	variablesMenu = [[NSMenu alloc] initWithTitle:@""];
	[variablesMenu addItemWithTitle:@"" action:NULL keyEquivalent:@""];
	[[variablesMenu addItemWithTitle:NSLocalizedString(@"Add Variable", @"Menu item for adding a new variable") action:@selector(add:) keyEquivalent:@""] setTarget:variablesTableController];
	[[variablesMenu addItemWithTitle:NSLocalizedString(@"Remove Variable", @"Menu item for deleting a variable") action:@selector(remove:) keyEquivalent:@""] setTarget:variablesTableController];
	[variablesMenu addItem:[NSMenuItem separatorItem]];
	[[variablesMenu addItemWithTitle:NSLocalizedString(@"Variable Type", @"Item in variables menu") action:NULL keyEquivalent:@""] setSubmenu:variableTypesMenu];
	[[variablesMenu addItemWithTitle:NSLocalizedString(@"Enumeration Values...",  @"Menu item for configuring enumeration values of a variable") action:@selector(configureEnumValues:) keyEquivalent:@""] setTarget:variablesTableController];
	[variablesMenu autorelease];
	
	cornerButton = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES];
	width = NSWidth([[[variablesTableView enclosingScrollView] verticalScroller] frame]);
	height = NSHeight([[variablesTableView headerView] frame]);
	[cornerButton setFrameSize:NSMakeSize(width, height)];
	[cornerButton setBezelStyle:NSShadowlessSquareBezelStyle];
	[cornerButton setMenu:variablesMenu];
	[variablesTableView setCornerView:cornerButton];
	[cornerButton release];	
}

#pragma mark Accessors

- (void)setDocument:(NSDocument *)newDocument
{
	if (newDocument != [self document]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[self document]];
		[super setDocument:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performErrorNotification:) name:ScriptDocumentErrorNotification object:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptDocumentWillRun:) name:ScriptDocumentWillRunNotification object:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptDocumentWillSave:) name:ScriptDocumentWillSaveNotification object:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptDocumentWillRevert:) name:ScriptDocumentWillRevertNotification object:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptDocumentCollectSavedPropertyList:) name:ScriptEditorDocumentCollectSavedPropertyListNotification object:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptDocumentApplySavedPropertyList:) name:ScriptEditorDocumentApplySavedPropertyListNotification object:newDocument];
	}
}

- (NSDictionary *)savedPropertyList
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[[self window] stringWithSavedFrame], @"savedFrame",
		[NSNumber numberWithFloat:[horizontalSplitView subviewRatio]], @"horizontalSplitRatio",
		[NSNumber numberWithFloat:[verticalSplitView subviewRatio]], @"verticalSplitRatio",
		[NSNumber numberWithBool:([infoDrawer state] == NSDrawerOpenState)], @"infoDrawerOpen",
		NSStringFromRange([scriptTextView selectedRange]), @"selectedScriptRange",
		NSStringFromRange([inputTextView selectedRange]), @"selectedInputRange",
		nil];
}

- (void)applySavedPropertyList:(NSDictionary *)propertyList
{
	id property;
	
	if (propertyList != nil) {
		if ((property = [propertyList objectForKey:@"savedFrame"])) {
			// Do not restore the saved frame if this is a new document (e.g. based on a template)
			if ([[self document] fileName] != nil)
				[[self window] setFrameFromString:property];
		}
		if ((property = [propertyList objectForKey:@"horizontalSplitRatio"]))
			[horizontalSplitView adjustSubviewsWithRatio:[property floatValue]];
		if ((property = [propertyList objectForKey:@"verticalSplitRatio"]))
			[verticalSplitView adjustSubviewsWithRatio:[property floatValue]];
		if ((property = [propertyList objectForKey:@"selectedScriptRange"])) {
			[scriptTextView setSelectedRange:NSRangeFromString(property)];
			[scriptTextView scrollRangeToVisible:NSRangeFromString(property)];
		}
		if ((property = [propertyList objectForKey:@"selectedInputRange"])) {
			[inputTextView setSelectedRange:NSRangeFromString(property)];
			[inputTextView scrollRangeToVisible:NSRangeFromString(property)];
		}
		if ((property = [propertyList objectForKey:@"infoDrawerOpen"])) {
			if ([property boolValue])
				[infoDrawer open];
		}
	}
}

#pragma mark Actions

- (IBAction)toggleErrorsDrawer:(id)sender
{
	[errorsDrawer toggle:self];
}

- (IBAction)addToScriptBrowser:(id)sender
{
	ScriptReference *newReference;
	
	if ([[KwikiController sharedController] indexOfKwikiWithPath:[[self document] fileName]] == NSNotFound) {
		newReference = [[ScriptReference alloc] initWithPath:[[self document] fileName]];
		[[KwikiController sharedController] insertObject:newReference inKwikisAtIndex:[[KwikiController sharedController] countOfKwikis]];
		[newReference release];
	}
	else NSBeep();
}

- (IBAction)focusScript:(id)sender
{
	[[self window] makeFirstResponder:scriptTextView];
}

- (IBAction)editScriptSettings:(id)sender
{
	if ([[self window] makeFirstResponder:nil])
		[propertyEditingController beginSheet];
}

- (IBAction)editSupportFiles:(id)sender
{
	SupportFilesWindowController *windowController;
	
	windowController = [[SupportFilesWindowController alloc] init];
	[windowController setSupportFiles:[[self document] valueForKey:@"supportFiles"]];
	[windowController beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(editSupportFilesDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[windowController release];
}

- (void)editSupportFilesDidEnd:(SupportFilesWindowController *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[[[self document] mutableArrayValueForKey:@"supportFiles"] setArray:[sheet supportFiles]];
	}
}

#pragma mark User Interface Validation

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];
	unsigned scriptIndex;
	
	if (action == @selector(addToScriptBrowser:)) {
		[anItem setTitle:NSLocalizedString(@"Add to Script Browser", @"Menu item for adding the current script to the script browser")];
		if ([[self document] fileName] && [[self document] fileType]) {
			scriptIndex = [[KwikiController sharedController] indexOfKwikiWithPath:[[self document] fileName]];
			return scriptIndex == NSNotFound;
		}
		else
			return NO;
	}
	else if (action == @selector(toggleErrorsDrawer:)) {
		if ([errorsDrawer state] == NSDrawerOpenState)
			[anItem setTitle:NSLocalizedString(@"Hide Errors", @"Menu item for hiding the errors drawer")];
		else
			[anItem setTitle:NSLocalizedString(@"Show Errors", @"Menu item for showing the errors drawer")];
		return YES;
	}
	else if (action == @selector(saveScriptSourceToFile:)) {
		if ([anItem tag] == 1)
			return [[[self document] scriptSourceAlias] path] != nil;
		else
			return YES;
	}
	else return [self validateUserInterfaceItem:anItem];
}

#pragma mark Notifications

- (void)scriptDocumentApplySavedPropertyList:(NSNotification *)aNotification
{
	NSDictionary *propertyList;
	
	propertyList = [[aNotification userInfo] objectForKey:@"propertyList"];
	[self applySavedPropertyList:[propertyList objectForKey:PipeScriptEditorWindowPropertiesPlistKey]];
}

- (void)scriptDocumentCollectSavedPropertyList:(NSNotification *)aNotification
{
	NSMutableDictionary *propertyList;
	
	propertyList = [[aNotification userInfo] objectForKey:@"propertyList"];
	[propertyList setObject:[self savedPropertyList] forKey:PipeScriptEditorWindowPropertiesPlistKey];
}

- (void)scriptDocumentWillRun:(NSNotification *)aNotification
{
	[super scriptDocumentWillRun:aNotification];
	// workaround to prevent strange drawing glitch (AppKit bug?)
	[[errorsDrawer contentView] setNeedsDisplay:YES];
}

- (void)scriptDocumentWillSave:(NSNotification *)aNotification
{
	[self commitAllEditing];
}

- (void)scriptDocumentWillRevert:(NSNotification *)aNotification
{
	[self discardAllEditing];
}

- (void)performErrorNotification:(NSNotification *)aNotification
{
	[errorsDrawer open];
}

#pragma mark Toolbar

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [[super toolbarAllowedItemIdentifiers:toolbar] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
		ScriptWindowToggleErrorsDrawerItemIdentifier,
		nil]];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item;
	
	item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	if ([itemIdentifier isEqualToString:ScriptWindowToggleErrorsDrawerItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Errors", @"Toolbar item for toggling the errors drawer")];
		[item setImage:[NSImage imageNamed:@"Errors Button"]];
		[item setAction:@selector(toggleErrorsDrawer:)];
		[item setTarget:nil];
	}
	else return [super toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
	
	if ([item paletteLabel] == nil || [[item paletteLabel] isEqualToString:@""])
		[item setPaletteLabel:[item label]];
	
	return item;
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
		ScriptWindowToggleErrorsDrawerItemIdentifier,
		ScriptToggleInfoToolbarItemIdentifier,
		nil];
}

#pragma mark Text View Delegate

- (NSString *)fileExtensionForExternalEditorOfTextView:(JGExtendedTextView *)textView
{
	if (textView == scriptTextView)
		return [[[self document] preferredScriptFileName] pathExtension];
	else 
		return nil;
}

- (NSString *)customFilenameForExternalEditorOfTextView:(JGExtendedTextView *)textView
{
	NSMutableString *customFilename = [NSMutableString string];

	[customFilename setString:NSLocalizedString(@"Pipe: ", @"Prefix for external editor display name")];
	[customFilename appendString:[[self document] displayName]];
	[customFilename appendString:@": "];
	
	if (textView == scriptTextView)
		[customFilename appendString:NSLocalizedString(@"Script Source", @"External editor display name for script source")];
	else if (textView == inputTextView)
		[customFilename appendString:NSLocalizedString(@"Input", @"External editor display name for input")];
	
	return customFilename;
}

@end
