/* AppController */

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>

#define PIPE_VERSION_1_2_0 891
#define PIPE_VERSION_1_2_1 906

@class ScriptWindowController, KwikiController;

@interface AppController : NSObject
{
	IBOutlet NSMenu *templatesMenu;
	BOOL hasLaunchedCompletely;
}
// Actions
- (IBAction)doNothing:(id)sender;
- (IBAction)enterLicense:(id)sender;
- (IBAction)showScriptBrowser:(id)sender;
- (IBAction)switchInputLineEndingsConversion:(id)sender;
- (IBAction)openReleaseNotes:(id)sender;
- (IBAction)showWelcomeMessage:(id)sender;
- (IBAction)checkForSoftwareUpdates:(id)sender;
// Application Setup
- (void)createSupportDirectories;
- (void)registerInitialDefaultValues;
- (void)setupEnvironment;
- (void)setupLicensing;
- (void)verifyLicense;
- (void)registerServices;
// Accessors (mostly for binding from IB)
- (KwikiController *)kwikiController;
- (NSArray *)panesForPreferenceWindowController:(JGPreferenceWindowController *)aController;
// Software update
- (BOOL)presentSoftwareUpdateDialogForPropertyList:(id)propertyList;
@end
