/* WelcomeWindowController */

#import <Cocoa/Cocoa.h>

@interface WelcomeWindowController : NSWindowController
{
}
- (int)runModal;
- (IBAction)okay:(id)sender;
- (IBAction)openWebSiteAndClose:(id)sender;
@end
