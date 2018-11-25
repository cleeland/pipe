//
//  ScriptDocument+UserInterface.m
//  Pipe
//
//  Created by René Puls on 14.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptDocument+UserInterface.h"
#import "ScriptDocument+Running.h"

#import <JaguarAppKit/JaguarAppKit.h>

static NSString * const OutputContext = @"OutputContext";

@implementation ScriptDocument (UserInterface)

#pragma mark User Interface Validation

- (BOOL)validateToolbarItem:(NSToolbarItem *)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(toggleReverseTransformation:)) {
		if ([self isReverseTransformation])
			[anItem setImage:[NSImage imageNamed:@"Reverse Transform"]];
		else
			[anItem setImage:[NSImage imageNamed:@"Forward Transform"]];
		return YES;
	}
	else return [self validateUserInterfaceItem:anItem];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];

	if (action == @selector(runScript:))
		return [self validateUserInterfaceItem:anItem];
	else if (action == @selector(stopScript:))
		return [self validateUserInterfaceItem:anItem];
	else if (action == @selector(openScriptHomePage:))
		return [self validateUserInterfaceItem:anItem];
	else if (action == @selector(toggleReverseTransformation:)) {
		[anItem setState:[self isReverseTransformation]];
		return YES;
	}
	else if (action == @selector(switchOutputType:)) {
		[anItem setState:([anItem tag] == [self outputType])];
		return YES;
	}
	else return [super validateMenuItem:anItem];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];

	if (action == @selector(runScript:))
		return YES;
	else if (action == @selector(stopScript:))
		return [self currentSession] != nil;
	else if (action == @selector(openScriptHomePage:))
		return ([self homeURL] != nil) && (![[[self homeURL] absoluteString] isEqualToString:@""]);
	
	return [super validateUserInterfaceItem:anItem];
}

#pragma mark Actions

- (void)editScriptArguments:(id)sender
{
	JGInputRequest *request;
	
	request = [[JGInputRequest alloc] init];
	[request setMessageText:NSLocalizedString(@"Script Arguments:", @"Message text for script arguments input request")];
	[request setInputString:[self argumentString]];
	[request setShowsHelp:YES];
	[request setHelpAnchor:@"PipeScriptArgumentsTopic"];
	[request beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(editScriptArgumentsDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[request release];
}

- (IBAction)openScriptHomePage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[self homeURL]];
}

- (IBAction)saveOutputToFile:(id)sender
{
	NSSavePanel *savePanel;
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setMessage:NSLocalizedString(@"Save Script Output to File", @"Informational text in save panel when saving only the script output to a file")];
	[savePanel beginSheetForDirectory:nil file:nil modalForWindow:[self windowForSheet] modalDelegate:self  didEndSelector:@selector(saveToFileDialogDidEnd:returnCode:contextInfo:) contextInfo:OutputContext];
}

- (IBAction)switchOutputType:(id)sender
{
	[self setOutputType:[sender tag]];
	[self autoRunScript:self];
	[[self undoManager] setActionName:NSLocalizedString(@"Change Output Type", @"Undo action name")];
}

- (IBAction)takeInputFromOutput:(id)sender
{
	[self setInput:[self output]];
	[self autoRunScript:self];
	[[self undoManager] setActionName:NSLocalizedString(@"Take Input from Output", @"Undo action name")];
}

- (IBAction)toggleReverseTransformation:(id)sender
{
	[self setReverseTransformation:![self isReverseTransformation]];
	[self autoRunScript:self];
	[[self undoManager] setActionName:NSLocalizedString(@"Toggle Reverse Transformation", @"Undo action name")];
	[NSApp setWindowsNeedUpdate:YES];
}

#pragma mark UI Callbacks

- (void)editScriptArgumentsDidEnd:(JGInputRequest *)request returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[self setArgumentString:[request inputString]];
		[self autoRunScript:self];
		[[self undoManager] setActionName:NSLocalizedString(@"Edit Script Arguments", @"Undo action name")];
	}
}

- (void)saveToFileDialogDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[[self outputData] writeToFile:[savePanel filename] atomically:YES];
	}
}

@end
