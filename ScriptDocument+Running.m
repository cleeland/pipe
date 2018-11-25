//
//  ScriptDocument+Running.m
//  Pipe
//
//  Created by René Puls on 09.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <JaguarFoundation/JaguarFoundation.h>
#import <JaguarAppKit/JaguarAppKit.h>

#import "ScriptDocument+Running.h"
#import "ScriptSession.h"
#import "UserDefaults.h"
#import "Environment.h"

@implementation ScriptDocument (Running)

- (NSDictionary *)environment
{
	NSMutableDictionary *environment;
	NSString *outputTypeName, *encodingName;
	
	environment = [NSMutableDictionary dictionary];
	[environment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
		
	switch ([self outputType]) {
		case ScriptTextOutputType:
			outputTypeName = @"text";
			break;
		case ScriptImageOutputType:
			outputTypeName = @"image";
			break;
		case ScriptWebOutputType:
			outputTypeName = @"html";
			break;
		default:
			outputTypeName = @"unknown";
	}
	
	// Output type
	[environment setObject:outputTypeName forKey:PipeExpectedOutputTypeEnvironmentKey];

	if ([self isReverseTransformation]) {
		[environment setObject:@"1" forKey:PipeReverseTransformationEnvironmentKey];
	}

	// Script encoding
	if ((encodingName = [NSString IANANameOfStringEncoding:[self scriptStringEncoding]])) {
		[environment setObject:encodingName forKey:PipeScriptCharsetEnvironmentKey];
	}
	else {
		[environment setObject:(NSString *)CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding([self scriptStringEncoding])) forKey:PipeScriptCharsetEnvironmentKey];
	}
	
	// Input encoding
	if ((encodingName = [NSString IANANameOfStringEncoding:[self inputStringEncoding]])) {
		[environment setObject:encodingName forKey:PipeInputCharsetEnvironmentKey];
	}
	else {
		[environment setObject:(NSString *)CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding([self inputStringEncoding])) forKey:PipeInputCharsetEnvironmentKey];
	}
		
	// Output encoding
	if ((encodingName = [NSString IANANameOfStringEncoding:[self outputStringEncoding]]))
		[environment setObject:encodingName forKey:PipeExpectedOutputCharsetEnvironmentKey];
	else
		[environment setObject:(NSString *)CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding([self outputStringEncoding])) forKey:PipeExpectedOutputCharsetEnvironmentKey];
		
	// Global script support files
	[environment setObject:[NSString stringWithFormat:@"%@/Contents/Resources/Script Support", [[NSBundle mainBundle] bundlePath]] forKey:PipeSupportPathEnvironmentKey];
	
	return environment;
}

- (NSString *)scriptFileName
{
	if ([self preferredScriptFileName] != nil)
		return [self preferredScriptFileName];
	else
		return @"script";
}

- (NSDictionary *)scriptFileAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:0700], NSFilePosixPermissions,
		nil];
}

- (ScriptSession *)preparedScriptSessionWithVariables:(NSArray *)sessionVariables
{
	ScriptSession *newSession;
	JGBufferedTask *sessionTask;
	BOOL result;
	
	// Don't do anything if this document has no script
	if ([self script] == nil)
		return nil;
	
	// Use the document's variables by default
	if (sessionVariables == nil)
		sessionVariables = [self valueForKey:@"variables"];

	// Create a new session and add support files if necessary
	newSession = [[[ScriptSession alloc] init] autorelease];
	sessionTask = [newSession scriptTask];
	
	[self updateSupportFiles];

	if ([self supportDirectoryWrapper] != nil) {
		[newSession addSupportFilesFromFileWrapper:[self supportDirectoryWrapper]];
	}
	
	[newSession setVariables:sessionVariables];
	[newSession setArgumentString:[self argumentString]];
	[newSession setAdditionalEnvironment:[self environment]];
	
	if ([self executesDirectly] == NO)
		[newSession setRunCommand:[self runCommand]];
	
	// Prepare the buffered task
	[sessionTask setMaximumExecutionTime:[JGUserDefaultValue(PipeMaximumScriptExecutionTimeDefaultKey) floatValue]];
	[sessionTask setMaximumOutputSize:[JGUserDefaultValue(PipeMaximumScriptOutputSizeDefaultKey) intValue] * 1024];
	
	[newSession setScriptPath:[[newSession temporaryFilePath] stringByAppendingPathComponent:[self scriptFileName]]];
	result = [[NSFileManager defaultManager] createFileAtPath:[newSession scriptPath] contents:[self scriptData] attributes:[self scriptFileAttributes]];
	NSAssert1(result == YES, @"Failed to write temporary script file '%@'", [newSession scriptPath]);
	
	return newSession;
}

