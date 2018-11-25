//
//  ScriptWindowControllerBase.h
//  Pipe
//
//  Created by René Puls on 14.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>
#import <JaguarFoundation/JaguarFoundation.h>

@class DataView, VariablesTableController;

extern NSString * const ScriptArgumentsToolbarItemIdentifier;
JGDeclareStringName(ScriptRunToolbarItemIdentifier)
JGDeclareStringName(ScriptStopToolbarItemIdentifier)
JGDeclareStringName(ScriptReverseTransformationToolbarItemIdentifier)
JGDeclareStringName(ScriptOutputToInputToolbarItemIdentifier)
JGDeclareStringName(ScriptToggleInfoToolbarItemIdentifier)

@interface ScriptWindowControllerBase : NSWindowController {
@protected
	IBOutlet NSObjectController *documentController;
	IBOutlet NSSplitView *verticalSplitView;
	IBOutlet NSSplitView *horizontalSplitView;
	IBOutlet id inputTextView;
	IBOutlet DataView *outputDataView;
	IBOutlet NSDrawer *infoDrawer;
	IBOutlet NSArrayController *variablesArrayController;
	IBOutlet JGExtendedTableView *variablesTableView;
	IBOutlet NSTextView *usageInfoTextView;
	IBOutlet VariablesTableController *variablesTableController;
}
// Init and Cleanup
- (void)disconnectBindings;
// Actions
- (IBAction)focusInput:(id)sender;
- (IBAction)focusOutput:(id)sender;
- (IBAction)focusVariables:(id)sender;
- (IBAction)toggleInfoDrawer:(id)sender;
// Misc Stuff
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
- (BOOL)commitAllEditing;
- (void)discardAllEditing;
- (void)scriptDocumentWillRun:(NSNotification *)aNotification;
- (void)configureDataView:(DataView *)dataView;
@end
