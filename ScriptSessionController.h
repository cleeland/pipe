//
//  ScriptSessionController.h
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ScriptSession;

@interface ScriptSessionController : NSObject {
	NSMutableDictionary *sessionDict;
	NSConnection *serverConnection;
}
+ (id)sharedController;
- (NSString *)connectionName;
- (void)registerSession:(ScriptSession *)aSession;
- (void)unregisterSession:(ScriptSession *)aSession;
- (ScriptSession *)sessionWithID:(NSString *)sessionID;
@end
