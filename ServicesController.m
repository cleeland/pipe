//
//  ServicesController.m
//  Pipe
//
//  Created by René Puls on 11.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <JaguarFoundation/JaguarFoundation.h>

#import "ServicesController.h"
#import "Environment.h"

#import "ChooseScriptController.h"
#import "ScriptReference.h"
#import "ScriptEditorDocument.h"
#import "ScriptDocument+Running.h"
#import "ScriptBrowserDocument.h"
#import "ScriptSession.h"
#import "KwikiController.h"

@implementation ServicesController

+ (id)sharedController
{
	static id sharedInstance = nil;
	
	if (sharedInstance == nil)
		sharedInstance = [[self alloc] init];
	return sharedInstance;
}

- (void)dealloc
{
	[currentServiceRequest release];
	[super dealloc];
}

- (NSDictionary *)currentServiceRequest
{
	return currentServiceRequest;
}

- (void)beginServiceRequestAndBringToFront:(BOOL)flag
{
	NSProcessInfo *processInfo = [NSProcessInfo processInfo];
	ProcessSerialNumber currentFrontProcess;
	NSDictionary *requestingAppInfo;
	
	if (currentServiceRequest != nil) {
		NSLog(@"WARNING: Beginning service request while another request in progress");
		[currentServiceRequest release];
	}
	
	GetFrontProcess(&currentFrontProcess);
	currentServiceRequest = [[NSMutableDictionary alloc] init];
	requestingAppInfo = (NSDictionary *)ProcessInformationCopyDictionary(&currentFrontProcess,kProcessDictionaryIncludeAllInformationMask);
	[currentServiceRequest setObject:requestingAppInfo forKey:@"requestingApplicationInfo"];
	[requestingAppInfo release];
	[currentServiceRequest setObject:[NSNumber numberWithBool:flag] forKey:@"didBringThisAppToFront"];
	[currentServiceRequest setObject:[NSNumber numberWithBool:[NSApp isHidden]] forKey:@"thisAppWasHidden"];
	[currentServiceRequest setObject:[NSValue value:&currentFrontProcess withObjCType:@encode(ProcessSerialNumber)] forKey:@"previousFrontProcess"];
	
	// Provide service request information in the environment
	[processInfo setValue:[requestingAppInfo objectForKey:@"BundlePath"] forEnvironmentKey:PipeServiceRequestingAppBundlePathEnvironmentKey];
	[processInfo setValue:[requestingAppInfo objectForKey:@"CFBundleIdentifier"] forEnvironmentKey:PipeServiceRequestingAppBundleIdentifierEnvironmentKey];
	[processInfo setValue:[requestingAppInfo objectForKey:@"CFBundleName"] forEnvironmentKey:PipeServiceRequestingAppBundleNameEnvironmentKey];
	
	if (flag)
		[NSApp activateIgnoringOtherApps:YES];
}

- (void)endServiceRequestRestoringLastFrontApp:(BOOL)flag
{
	NSProcessInfo *processInfo = [NSProcessInfo processInfo];
	ProcessSerialNumber previousFrontProcess;
	
	[processInfo setValue:nil forEnvironmentKey:PipeServiceRequestingAppBundlePathEnvironmentKey];
	[processInfo setValue:nil forEnvironmentKey:PipeServiceRequestingAppBundleIdentifierEnvironmentKey];
	[processInfo setValue:nil forEnvironmentKey:PipeServiceRequestingAppBundleNameEnvironmentKey];
	
	if ([[currentServiceRequest objectForKey:@"didBringThisAppToFront"] boolValue]) {
		[[currentServiceRequest objectForKey:@"previousFrontProcess"] getValue:&previousFrontProcess];
		if (flag) {
			SetFrontProcessWithOptions(&previousFrontProcess, 0);
			if ([[currentServiceRequest objectForKey:@"thisAppWasHidden"] boolValue])
				[NSApp hide:self];
		}
	}
	
	[currentServiceRequest release];
	currentServiceRequest = nil;
}

