//
//  ScriptDocument.h
//  Pipe
//
//  Created by René Puls on 18.01.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>
#import <JaguarAppKit/JaguarAppKit.h>

@class ScriptSession;

typedef enum {
	ScriptUnknownOutputType = 0,
	ScriptTextOutputType = 1,
	ScriptImageOutputType = 2,
	ScriptWebOutputType = 3
} ScriptOutputType;

extern NSString * const ScriptDocumentErrorNotification;
extern NSString * const ScriptDocumentWillRunNotification;
extern NSString * const ScriptDocumentScriptDidTerminateNotification;
extern NSString * const ScriptDocumentWillSaveNotification;
extern NSString * const ScriptDocumentWillRevertNotification;

/*! ScriptDocument is an abstract base class defining common attributes of scripts. A script is anything that consists of some form of executable instructions, and fits into the basic UNIX input-output pattern. */

@interface ScriptDocument : NSDocument <NSCopying> {
	NSString *script;
	NSString *input;
	NSString *output;
	NSString *errors;
	NSString *argumentString;
	NSString *runCommand;
	NSString *preferredScriptFileName;
	NSAttributedString *usageInfo;
	NSURL *homeURL;
	ScriptSession *currentSession;
	BOOL reverseTransformation;
	BOOL executesDirectly;
	NSData *inputData;
	NSData *outputData;
	ScriptOutputType outputType;
	NSStringEncoding scriptStringEncoding, inputStringEncoding, outputStringEncoding;
	NSWritingDirection inputWritingDirection, outputWritingDirection;
	NSMutableArray *variables;
	NSMutableArray *supportFiles;
	BOOL serviceCapable;
}
// Accessors
- (NSString *)script;
- (void)setScript:(NSString *)newScript;
- (NSData *)scriptData;
- (NSString *)input;
- (void)setInput:(NSString *)newInput;
- (NSData *)inputData;
- (void)setInputData:(NSData *)newData;
- (NSString *)output;
- (void)setOutput:(NSString *)newOutput;
- (NSData *)outputData;
- (void)setOutputData:(NSData *)newData;
- (ScriptOutputType)outputType;
- (void)setOutputType:(ScriptOutputType)newType;
- (NSString *)errors;
- (void)setErrors:(NSString *)errors;
- (NSString *)argumentString;
- (void)setArgumentString:(NSString *)newString;
- (NSString *)runCommand;
- (void)setRunCommand:(NSString *)newString;
- (NSAttributedString *)usageInfo;
- (void)setUsageInfo:(NSAttributedString *)newString;
- (NSURL *)homeURL;
- (void)setHomeURL:(NSURL *)newURL;
- (BOOL)executesDirectly;
- (void)setExecutesDirectly:(BOOL)flag;
- (BOOL)isReverseTransformation;
- (void)setReverseTransformation:(BOOL)flag;
- (NSFileWrapper *)supportDirectoryWrapper;
- (ScriptSession *)currentSession;
- (void)setCurrentSession:(ScriptSession *)newSession;
- (JGLineEndingsType)inputLineEndings;
- (NSStringEncoding)scriptStringEncoding;
- (void)setScriptStringEncoding:(NSStringEncoding)newScriptStringEncoding;
- (NSStringEncoding)inputStringEncoding;
- (void)setInputStringEncoding:(NSStringEncoding)newInputStringEncoding;
- (NSStringEncoding)outputStringEncoding;
- (void)setOutputStringEncoding:(NSStringEncoding)newOutputStringEncoding;
- (NSStringEncoding)errorStringEncoding;
- (NSWritingDirection)inputWritingDirection;
- (void)setInputWritingDirection:(NSWritingDirection)newDirection;
- (NSWritingDirection)outputWritingDirection;
- (void)setOutputWritingDirection:(NSWritingDirection)newDirection;
- (BOOL)isServiceCapable;
- (void)setServiceCapable:(BOOL)flag;
- (NSString *)preferredScriptFileName;
- (void)setPreferredScriptFileName:(NSString *)newName;
// variables
- (unsigned int)countOfVariables;
- (id)objectInVariablesAtIndex:(unsigned int)index;
- (void)insertObject:(id)anObject inVariablesAtIndex:(unsigned int)index;
- (void)removeObjectFromVariablesAtIndex:(unsigned int)index;
// support files
- (unsigned int)countOfSupportFiles;
- (id)objectInSupportFilesAtIndex:(unsigned int)index;
- (void)insertObject:(id)anObject inSupportFilesAtIndex:(unsigned int)index;
- (void)removeObjectFromSupportFilesAtIndex:(unsigned int)index;
- (void)updateSupportFiles;
@end
