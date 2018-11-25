#import "WelcomeWindowController.h"
#import "AppController.h"
#import <JaguarAppKit/JaguarAppKit.h>

@implementation WelcomeWindowController

- (id)init
{
	if ((self = [super initWithWindowNibName:@"Welcome"])) {
	}
	return self;
}

- (int)runModal
{
	return [NSApp runModalForWindow:[self window]];
}

- (IBAction)okay:(id)sender
{
	[NSApp stopModalWithCode:NSOKButton];
	[[self window] orderOut:self];
}

- (IBAction)openWebSiteAndClose:(id)sender
{
	[NSApp openApplicationWebSite:self];
	[self okay:self];
}

@end
