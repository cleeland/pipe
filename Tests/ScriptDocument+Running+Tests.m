//
//  ScriptDocument+Running+Tests.m
//  Pipe
//
//  Created by René Puls on 29.03.05.
//  Copyright (c) 2005 René Puls. All rights reserved.
//

#import "ScriptDocument+Running+Tests.h"
#import "ScriptDocument+Running.h"
#import "ScriptSession.h"
#import "ScriptVariable.h"

@implementation ScriptDocument_Running_Tests

- (id)init
{
	ScriptVariable *variable;
	
	if ((self = [super init])) {
		testDocument = [[ScriptDocument alloc] init];
		
		[testDocument setScript:@"#!/bin/sh\necho -n hello $thing\necho `cat`\n"];
		[testDocument setInput:@"foo"];
		[testDocument setOutputData:[@"hello worldfoo\n" dataUsingEncoding:NSUTF8StringEncoding]];
		
		variable = [[ScriptVariable alloc] initWithName:@"thing" value:@"world"];
		[variable setSensitive:NO];
		[testDocument insertObject:variable inVariablesAtIndex:0];
		[variable release];
	}
	return self;
}

- (void)dealloc
{
	[testDocument release];
	[super dealloc];
}

- (void)testRunning
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	ScriptSession *session;
	NSData *outputData;
	NSString *outputString;
	BOOL result, isDirectory;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *tempPath;
	
	session = [testDocument preparedScriptSessionWithVariables:nil];
	tempPath = [[session temporaryFilePath] retain];
	
	// Check if the session temp directory exists
	result = [fileManager fileExistsAtPath:tempPath isDirectory:&isDirectory];
	UKTrue(result);
	UKTrue(isDirectory);
	
	// Run the session
	outputData = [session dataFromTransformingInputData:[testDocument inputData]];
	outputString = [[[NSString alloc] initWithData:outputData encoding:[testDocument outputStringEncoding]] autorelease];
	UKStringsEqual([testDocument output], outputString);
	
	[pool release]; // release the session

	// Make sure the temporary directory was deleted
	result = [fileManager fileExistsAtPath:tempPath];
	UKFalse(result);
	[tempPath release];
}

@end
