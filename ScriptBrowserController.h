/* ScriptBrowserController */

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>

#import "ScriptWindowControllerBase.h"

@class KwikiController, ScriptTask, ScriptDocument, DataView;

@interface ScriptBrowserController : ScriptWindowControllerBase
{
	BOOL shouldRestoreInfoDrawer;
	IBOutlet JGExtendedTableView *scriptBrowserTableView;
    IBOutlet NSArrayController *scriptsController;
	IBOutlet NSMenu *scriptContextualMenu;
}
// Accessors
- (KwikiController *)kwikiController;
// Actions
- (IBAction)loadSelectedScript:(id)sender;
- (IBAction)focusScript:(id)sender;
- (void)saveWindowLayout;
- (void)restoreWindowLayout;
@end
