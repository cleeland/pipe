//
//  ScriptWindowControllerBase.m
//  Pipe
//
//  Created by René Puls on 14.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptWindowControllerBase.h"
#import "DataView.h"
#import "ScriptDocument.h"
#import "ScriptDocument+Running.h"
#import "UserDefaults.h"
#import "ScriptVariable.h"

#import <JaguarAppKit/JaguarAppKit.h>

#define NSAppKitVersionNumber10_3 743

NSString * const ScriptArgumentsToolbarItemIdentifier = @"ScriptArgumentsToolbarItemIdentifier";
JGDefineStringName(ScriptRunToolbarItemIdentifier)
JGDefineStringName(ScriptStopToolbarItemIdentifier)
JGDefineStringName(ScriptReverseTransformationToolbarItemIdentifier)
JGDefineStringName(ScriptOutputToInputToolbarItemIdentifier)
JGDefineStringName(ScriptToggleInfoToolbarItemIdentifier)

@implementation ScriptWindowControllerBase

#pragma mark Init and Cleanup

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
	}
	return self;
}

- (NSString *)toolbarIdentifier
{
	return nil;
}

- (void)windowDidLoad
{
	NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	NSToolbar *toolbar;
	id newView;

	// Configure the toolbar
	toolbar = [[NSToolbar alloc] initWithIdentifier:[self toolbarIdentifier]];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[[self window] setToolbar:toolbar];
	[toolbar release];
				
	[horizontalSplitView setFrame:NSInsetRect([horizontalSplitView frame], -1, -1)];
	
	// Configure the input text view
	newView = [JGExtendedTextView fullyConfiguredTextView];
	[newView setFrame:[inputTextView frame]];
	[[inputTextView superview] replaceSubview:inputTextView with:newView];
	inputTextView = [newView documentView];
	[inputTextView setDelegate:self];
	[inputTextView setRichText:NO];
	[inputTextView setUsesFontPanel:NO];
	[inputTextView setUsesFindPanel:YES];
	[inputTextView setUsesRuler:NO];
	[inputTextView setAllowsUndo:YES];
	[inputTextView bind:@"font" toObject:userDefaultsController withKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey] options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	[inputTextView bind:@"value" toObject:documentController withKeyPath:@"selection.input" options:nil];
	[inputTextView bind:@"backgroundColor" toObject:userDefaultsController withKeyPath:[NSString stringWithFormat:@"values.%@", PipeInputBackgroundColorDefaultKey] options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	[inputTextView bind:@"softWraps" toObject:userDefaultsController withKeyPath:[NSString stringWithFormat:@"values.%@", PipeSoftWrapDefaultKey] options:nil];
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
		[inputTextView bind:@"baseWritingDirection" toObject:documentController withKeyPath:@"selection.inputWritingDirection" options:nil];
	}
	[[inputTextView enclosingScrollView] bind:@"verticalLineScroll" toObject:userDefaultsController withKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey] options:[NSDictionary dictionaryWithObject:JGFontLineHeightTransformerName forKey:@"NSValueTransformerName"]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidUpdateFromExternalEditor:) name:JGExtendedTextViewDidUpdateFromExternalEditorNotification object:inputTextView];
	
	[outputDataView bind:@"data" toObject:documentController withKeyPath:@"selection.outputData" options:nil];
	[outputDataView bind:@"contentType" toObject:documentController withKeyPath:@"selection.outputType" options:nil];
	[outputDataView bind:@"dataStringEncoding" toObject:documentController withKeyPath:@"selection.outputStringEncoding" options:nil];
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
		[outputDataView bind:@"baseWritingDirection" toObject:documentController withKeyPath:@"selection.outputWritingDirection" options:nil];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataContentViewDidChange:) name:DataViewDidChangeContentViewNotification object:outputDataView];
	

	[variablesTableView setSelectsNextCellOnEndEditing:NO];
	
	[usageInfoTextView setUsesFontPanel:YES];
	[usageInfoTextView setUsesFindPanel:YES];
	[usageInfoTextView setTextContainerInset:NSMakeSize(4,8)];
	
	[self configureDataView:outputDataView];
}

