/* ScriptPropertyEditingController */

#import <Cocoa/Cocoa.h>

@interface ScriptPropertyEditingController : NSObject
{
	IBOutlet NSWindow *scriptWindow;
	IBOutlet NSPanel *propertiesPanel;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *okayButton;
	IBOutlet NSTextField *runCommandTextField;
	IBOutlet NSMatrix *runModeMatrix;
	IBOutlet NSTextView *usageTextView;
	IBOutlet NSTextField *homePageTextField;
	IBOutlet NSPopUpButton *scriptEncodingPopUp;
	IBOutlet NSPopUpButton *inputEncodingPopUp;
	IBOutlet NSPopUpButton *outputEncodingPopUp;
	IBOutlet NSPopUpButton *inputWritingDirectionPopUp;
	IBOutlet NSPopUpButton *outputWritingDirectionPopUp;
	IBOutlet NSTabView *tabView;
	IBOutlet NSButton *serviceCapableCheckBox;
	IBOutlet NSTextField *preferredFileNameTextField;
	IBOutlet NSBox *writingDirectionBox;
}
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)runModeChanged:(id)sender;
- (IBAction)showHelp:(id)sender;
- (void)beginSheet;
@end
