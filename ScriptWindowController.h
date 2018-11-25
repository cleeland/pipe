/* ScriptWindowController */

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>

#import "ScriptWindowControllerBase.h"

@class ScriptPropertyEditingController, DataView;

@interface ScriptWindowController : ScriptWindowControllerBase
{
	IBOutlet id scriptTextView;
	IBOutlet NSDrawer *errorsDrawer;
	IBOutlet ScriptPropertyEditingController *propertyEditingController;
	IBOutlet NSTextView *errorsTextView;
}
// Window State
- (NSDictionary *)savedPropertyList;
- (void)applySavedPropertyList:(NSDictionary *)aDictionary;
// Actions
- (IBAction)addToScriptBrowser:(id)sender;
- (IBAction)focusScript:(id)sender;
- (IBAction)toggleErrorsDrawer:(id)sender;
- (IBAction)editScriptSettings:(id)sender;
- (IBAction)editSupportFiles:(id)sender;
@end
