#import "LicenseWindowController.h"
#import "SoftwareLicenseController.h"
#import "UserDefaults.h"

#import <JaguarAppKit/JaguarAppKit.h>

@implementation LicenseWindowController

static LicenseWindowController *SharedInstance = nil;

#pragma mark Init and Cleanup

+ (id)sharedController
{
	if (SharedInstance == nil)
		SharedInstance = [[self alloc] init];
	return SharedInstance;
}

- (id)init
{
	if (SharedInstance != nil) {
		[self release];
		return SharedInstance;
	}
	
	if ((self = [super initWithWindowNibName:@"License"])) {
		SharedInstance = self;
	}
	return self;
}

#pragma mark Accessors

- (BOOL)enteredLicenseKeyIsValid
{
	return [[SoftwareLicenseController sharedController] verifyKey:[keyTextField stringValue]];
}

#pragma mark Actions

- (IBAction)buyLicense:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.kcore.de/software/pipe/"]];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModalWithCode:NSCancelButton];
	[[self window] orderOut:self];
}

- (IBAction)okay:(id)sender
{
	JGSetUserDefaultValue(PipeLicenseKeyDefaultKey, [[keyTextField stringValue] uppercaseString]);
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	if ([self enteredLicenseKeyIsValid])
		[NSApp stopModalWithCode:NSOKButton];
	else
		[NSApp stopModalWithCode:NSCancelButton];
	[[self window] orderOut:self];
}

- (int)runModal
{
	NSString *licenseKey;
	
	[self window];
	licenseKey = JGUserDefaultValue(PipeLicenseKeyDefaultKey);
	[keyTextField setStringValue:licenseKey ? licenseKey : @""];
	[self validateControls];
	return [NSApp runModalForWindow:[self window]];
}

#pragma mark User Interface Validation

- (void)validateControls
{
	BOOL isValid;
	float daysRemaining;
	
	isValid = [self enteredLicenseKeyIsValid];
	[okayButton setEnabled:isValid];
	
	if (isValid) {
		[thankYouTextField setTextColor:[NSColor blueColor]];
		[thankYouTextField setStringValue:NSLocalizedString(@"Thanks for buying a license!", @"License dialog message when key is valid")];
		[pleaseEnterTextField setStringValue:NSLocalizedString(@"This is your license key:", @"Label above license key text field when key is valid")];
	}
	else {
		daysRemaining = [[SoftwareLicenseController sharedController] remainingTrialPeriod] / 86400.0;
		[thankYouTextField setTextColor:[NSColor redColor]];
		if ([[SoftwareLicenseController sharedController] warningFlag]) {
			[thankYouTextField setStringValue:NSLocalizedString(@"Please contact technical support.", @"License dialog message when trial period information on disk is invalid. This may be due to intentional tampering or data corruption; please do not insult the user here!")];
		}
		else if (daysRemaining > 0) {
			[thankYouTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"This trial version expires in %.0f %@.", @"License dialog message during trial period; first arg is number of days, second argument is either singular or plural form of the word 'day'"), daysRemaining, daysRemaining > 1 ? NSLocalizedString(@"days", @"Plural of 'day', will be preceded by a number") : NSLocalizedString(@"day", @"Singular of 'day', will be preceded by a number")]];
		}
		else {
			[thankYouTextField setStringValue:NSLocalizedString(@"This trial version has expired.", @"License dialog message if trial version has expired")];
		}
		[pleaseEnterTextField setStringValue:NSLocalizedString(@"Please enter your license key exactly as you have received it:", @"Label above license key text field when no valid key has been entered")];
	}
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	[self validateControls];
}

@end
