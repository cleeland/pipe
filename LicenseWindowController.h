/* LicenseWindowController */

#import <Cocoa/Cocoa.h>

@interface LicenseWindowController : NSWindowController
{
    IBOutlet NSButton *cancelButton;
    IBOutlet NSTextField *keyTextField;
    IBOutlet NSButton *okayButton;
	IBOutlet NSTextField *thankYouTextField;
	IBOutlet NSTextField *pleaseEnterTextField;
}
+ (id)sharedController;
// Accessors
- (BOOL)enteredLicenseKeyIsValid;
// Actions
- (IBAction)buyLicense:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (int)runModal;
// User Interface Validation
- (void)validateControls;
@end
