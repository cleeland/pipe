#import <Carbon/Carbon.h>
#import <JaguarAppKit/JaguarAppKit.h>
#import "AppController.h"

#import "UserDefaults.h"
#import "Environment.h"
#import "Errors.h"

#import "ChooseScriptController.h"
#import "KwikiController.h"
#import "LicenseWindowController.h"
#import "ScriptBrowserDocument.h"
#import "ScriptDocument+Running.h"
#import "ScriptEditorDocument.h"
#import "ScriptReference.h"
#import "ScriptWindowController.h"
#import "SoftwareLicenseController.h"
#import "WelcomeWindowController.h"
#import "ServicesController.h"
#import "EncodingManager.h"
#import "RunningPreferencePane.h"
#import "AppearancePreferencePane.h"
#import "GeneralPreferencePane.h"
#import "ScriptSessionController.h"

// Pipe trial period
static NSTimeInterval TrialPeriodInSeconds = 86400 * 15;

// Pipe product key for generating and verifying license keys (SHA1-HMAC)
static unsigned char const ProductKey[128] = {
	0x7c, 0xf1, 0xe4, 0x7f, 0xf7, 0x1d, 0x8c, 0x40,
	0xd1, 0xe6, 0xdf, 0x23, 0xcd, 0x0c, 0xb5, 0xd7,
	0x14, 0x9e, 0x3e, 0x18, 0x6e, 0xb2, 0x2e, 0x96,
	0xa7, 0xcb, 0x87, 0x2a, 0xed, 0xee, 0x68, 0x4c,
	0xf4, 0xe7, 0x30, 0x67, 0xcc, 0x4d, 0xce, 0x27,
	0x4c, 0xce, 0xb3, 0x24, 0xef, 0x05, 0x1f, 0x53,
	0x29, 0x35, 0x2c, 0xc7, 0xc1, 0x57, 0x01, 0x77,
	0xf2, 0x1b, 0x74, 0x3f, 0xe3, 0x3a, 0x3c, 0xe5,
	0xd7, 0x06, 0x09, 0x96, 0x51, 0xc2, 0x44, 0x33,
	0xa1, 0xce, 0x1a, 0x5b, 0x42, 0x20, 0x28, 0xd5,
	0xa1, 0x7f, 0x90, 0x6f, 0x13, 0x4e, 0x78, 0x03,
	0xc7, 0x6a, 0xdd, 0x46, 0x76, 0x7c, 0x8c, 0x7b,
	0x46, 0x16, 0x6f, 0x95, 0xf9, 0x14, 0x3c, 0xee,
	0x31, 0x5a, 0xb4, 0xc8, 0x6c, 0x8d, 0xeb, 0x04,
	0x01, 0x34, 0xcb, 0x1f, 0xa4, 0xd5, 0xa6, 0x46,
	0x53, 0x0e, 0xca, 0x7c, 0xa7, 0x01, 0x31, 0xa9	
};

@implementation AppController

#pragma mark Application Setup

- (void)createSupportDirectories
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *supportDirectory, *currentDirectory;
	NSEnumerator *directoryEnumerator;
	BOOL exists, isDirectory;
	
	supportDirectory = [NSString stringWithFormat:@"%@/Library/Application Support/%@", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]];
	directoryEnumerator = [[NSArray arrayWithObjects:
		supportDirectory,
		[supportDirectory stringByAppendingPathComponent:@"Templates"],
		nil] objectEnumerator];
	
	while ((currentDirectory = [directoryEnumerator nextObject])) {
		exists = [fileManager fileExistsAtPath:currentDirectory isDirectory:&isDirectory];
		if (!exists) {
			// Try to create the directory if it does not yet exist
			if (![fileManager createDirectoryAtPath:currentDirectory attributes:nil]) {
				@throw [NSException exceptionWithUnderlyingError:[NSError errorWithDomain:PipeApplicationErrorDomain code:PipeApplicationInitialSetupError localizedDescription:[NSString stringWithFormat:NSLocalizedString(@"Failed to create directory '%@'.", @"Failed to create support directory during app launch (ERR)"), currentDirectory] userInfo:nil]];
			}
		}
		else if (!isDirectory) {
			@throw [NSException exceptionWithUnderlyingError:[NSError errorWithDomain:PipeApplicationErrorDomain code:PipeApplicationInitialSetupError localizedDescription:[NSString stringWithFormat:NSLocalizedString(@"'%@' is not a directory (but should be).", @"Failed to create support directory during app launch (ERR)"), currentDirectory] userInfo:nil]];
		}
	}
}