- (IBAction)runScript:(id)sender
{
	ScriptSession *newSession;
	
//	[[self undoManager] disableUndoRegistration];
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentWillRunNotification object:self];
//	[[self undoManager] enableUndoRegistration];
	
	newSession = [self preparedScriptSessionWithVariables:nil];
	[[[newSession scriptTask] inputBuffer] appendData:[self inputData]];
	
	@try {
		[newSession launch];
		[self setCurrentSession:newSession];
		[self setOutputData:nil];
		[self setErrors:nil];
	}
	@catch (NSException *exception) {
		NSAlert *alert;
		
		alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert setMessageText:NSLocalizedString(@"Could not run script", @"Alert message displayed when Pipe was unable to launch a script")];
		[alert setInformativeText:[exception reason]];
		[alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(runScriptAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		[alert release];
	}
}

- (void)runScriptAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
}

- (void)stopScript:(id)sender
{
	[[self currentSession] abort];
}

- (IBAction)autoRunScript:(id)sender
{
	BOOL optionKeyDown;
	
	optionKeyDown = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0);
	
	if ([JGUserDefaultValue(PipeAutoRunScriptsDefaultKey) boolValue] ^ optionKeyDown) {
		[self performSelectorOnMainThread:@selector(runScript:) withObject:self waitUntilDone:NO];
		if ([[self undoManager] canUndo])
			[[self undoManager] registerUndoWithTarget:self selector:@selector(autoRunScript:) object:self];
	}
}

- (void)scriptTaskDidTerminate:(NSNotification *)aNotification
{
	JGBufferedTask *theTask = [aNotification object];
	NSString *newErrors;
	NSError *error;
	
	error = [[aNotification userInfo] objectForKey:JGBufferedTaskTerminationErrorKey];
	
	if (error) {
		NSAlert *alert;
		NSString *informativeText;
		
		alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"Error during script execution", @"Alert message displayed when a running script was aborted prematurely")];
		
		switch ([error code]) {
			case JGBufferedTaskOutputSizeExceededError:
				informativeText = NSLocalizedString(@"Script output size exceeded. (You can increase this limit in the preferences.)", @"Informative text when a running script was aborted because its output size exceeded the user-configurable limit");
				break;
			case JGBufferedTaskExecutionTimeExceededError:
				informativeText = NSLocalizedString(@"Script execution time exceeded. (You can increase this limit in the preferences.)", @"Informative text when a running script was aborted because its execution time exceeded the user-configurable limit");
				break;
			default:
				informativeText = [error localizedDescription];
				break;
		}
		
		[alert setInformativeText:informativeText];
		
		[self showWindows];

		// Ignore user aborts: users know what they have done, no need to tell them
		if ([error code] != JGBufferedTaskAbortedError) {
			[alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
		}
		[alert release];
	}

	if ((error == nil) || ([self outputType] != ScriptImageOutputType))
		[self setOutputData:[theTask outputBuffer]];
	
	newErrors = [[NSString alloc] initWithData:[theTask errorBuffer] encoding:[self errorStringEncoding]];
	if ([newErrors length] > 0) {
		[self setErrors:newErrors];
		[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentErrorNotification object:self];
	}
	[newErrors release];
	
	[self setCurrentSession:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentScriptDidTerminateNotification object:self];
	[NSApp setWindowsNeedUpdate:YES];
}

@end