- (void)pipeThroughScript:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    NSString *newString;
	NSData *newData;
    NSArray *types;
	ChooseScriptController *chooseScriptController = [ChooseScriptController sharedController];
	BOOL shouldSaveToFile = NO;
	NSImage *image;
	NSData *inputData = nil;
	NSString *inputString = nil;
	NSArray *inputFiles;
	ScriptSession *scriptSession;
	
	[self beginServiceRequestAndBringToFront:YES];
	
	if ([[KwikiController sharedController] countOfKwikis] == 0) {
		[self presentEmptyScriptBrowserAlert];
	}
	else if (![chooseScriptController hasScripts]) {
		[self presentNoServicesScriptBrowserAlert];
	}
	else {
		// Gather input data
		types = [pboard types];
		
		inputFiles = [pboard propertyListForType:NSFilenamesPboardType];
		if (inputFiles != nil) {
			if ([inputFiles count] != 1) {
				*error = @"Please select only one file at a time";
			}
			else {
				inputData = [NSData dataWithContentsOfFile:[inputFiles objectAtIndex:0]];
				shouldSaveToFile = YES;
			}
		}
		
		if ([userData isEqualToString:@"processOnly"])
			shouldSaveToFile = YES;
		
		if (inputData == nil)
			inputString = [pboard stringForType:NSStringPboardType];
		
		if ((inputString == nil) && (inputData == nil))
			inputData = [NSData data];
		
		[chooseScriptController setShouldSaveToFile:shouldSaveToFile];
		
		if ([chooseScriptController runModal] == NSOKButton) {
			ScriptEditorDocument *scriptDocument;
			ScriptReference *scriptReference;
			NSString *docType;
			
			shouldSaveToFile = [chooseScriptController shouldSaveToFile];
			
			scriptReference = [chooseScriptController selectedScriptReference];
			docType = [[NSDocumentController sharedDocumentController] typeFromFileExtension:[[scriptReference path] pathExtension]];
			scriptDocument = [[[ScriptEditorDocument alloc] initWithContentsOfFile:[scriptReference path] ofType:docType] autorelease];
			[scriptDocument setReverseTransformation:[chooseScriptController reverseTransformation]];
			
			if ((inputString != nil) && (inputData == nil)) {
				inputData = [[inputString stringWithLineEndings:[scriptDocument inputLineEndings]] dataUsingEncoding:[scriptDocument inputStringEncoding]];
			}
			
			scriptSession = [scriptDocument preparedScriptSessionWithVariables:[chooseScriptController variables]];
			newData = [scriptSession dataFromTransformingInputData:inputData];
			
			switch ([scriptDocument outputType]) {
				case ScriptImageOutputType:
					image = [[[NSImage alloc] initWithData:newData] autorelease];
					if (image != nil) {
						types = [NSArray arrayWithObject:NSTIFFPboardType];
						[pboard declareTypes:types owner:nil];
						[pboard setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
					}
						break;
				case ScriptTextOutputType:
				case ScriptWebOutputType:
				default:
					newString = [NSString stringByGuessingEncodingOfData:newData];
					types = [NSArray arrayWithObject:NSStringPboardType];
					[pboard declareTypes:types owner:nil];
					[pboard setString:newString forType:NSStringPboardType];
					break;
			}
			
			if (shouldSaveToFile) {
				NSSavePanel *savePanel = [NSSavePanel savePanel];
				if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
					[newData writeToFile:[savePanel filename] atomically:YES];
				}
			}
		}
	}
	
	[self endServiceRequestRestoringLastFrontApp:YES];
}

- (void)useAsInput:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    NSArray *types;
	ScriptDocument *scriptDocument;
	NSString *inputString;
	
	[self beginServiceRequestAndBringToFront:YES];
	
    types = [pboard types];
	
	if ([types containsObject:NSFilenamesPboardType]) {
		inputString = [NSString stringWithContentsOfFile:[[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	}
	else inputString = [pboard stringForType:NSStringPboardType];
	
	scriptDocument = [ScriptBrowserDocument sharedDocument];
	[scriptDocument setInput:inputString];
	[scriptDocument autoRunScript:self];
	
	[self endServiceRequestRestoringLastFrontApp:NO];
}

- (void)newScriptFromSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    NSArray *types;
	ScriptEditorDocument *scriptDocument;
	NSString *inputString;
	
	[self beginServiceRequestAndBringToFront:YES];
	
    types = [pboard types];
	
	if ([types containsObject:NSFilenamesPboardType]) {
		inputString = [NSString stringWithContentsOfFile:[[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	}
	else inputString = [pboard stringForType:NSStringPboardType];
	
	scriptDocument = [[ScriptEditorDocument alloc] init];
	[scriptDocument makeWindowControllers];
	[scriptDocument setScript:inputString];
	[scriptDocument showWindows];
	[[NSDocumentController sharedDocumentController] addDocument:scriptDocument];
	[scriptDocument release];
	
	[self endServiceRequestRestoringLastFrontApp:NO];
}

- (void)presentEmptyScriptBrowserAlert
{
	NSAlert *alert;
	
	alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:@"No scripts available."];
	[alert setInformativeText:@"There are currently no scripts in the script browser. Please add at least one script which can be run as a service."];
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	[alert release];
}

- (void)presentNoServicesScriptBrowserAlert
{
	NSAlert *alert;
	
	alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:@"No service-capable scripts available."];
	[alert setInformativeText:@"There are currently no service-capable scripts in the script browser. Please add at least one script which can be run as a service."];
	[alert addButtonWithTitle:@"OK"];
	[alert runModal];
	[alert release];
}

@end