- (void)registerInitialDefaultValues
{
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:0], PipeStartupActionDefaultKey,
		[NSNumber numberWithBool:YES], JGAutoSoftwareUpdateEnabledDefaultKey,
		[NSNumber numberWithInt:0], PipeMaximumScriptExecutionTimeDefaultKey,
		[NSNumber numberWithInt:0], PipeMaximumScriptOutputSizeDefaultKey,
		[NSNumber numberWithBool:NO], PipeAutoRunScriptsDefaultKey,
		[NSNumber numberWithInt:0], PipeInputLineEndingsConversionDefaultKey,
		[NSNumber numberWithBool:NO], PipeDidShowWelcomeMessageDefaultKey,
		[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding], PipeLastSelectedTextEncodingInFilePanelDefaultKey,
		[NSNumber numberWithUnsignedInt:NSUTF8StringEncoding], PipeTextEncodingDefaultKey,
		@"BBEdit", PipeExternalEditorDefaultKey,
		[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], PipeScriptBackgroundColorDefaultKey,
		[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], PipeInputBackgroundColorDefaultKey,
		[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], PipeOutputBackgroundColorDefaultKey,
		[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Monaco" size:10]], PipeFontDefaultKey,
		nil]];
}

- (void)setupEnvironment
{
	NSProcessInfo *processInfo = [NSProcessInfo processInfo];
	NSMutableString *shortVersionString;
	NSCharacterSet *versionCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
	NSRange nonVersionCharacterRange;
	
	shortVersionString = [NSMutableString stringWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
	
	// Strip away version modifiers like "rc"
	nonVersionCharacterRange = [shortVersionString rangeOfCharacterFromSet:[versionCharacterSet invertedSet]];
	if (nonVersionCharacterRange.location != NSNotFound) {
		[shortVersionString deleteCharactersInRange:NSMakeRange(nonVersionCharacterRange.location, [shortVersionString length] - nonVersionCharacterRange.location)];
	}
	
	[shortVersionString replaceOccurrencesOfString:@"." withString:@"" options:0 range:NSMakeRange(0, [shortVersionString length])];
	
	[processInfo setValue:shortVersionString forEnvironmentKey:PipeVersionEnvironmentKey];
	[processInfo setValue:[[ScriptSessionController sharedController] connectionName] forEnvironmentKey:PipeSessionServerEnvironmentKey];
}

- (void)setupLicensing
{
	SoftwareLicenseController *licenseController;
	NSDate *firstLaunchDate;
	
	licenseController = [SoftwareLicenseController sharedController];
	[licenseController setProductKey:[NSData dataWithBytes:ProductKey length:128]];
	[licenseController setAllowedTrialPeriod:TrialPeriodInSeconds];
	[licenseController setLicenseKey:JGUserDefaultValue(PipeLicenseKeyDefaultKey)];
	if ((firstLaunchDate = JGUserDefaultValue(PipeFirstLaunchDateDefaultKey)))
		[licenseController setFirstLaunchDate:firstLaunchDate];
	[[KwikiController sharedController] loadKwikiList:self];
}

- (void)verifyLicense
{
	SoftwareLicenseController *softwareLicenseController = [SoftwareLicenseController sharedController];
	BOOL shouldRequireLicense = NO;
	
	if ([softwareLicenseController warningFlag] && [softwareLicenseController softwareIsTrialVersion]) {
		shouldRequireLicense = YES;
	}
	else shouldRequireLicense = ![softwareLicenseController softwareIsLicensed];
	
	if (shouldRequireLicense) {
		if ([[LicenseWindowController sharedController] runModal] != NSOKButton) {
			[NSApp terminate:self];
			return;
		}
		else {
			[softwareLicenseController setLicenseKey:JGUserDefaultValue(PipeLicenseKeyDefaultKey)];
			if ([NSApp mainWindow] == nil) {
				[self applicationOpenUntitledFile:NSApp];
			}
		}
	} 

	// Only when the license checks are satisfied, enable saving of the script browser list.
	[[KwikiController sharedController] setSavesKwikiList:YES];
}

- (void)registerServices
{
	[NSApp setServicesProvider:[ServicesController sharedController]];
	NSUpdateDynamicServices();
}

- (void)configureExternalEditor:(id)sender
{
	NSString *appPath, *appIdentifier;
	NSBundle *appBundle;
	
	appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:JGUserDefaultValue(PipeExternalEditorDefaultKey)];
	appBundle = [NSBundle bundleWithPath:appPath];
	appIdentifier = [appBundle bundleIdentifier];
	if (appIdentifier != nil)
		[[ODBEditor sharedODBEditor] setEditorBundleIdentifier:appIdentifier];
}

