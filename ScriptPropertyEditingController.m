#import "ScriptPropertyEditingController.h"
#import "ScriptBrowserDocument.h"
#import "EncodingManager.h"
#import "ScriptDocument+Running.h"

#define NSAppKitVersionNumber10_3 743

@implementation ScriptPropertyEditingController

- (void)awakeFromNib
{
	// Pre-10.4 does not support setting the writing direction
	if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_3)
		[writingDirectionBox setHidden:YES];
}

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:propertiesPanel returnCode:NSCancelButton];
}

- (IBAction)okay:(id)sender
{
	ScriptBrowserDocument *document;
	int runMode;
	NSString *runCommand;
	
	[propertiesPanel makeFirstResponder:nil];

	document = [[scriptWindow windowController] document];
	runMode = [runModeMatrix selectedTag];
	runCommand = [runCommandTextField stringValue];
	
	if (runMode == 0)
		[document setExecutesDirectly:YES];
	else
		[document setExecutesDirectly:NO];
	
	if (![runCommand isEqualToString:@""])
		[document setRunCommand:runCommand];
	else
		[document setRunCommand:nil];
	
	[document setUsageInfo:[usageTextView textStorage]];
	
	if (![[homePageTextField stringValue] isEqualToString:@""])
		[document setHomeURL:[NSURL URLWithString:[homePageTextField stringValue]]];
	else
		[document setHomeURL:nil];
	
	[document setScriptStringEncoding:[scriptEncodingPopUp selectedTag]];
	[document setInputStringEncoding:[inputEncodingPopUp selectedTag]];
	[document setOutputStringEncoding:[outputEncodingPopUp selectedTag]];
	
	[document setInputWritingDirection:[inputWritingDirectionPopUp selectedTag]];
	[document setOutputWritingDirection:[outputWritingDirectionPopUp selectedTag]];
	
	if (![[preferredFileNameTextField stringValue] isEqualToString:@""])
		[document setPreferredScriptFileName:[preferredFileNameTextField stringValue]];
	else
		[document setPreferredScriptFileName:nil];
	
	[document setServiceCapable:([serviceCapableCheckBox state] == NSOnState)];
	
	[NSApp endSheet:propertiesPanel returnCode:NSOKButton];
	
	[document autoRunScript:self];
}

- (IBAction)runModeChanged:(id)sender
{
	[runCommandTextField setEnabled:[runModeMatrix selectedTag] != 0];
}

- (IBAction)showHelp:(id)sender
{
	static NSDictionary *helpLookupTable = nil;
	
	if (helpLookupTable == nil) {
		helpLookupTable = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"PipeRunCommandTopic", @"running",
			@"PipeTextEncodingTopic", @"textEncoding",
			@"PipeScriptInformationTopic", @"information",
			nil];
	}
	
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[helpLookupTable objectForKey:[[tabView selectedTabViewItem] identifier]] inBook:@"Pipe Help"];
}

- (void)beginSheet
{
	ScriptBrowserDocument *document;
	
	if ([scriptWindow attachedSheet] == nil) {
		document = [[scriptWindow windowController] document];
		[runModeMatrix selectCellWithTag:([document executesDirectly] ? 0 : 1)];
		[runCommandTextField setStringValue:[document runCommand] ? [document runCommand] : @""];
		if ([document usageInfo] != nil)
			[[usageTextView textStorage] setAttributedString:[document usageInfo]];
		else
			[usageTextView setString:@""];
		if ([document homeURL] != nil)
			[homePageTextField setStringValue:[[document homeURL] absoluteString]];
		else
			[homePageTextField setStringValue:@""];
		if ([document preferredScriptFileName] != nil)
			[preferredFileNameTextField setStringValue:[document preferredScriptFileName]];
		else
			[preferredFileNameTextField setStringValue:@""];
		[self runModeChanged:self];
		[[EncodingManager sharedInstance] setupPopUp:scriptEncodingPopUp selectedEncoding:[document scriptStringEncoding] withDefaultEntry:NO];
		[[EncodingManager sharedInstance] setupPopUp:inputEncodingPopUp selectedEncoding:[document inputStringEncoding] withDefaultEntry:NO];
		[[EncodingManager sharedInstance] setupPopUp:outputEncodingPopUp selectedEncoding:[document outputStringEncoding] withDefaultEntry:NO];
		if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
			[inputWritingDirectionPopUp selectItemWithTag:[document inputWritingDirection]];
			[outputWritingDirectionPopUp selectItemWithTag:[document outputWritingDirection]];
		}
		[serviceCapableCheckBox setState:[document isServiceCapable]];
		[NSApp beginSheet:propertiesPanel modalForWindow:scriptWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	}
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
}

@end
