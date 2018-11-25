//
//  pipectl.m
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ScriptSessionController.h"
#import "ScriptSession.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSConnection *pipeConnection;
	NSString *connectionName, *sessionID;
	ScriptSessionController *sessionController;
	ScriptSession *session;
	id value;
	char const *utf8Value;
	NSString *varName;
	
	varName = [[[NSProcessInfo processInfo] arguments] objectAtIndex:1];
	
	connectionName = [[[NSProcessInfo processInfo] environment] objectForKey:@"PIPE_SESSION_SERVER"];
	sessionID = [[[NSProcessInfo processInfo] environment] objectForKey:@"PIPE_SESSION_ID"];
	
	pipeConnection = [NSConnection connectionWithRegisteredName:connectionName host:nil];
	[pipeConnection runInNewThread];
	[pipeConnection enableMultipleThreads];
	
	sessionController = (id)[pipeConnection rootProxy];
	session = [sessionController sessionWithID:sessionID];

	value = [[session variableWithName:varName] value];
	utf8Value = [[value description] UTF8String];
	if (utf8Value != NULL)
		fprintf(stdout, "%s", utf8Value);
	
	[pool release];
	return 0;
}