- (IBAction)openReleaseNotes:(id)sender
{
	NSString *versionString;
	
	versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.kcore.de/software/pipe/releasenotes-%@", versionString]]];
}

- (IBAction)showWelcomeMessage:(id)sender
{
	WelcomeWindowController *windowController;
	
	windowController = [[WelcomeWindowController alloc] init];
	[windowController runModal];
	[windowController release];
	JGSetUserDefaultValue(PipeDidShowWelcomeMessageDefaultKey, [NSNumber numberWithBool:YES]);
}

#pragma mark Actions

- (IBAction)doNothing:(id)sender
{
	// Some menu items have their "state" bound to a user default (such as soft wrap). They will automatically update the default when they are selected. This action is only necessary to make the items enabled.
}

- (IBAction)enterLicense:(id)sender
{
	[[LicenseWindowController sharedController] runModal];
}

- (IBAction)showScriptBrowser:(id)sender
{
	[[ScriptBrowserDocument sharedDocument] showWindows];
}

- (IBAction)switchInputLineEndingsConversion:(id)sender
{
	JGSetUserDefaultValue(PipeInputLineEndingsConversionDefaultKey, [NSNumber numberWithInt:[sender tag]]);
}

- (IBAction)newDocumentFromTemplate:(id)sender
{
	ScriptEditorDocument *newDocument;
	NSString *templatePath;
	
	templatePath = [sender representedObject];
	
	if ([NSEvent isCommandKeyDown]) {
		[[NSWorkspace sharedWorkspace] selectFile:templatePath inFileViewerRootedAtPath:nil];
	}
	else if ([NSEvent isOptionKeyDown]) {
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:templatePath display:YES];
	}
	else {
		newDocument = [[ScriptEditorDocument alloc] initWithTemplatePath:templatePath];
		[[NSDocumentController sharedDocumentController] addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
		[newDocument release];
	}
}

- (IBAction)checkForSoftwareUpdates:(id)sender
{
	NSBundle *mainBundle;
	id propertyList;
	NSError *error;
	int myVersion;
	NSAlert *alert;

	mainBundle = [NSBundle mainBundle];
	myVersion = [[[mainBundle infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey] intValue];
	propertyList = [[JGSoftwareUpdateChecker checkerWithBundle:mainBundle client:nil] runSynchronouslyReturningError:&error];
	if (error) {
		alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"Could not check for updates", @"Alert message text")];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setInformativeText:[error localizedDescription]];
		[alert runModal];
		[alert release];
	}
	else if (myVersion < [[propertyList objectForKey:JGSoftwareUpdateBundleVersionKey] intValue]) {
		alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"A new version of Pipe (%@) is now available for download.\nDo you want to update your copy?", @"Alert text when new updates are available (manual check)"), [propertyList objectForKey:JGSoftwareUpdateHumanReadableVersionKey]]];
		[alert setInformativeText:NSLocalizedString(@"If you do not want to update now, simply check for updates at a later time to display this message again.", @"Informative text when new updates are available (manual check)")];
		[alert addButtonWithTitle:NSLocalizedString(@"Update Now", @"Software update alert button (manual check)")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Software update alert button (manual check)")];
		if ([alert runModal] == NSAlertFirstButtonReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[propertyList objectForKey:JGSoftwareUpdateReleaseNotesURLKey]]];
		}
	}
	else {
		alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setMessageText:NSLocalizedString(@"No updates available", @"Alert message text")];
		[alert setInformativeText:NSLocalizedString(@"Your copy of Pipe is up-to-date.", @"Alert informative text")];
		[alert runModal];
		[alert release];
	}
}

