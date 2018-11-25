//
//  ScriptSession.h
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>

@interface ScriptSession : NSObject {
	JGBufferedTask *scriptTask;
	NSString *sessionID;
	NSString *scriptPath;
	NSArray *variables;
	NSString *temporaryFilePath;
	NSDictionary *additionalEnvironment;
	NSString *runCommand;
	NSString *argumentString;
}
+ (NSString *)generateUniqueSessionID;
- (void)addSupportFilesFromPath:(NSString *)supportPath;
- (void)addSupportFilesFromFileWrapper:(NSFileWrapper *)fileWrapper;
// Accessors
- (NSString *)sessionID;
- (NSString *)temporaryFilePath;
- (NSString *)temporaryWorkPath;
- (NSString *)scriptSupportPath;
- (JGBufferedTask *)scriptTask;
- (NSString *)scriptPath;
- (void)setScriptPath:(NSString *)newPath;
- (NSArray *)variables;
- (void)setVariables:(NSArray *)newVariables;
- (NSDictionary *)additionalEnvironment;
- (void)setAdditionalEnvironment:(NSDictionary *)newEnvironment;
- (NSString *)runCommand;
- (void)setRunCommand:(NSString *)newCommand;
- (NSString *)argumentString;
- (void)setArgumentString:(NSString *)newArguments;
//
- (id)variableWithName:(NSString *)variableName;
- (NSData *)dataFromTransformingInputData:(NSData *)inputData;
- (void)setupTemporaryFilePath;
- (void)cleanupTemporaryFilePath;
- (void)launch;
- (void)abort;
@end