- (void)configureDataView:(DataView *)dataView
{
	if ([outputDataView contentType] == DataViewTextContentType) {
		JGExtendedTextView *textView;
		
		textView = [[outputDataView contentView] documentView];
		[textView bind:@"font" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey] options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
		[textView bind:@"softWraps" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeSoftWrapDefaultKey] options:nil];
		[textView bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[NSString stringWithFormat:@"values.%@", PipeOutputBackgroundColorDefaultKey] options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	}
	
}

- (void)disconnectBindings
{
	[documentController unbind:@"contentObject"];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark User Interface Validation

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(toggleInfoDrawer:)) {
		switch ([infoDrawer state]) {
			case NSDrawerOpeningState:
			case NSDrawerOpenState:
				[anItem setTitle:NSLocalizedString(@"Hide Information", @"Menu item for hiding the info drawer.")];
				break;
			default:
				[anItem setTitle:NSLocalizedString(@"Show Information", @"Menu item for showing the info drawer.")];
				break;
		}
		return YES;
	}
	else return [self validateUserInterfaceItem:anItem];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(takeInputFromOutput:)) {
		return ![inputTextView isEditingInExternalEditor] && ([[self document] outputType] != ScriptImageOutputType);
	}
	else return YES;
}

#pragma mark Split View Delegate

- (float)splitView:(NSSplitView *)sender constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset
{
	float ratio, max;
	
	if (sender == verticalSplitView) {
		
		// Make the divider snap into the centered position
		
		max = NSHeight([sender frame]) - [sender dividerThickness];
		ratio = proposedPosition / max;
		
		if (ratio > 0.45 && ratio < 0.55)
			ratio = 0.5;
		
		return max * ratio;
		
	}
	else return proposedPosition;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if (sender == horizontalSplitView) {
		[sender adjustSubviews];
	}
	else if (sender == verticalSplitView) {
		float ratio;
		
		ratio = [sender subviewRatio];
		if (ratio > 0.45 && ratio < 0.55)
			[sender adjustSubviewsWithRatio:0.5];
		else
			[sender adjustSubviews];
	}
	else [sender adjustSubviews];
}

