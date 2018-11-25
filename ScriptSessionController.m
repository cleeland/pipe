//
//  ScriptSessionController.m
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptSessionController.h"
#import "ScriptSession.h"
#import "ScriptDocument+Running.h"

@implementation ScriptSessionController

+ (id)sharedController
{
	static id sharedInstance = nil;
	
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
	}
	return sharedInstance;
}

- (NSString *)connectionName
{
	return [NSString stringWithFormat:@"PipeSessionManager-%d", [[NSProcessInfo processInfo] processIdentifier]];
}

- (id)init
{
	if ((self = [super init])) {
		sessionDict = [[NSMutableDictionary alloc] init];
		serverConnection = [[NSConnection alloc] init];
		[serverConnection setRootObject:self];
		[serverConnection registerName:[self connectionName]];
	}
	return self;
}

- (void)dealloc
{
	[serverConnection release];
	[sessionDict release];
	[super dealloc];
}

- (void)registerSession:(ScriptSession *)aSession
{
	NSParameterAssert(aSession != nil);
	NSAssert([aSession sessionID] != nil, @"Attempt to register session with nil ID");
	
	[sessionDict setObject:[NSValue valueWithNonretainedObject:aSession] forKey:[aSession sessionID]];
}

- (void)unregisterSession:(ScriptSession *)aSession
{
	NSParameterAssert(aSession != nil);
	NSAssert([aSession sessionID] != nil, @"Attempt to register session with nil ID");
	
	[sessionDict removeObjectForKey:[aSession sessionID]];
}

- (ScriptSession *)sessionWithID:(NSString *)sessionID
{
	NSParameterAssert(sessionID != nil);
	
	return [[sessionDict objectForKey:sessionID] nonretainedObjectValue];
}

@end