#pragma mark Accessors

- (KwikiController *)kwikiController
{
	return [KwikiController sharedController];
}

- (ScriptBrowserDocument *)scriptBrowser
{
	return [ScriptBrowserDocument sharedDocument];
}

#pragma mark Menu Delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSString *templatesDirectory, *currentTemplate;
	NSDirectoryEnumerator *templateEnumerator;
	NSDictionary *templateAttributes;
	NSMenuItem *newItem;
	
	NSAssert(menu == templatesMenu, @"menuNeedsUpdate called for unknown menu");
	
	// Remove all items
	while ([menu numberOfItems])
		[menu removeItemAtIndex:0];
	
	templatesDirectory = [NSString stringWithFormat:@"%@/Library/Application Support/%@/Templates", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]];
	templateEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:templatesDirectory];
	while ((currentTemplate = [templateEnumerator nextObject])) {
		templateAttributes = [templateEnumerator fileAttributes];
		if ([[templateAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			[templateEnumerator skipDescendents];
			if ([[currentTemplate pathExtension] isEqualToString:@"pipe"]) {
				newItem = (NSMenuItem *)[menu addItemWithTitle:[currentTemplate stringByDeletingPathExtension] action:@selector(newDocumentFromTemplate:) keyEquivalent:@""];
				[newItem setRepresentedObject:[templatesDirectory stringByAppendingPathComponent:currentTemplate]];
				[newItem setEnabled:[self validateMenuItem:newItem]];
			}
		}
	}
	
	if ([menu numberOfItems] > 0)
		[menu addItem:[NSMenuItem separatorItem]];
	
	templatesDirectory = [NSString stringWithFormat:@"%@/Templates", [[NSBundle mainBundle] resourcePath]];
	templateEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:templatesDirectory];
	while ((currentTemplate = [templateEnumerator nextObject])) {
		templateAttributes = [templateEnumerator fileAttributes];
		if ([[templateAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
			[templateEnumerator skipDescendents];
			if ([[currentTemplate pathExtension] isEqualToString:@"pipe"]) {
				newItem = (NSMenuItem *)[menu addItemWithTitle:[currentTemplate stringByDeletingPathExtension] action:@selector(newDocumentFromTemplate:) keyEquivalent:@""];
				[newItem setRepresentedObject:[templatesDirectory stringByAppendingPathComponent:currentTemplate]];
				[newItem setEnabled:[self validateMenuItem:newItem]];
			}
		}
	}
}

#pragma mark User Interface Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	
	// Disable all menu items when the license window is shown.
	if ([NSApp modalWindow] == [[LicenseWindowController sharedController] window]) {
		return NO;
	}
	else {
		if (action == @selector(switchInputLineEndingsConversion:)) {
			[menuItem setState:([menuItem tag] == [JGUserDefaultValue(PipeInputLineEndingsConversionDefaultKey) intValue])];
		}
		
		return YES;
	}
}

#pragma mark NSApplication delegate

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return [[SoftwareLicenseController sharedController] softwareIsLicensed];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication
{
	switch ([JGUserDefaultValue(PipeStartupActionDefaultKey) intValue]) {
		case 0:
			[[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:PipeScriptDocumentType display:YES];
			return YES;
		case 1:
			[self showScriptBrowser:self];
			return YES;
		default:
			NSLog(@"Unknown startup action: %@", [JGUserDefaultValue(PipeStartupActionDefaultKey) intValue]);
			return NO;
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Ignore SIGPIPE from launched subtasks.
	signal(SIGPIPE, SIG_IGN);
	
	@try {
		[self registerInitialDefaultValues];
		[[JGPreferenceWindowController sharedController] setDelegate:self];
		[self setupLicensing];
		[self createSupportDirectories];
		[self configureExternalEditor:self];
		[self setupEnvironment];
	}
	@catch (NSException *exception) {
		NSAlert *alert;
		
		alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"Fatal error", @"Error message when an exception is raised during the application launch phase")];
		[alert setInformativeText:[exception description]];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
		[alert release];
		
		[NSApp terminate:self];
	}
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	hasLaunchedCompletely = YES;
	
	[self verifyLicense];
	[self registerServices];

	if (![JGUserDefaultValue(PipeDidShowWelcomeMessageDefaultKey) boolValue])
		[self showWelcomeMessage:self];
}

#pragma mark NSDocumentController delegate

- (void)documentController:(JGDocumentController *)documentController prepareOpenPanel:(NSOpenPanel *)openPanel
{
	[openPanel setDelegate:self];
	[openPanel setAccessoryView:[[EncodingManager sharedInstance] encodingAccessory:[JGUserDefaultValue(PipeLastSelectedTextEncodingInFilePanelDefaultKey) unsignedIntValue] includeDefaultEntry:NO enableIgnoreRichTextButton:NO encodingPopUp:NULL ignoreRichTextButton:NULL]];
}

- (void)panelSelectionDidChange:(NSOpenPanel *)panel
{
	NSPopUpButton *popUpButton;
	JGDocumentController *documentController = [NSDocumentController sharedDocumentController];
	NSString *selectedType;
	
	popUpButton = [[panel accessoryView] viewWithTag:1];
	selectedType = [documentController typeFromFileExtension:[[panel filename] pathExtension]];
	
	if ([selectedType isEqualToString:PipeScriptDocumentType] || [selectedType isEqualToString:PipeScriptFlatDocumentType])
		[popUpButton setEnabled:NO];
	else
		[popUpButton setEnabled:YES];
}

#pragma mark Preference Window Controller Delegate

- (NSArray *)panesForPreferenceWindowController:(JGPreferenceWindowController *)aController
{
	static NSArray *preferencePanes = nil;
	
	if (preferencePanes == nil) {
		preferencePanes = [[NSArray alloc] initWithObjects:
			[[[GeneralPreferencePane alloc] init] autorelease],
			[[[AppearancePreferencePane alloc] init] autorelease],
			[[[RunningPreferencePane alloc] init] autorelease],
			nil];
	}
	
	return preferencePanes;
}

#pragma mark Software Update

- (BOOL)application:(JGApplication *)application softwareUpdatesAvailable:(NSDictionary *)updateInfo
{
	return [self presentSoftwareUpdateDialogForPropertyList:updateInfo];
}

- (BOOL)presentSoftwareUpdateDialogForPropertyList:(id)propertyList
{
	NSAlert *alert;
	BOOL result = NO;
	
	if ([NSApp modalWindow] == nil) {
		alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"A new version of Pipe (%@) is now available for download.\nDo you want to update your copy?", @"Notification alert when a new version of Pipe is available for download"), [propertyList objectForKey:JGSoftwareUpdateHumanReadableVersionKey]]];
		[alert setInformativeText:NSLocalizedString(@"You can turn off automatic update checks in the preferences if you do not wish to be notified of new versions in the future.", @"Informative text when a new version of Pipe is available for download")];
		[alert addButtonWithTitle:NSLocalizedString(@"Update Now", @"Software update alert")];
		[alert addButtonWithTitle:NSLocalizedString(@"Ask Again Later", @"Software update alert")];
		[alert addButtonWithTitle:NSLocalizedString(@"Change Preferences...", @"Software update alert")];
		
		switch ([alert runModal]) {
			case NSAlertFirstButtonReturn:
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[propertyList objectForKey:JGSoftwareUpdateReleaseNotesURLKey]]];
				result = YES;
				break;
			case NSAlertSecondButtonReturn:
				result = NO;
				break;
			case NSAlertThirdButtonReturn:
				result = YES;
				[[JGPreferenceWindowController sharedController] showWindow:self];
				[[JGPreferenceWindowController sharedController] setSelectedPaneIndex:0];
				break;
		}
		[alert release];
		
		return result;
	}
	else return NO; // modal window is open; don't interfere
}

@end