#pragma mark Toolbar Delegate

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
		ScriptRunToolbarItemIdentifier,
		ScriptStopToolbarItemIdentifier,
		ScriptReverseTransformationToolbarItemIdentifier,
		ScriptOutputToInputToolbarItemIdentifier,
		ScriptToggleInfoToolbarItemIdentifier,
		ScriptArgumentsToolbarItemIdentifier,
		NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray array];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item;
	
	item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	
	if ([itemIdentifier isEqualToString:ScriptRunToolbarItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Run", @"Toolbar item for running a script")];
		[item setToolTip:NSLocalizedString(@"Run Script", @"Toolbar item tooltip for running a script")];
		[item setImage:[NSImage imageNamed:@"Run Button"]];
		[item setAction:@selector(runScript:)];
		[item setTarget:nil];
	}
	else if ([itemIdentifier isEqualToString:ScriptStopToolbarItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Stop", @"Toolbar item for stopping a script")];
		[item setToolTip:NSLocalizedString(@"Stop Script", @"Toolbar item tooltop for stopping a script")];
		[item setImage:[NSImage imageNamed:@"Stop Button"]];
		[item setAction:@selector(stopScript:)];
		[item setTarget:nil];
	}
	else if ([itemIdentifier isEqualToString:ScriptReverseTransformationToolbarItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Toggle Direction", @"Reverse transformation toolbar item")];
		[item setToolTip:NSLocalizedString(@"Toggle Transformation Direction", @"Reverse transformation toolbar item tooltip")];
		[item setImage:[NSImage imageNamed:@"Forward Transform"]];
		[item setAction:@selector(toggleReverseTransformation:)];
		[item setTarget:nil];
	}
	else if ([itemIdentifier isEqualToString:ScriptOutputToInputToolbarItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Output to Input", @"Copy current script output to input (toolbar item)")];
		[item setImage:[NSImage imageNamed:@"Output to Input"]];
		[item setAction:@selector(takeInputFromOutput:)];
		[item setTarget:nil];
	}
	else if ([itemIdentifier isEqualToString:ScriptToggleInfoToolbarItemIdentifier]) {
		[item setLabel:NSLocalizedString(@"Info", @"Toolbar item for toggling the info drawer")];
		[item setImage:[NSImage imageNamed:@"Info Button"]];
		[item setAction:@selector(toggleInfoDrawer:)];
		[item setTarget:nil];
	}
	else if ([itemIdentifier isEqualToString:ScriptArgumentsToolbarItemIdentifier]) {
		NSTextField *inputTextField;
		
		inputTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
		[inputTextField bind:@"value" toObject:documentController withKeyPath:@"selection.argumentString" options:[NSDictionary dictionaryWithObject:NSLocalizedString(@"None", @"Placeholder text for empty arguments toolbar item") forKey:@"NSNullPlaceholder"]];
		[item setLabel:NSLocalizedString(@"Arguments", @"Toolbar item for editing script arguments")];
		[item setView:inputTextField];
		[inputTextField setAction:@selector(autoRunScript:)];
		[inputTextField setTarget:[self document]];
//		if ([toolbar sizeMode] == NSToolbarSizeModeSmall)
//			[[inputTextField cell] setControlSize:NSSmallControlSize];
//		else
//			[[inputTextField cell] setControlSize:NSRegularControlSize];
		[inputTextField sizeToFit];
		[inputTextField release];
		[item setMaxSize:NSMakeSize(500, NSHeight([inputTextField frame]))];
		[item setMinSize:NSMakeSize(100, NSHeight([inputTextField frame]))];
	}
	
	if ([item paletteLabel] == nil || [[item paletteLabel] isEqualToString:@""])
		[item setPaletteLabel:[item label]];
	
	return item;
}

#pragma mark Notifications

- (void)dataContentViewDidChange:(NSNotification *)aNotification
{
	[self configureDataView:[aNotification object]];
}

- (void)scriptDocumentWillRun:(NSNotification *)aNotification
{
	[self commitAllEditing];
}

- (void)textViewDidUpdateFromExternalEditor:(NSNotification *)aNotification
{
	[[self document] autoRunScript:self];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self disconnectBindings];
}

#pragma mark Actions

- (IBAction)focusInput:(id)sender
{
	[[self window] makeFirstResponder:inputTextView];
}

- (IBAction)focusOutput:(id)sender
{
	[[self window] makeFirstResponder:[outputDataView contentView]];
}

- (IBAction)focusVariables:(id)sender
{
	if (([infoDrawer state] == NSDrawerClosingState) || ([infoDrawer state] == NSDrawerClosedState)) {
		[infoDrawer open];
	}
	[[self window] makeFirstResponder:variablesTableView];
}

- (IBAction)takeInputFromOutput:(id)sender
{
	[[self document] takeInputFromOutput:sender];
}

- (IBAction)toggleInfoDrawer:(id)sender
{
	[infoDrawer toggle:sender];
}

#pragma mark Misc Stuff

- (void)setDocument:(id)newDocument
{
	if (newDocument != [self document]) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[self document]];
		[super setDocument:newDocument];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptDocumentWillRun:) name:ScriptDocumentWillRunNotification object:newDocument];
	}
}

- (BOOL)commitAllEditing
{
	id previousResponder = nil;
	BOOL success = YES;
	
	if ([documentController isEditing]) {
		previousResponder = [[self window] firstResponder];
		success = [documentController commitEditing];
		if (success) {
			if ([previousResponder isKindOfClass:[NSTextView class]]) {
				[previousResponder setNeedsDisplay:YES];
				[[self window] makeFirstResponder:previousResponder];
			}
		}
	}
	return success;
}

- (void)discardAllEditing
{
	[documentController discardEditing];
}

@end
