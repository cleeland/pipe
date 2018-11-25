//
//  SupportFilesWindowController.m
//  Pipe
//
//  Created by René Puls on 16.04.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SupportFilesWindowController.h"
#import "SupportFileReference.h"

@implementation SupportFilesWindowController

static NSArray *ConvertFilesToURLs(NSArray *files)
{
	NSEnumerator *enumerator;
	id currentObject;
	NSMutableArray *URLs = [NSMutableArray array];
	
	// Turn the array of file names (NSStrings) into NSURLs
	enumerator = [files objectEnumerator];
	while ((currentObject = [enumerator nextObject]))
		[URLs addObject:[NSURL fileURLWithPath:currentObject]];
	
	return URLs;
}

static NSArray *FilterURLs(NSArray *URLs, NSArray *supportFiles)
{
	NSMutableSet *myURLs = [NSSet setWithArray:[supportFiles valueForKeyPath:@"sourceAlias.url"]];
	NSEnumerator *newURLEnumerator = [URLs objectEnumerator];
	NSURL *currentURL;
	NSMutableArray *filteredURLs = [NSMutableArray array];

	while ((currentURL = [newURLEnumerator nextObject])) {
		if (![myURLs containsObject:currentURL])
			[filteredURLs addObject:currentURL];
	}
	
	return filteredURLs;
}

#pragma mark Init and Cleanup

- (id)init
{
	if ((self = [super initWithWindowNibName:@"SupportFiles"])) {
		supportFiles = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	NSAssert(endSheetInvocation == nil, @"Deallocating SupportFilesWindowController while sheet is running");
	[supportFiles release];
	[super dealloc];
}

- (void)windowDidLoad
{
	[filesTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

#pragma mark Accessors

- (NSArray *)supportFiles
{
	return supportFiles;
}

- (void)setSupportFiles:(NSArray *)newFiles
{
	if (newFiles == nil)
		[supportFiles removeAllObjects];
	else
		[supportFiles setArray:newFiles];
}

#pragma mark Window Management

- (void)beginSheetModalForWindow:(NSWindow *)aWindow modalDelegate:(id)delegate didEndSelector:(SEL)aSelector contextInfo:(void *)contextInfo;
{
	NSAssert(endSheetInvocation == nil, @"Sheet already running");
	
	endSheetInvocation = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:aSelector]];
	[endSheetInvocation setSelector:aSelector];
	[endSheetInvocation setTarget:delegate];
	[endSheetInvocation setArgument:&self atIndex:2];
	[endSheetInvocation setArgument:&contextInfo atIndex:4];
	[endSheetInvocation retainArguments];
	[endSheetInvocation retain];
	[NSApp beginSheet:[self window] modalForWindow:aWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[self retain];
}

- (void)sheetDidEnd:(NSWindow *)aWindow returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSAssert(endSheetInvocation != nil, @"Sheet not running");

	[[self window] orderOut:self];
	
	[endSheetInvocation setArgument:&returnCode atIndex:3];
	[endSheetInvocation invoke];
	[endSheetInvocation release];
	endSheetInvocation = nil;
	[self autorelease];
}

#pragma mark Actions

- (IBAction)addFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSEnumerator *fileEnumerator;
	NSURL *currentURL;
	SupportFileReference *newReference;
	NSMutableArray *array = [self mutableArrayValueForKey:@"supportFiles"];
	
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setAllowsMultipleSelection:YES];
	
	if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
		fileEnumerator = [FilterURLs([openPanel URLs], array) objectEnumerator];
		while ((currentURL = [fileEnumerator nextObject])) {
			newReference = [[SupportFileReference alloc] init];
			[newReference setSourceAlias:[NDAlias aliasWithURL:currentURL]];
			[array addObject:newReference];
			[newReference release];
		}
	}
}

- (IBAction)okay:(id)sender
{
	[NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)save:(id)sender
{
	NSArray *selectedFiles;
	int result;
	
	selectedFiles = [supportFilesArrayController selectedObjects];
	
	if ([selectedFiles count] == 1) {
		NSSavePanel *panel;
		panel = [NSSavePanel savePanel];
		result = [panel runModalForDirectory:nil file:[[[selectedFiles lastObject] fileWrapper] preferredFilename]];
		if (result == NSOKButton) {
			[[[selectedFiles lastObject] fileWrapper] writeToFile:[panel filename] atomically:YES updateFilenames:NO];
		}
	} else {
		NSOpenPanel *panel;
		NSEnumerator *filenameEnumerator;
		NSString *currentFileName;
		SupportFileReference *currentReference;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSAlert *alert;
		
		panel = [NSOpenPanel openPanel];
		[panel setCanCreateDirectories:YES];
		[panel setCanChooseFiles:NO];
		[panel setCanChooseDirectories:YES];
		[panel setMessage:NSLocalizedString(@"Choose a destination directory for saving:", @"Choose dialog message when saving multiple script support files")];
		result = [panel runModalForDirectory:nil file:nil types:nil];
		if (result == NSOKButton) {
			filenameEnumerator = [selectedFiles objectEnumerator];
			while ((currentReference = [filenameEnumerator nextObject])) {
				currentFileName = [[panel filename] stringByAppendingPathComponent:[[currentReference fileWrapper] preferredFilename]];
				if ([fileManager fileExistsAtPath:currentFileName]) {
					alert = [[NSAlert alloc] init];
					[alert setAlertStyle:NSWarningAlertStyle];
					[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Overwrite file '%@'?", @"Alert message text when saving script support files"), [fileManager displayNameAtPath:currentFileName]]];
					[alert setInformativeText:NSLocalizedString(@"A file with this name already exists in the destination directory. If you overwrite it, the existing version will be lost.", @"Alert informative text when saving script support files")];
					[alert addButtonWithTitle:NSLocalizedString(@"Skip", @"Alert button for not overwriting when saving script support files")];
					[alert addButtonWithTitle:NSLocalizedString(@"Overwrite", @"Alert button for overwriting when saving script support files")];
					[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Alert button for aborting the whole operation when saving script support files")];
					result = [alert runModal];
					if (result == NSAlertFirstButtonReturn)
						continue;
					else if (result == NSAlertThirdButtonReturn)
						break;
					[alert release];
				}
				[[currentReference fileWrapper] writeToFile:currentFileName atomically:YES updateFilenames:NO];
			}
		}
	}
}

#pragma mark Table View Data Source

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSArray *droppedURLs;
	NSMutableArray *array = [self valueForKey:@"supportFiles"];

	droppedURLs = ConvertFilesToURLs([[info draggingPasteboard] propertyListForType:NSFilenamesPboardType]);
	droppedURLs = FilterURLs(droppedURLs, array);

	return ([droppedURLs count] > 0) ? NSDragOperationLink : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSEnumerator *enumerator;
	id currentObject;
	SupportFileReference *newReference;
	NSMutableArray *array = [self mutableArrayValueForKey:@"supportFiles"];
	NSArray *droppedURLs;
	
	droppedURLs = ConvertFilesToURLs([[info draggingPasteboard] propertyListForType:NSFilenamesPboardType]);
	droppedURLs = FilterURLs(droppedURLs, array);
	
	enumerator = [droppedURLs objectEnumerator];
	while ((currentObject = [enumerator nextObject])) {
		newReference = [[SupportFileReference alloc] init];
		[newReference setSourceAlias:[NDAlias aliasWithURL:currentObject]];
		[array addObject:newReference];
		[newReference release];
	}
	return YES;
}

@end
