//
//  ScriptSession.m
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptSession.h"

#import "Environment.h"

#import "ScriptVariable.h"
#import "ScriptDocument+Running.h"

@implementation ScriptSession

#pragma mark Init and Cleanup

+ (NSString *)generateUniqueSessionID
{
	static unsigned int serialNumber = 0;
	
	@synchronized (self) {
		return [NSString stringWithFormat:@"s%u", serialNumber++];
	}
	
	return nil; // never reached, but GCC seems to disagree
}

- (id)init
{
	if ((self = [super init])) {
		sessionID = [[[self class] generateUniqueSessionID] copy];
		scriptTask = [[JGBufferedTask alloc] init];
		temporaryFilePath = [[NSString alloc] initWithFormat:@"%@/%@.pid%d.%@", NSTemporaryDirectory(), [[NSBundle mainBundle] bundleIdentifier], [[NSProcessInfo processInfo] processIdentifier], sessionID];
		[self setupTemporaryFilePath];
	}
	return self;
}

- (void)addSupportFilesFromPath:(NSString *)supportPath
{
	BOOL result;
	
	NSParameterAssert(supportPath != nil);
	NSParameterAssert([supportPath isAbsolutePath]);
	
	result = [[NSFileManager defaultManager] createSymbolicLinkAtPath:[self scriptSupportPath] pathContent:supportPath];
	NSAssert2(result == YES, @"Failed to link script support path '%@' to temporary directory '%@'", supportPath, [self scriptSupportPath]);
}

- (void)addSupportFilesFromFileWrapper:(NSFileWrapper *)fileWrapper
{
	BOOL result;
	
	NSParameterAssert(fileWrapper != nil);
	
	result = [fileWrapper writeToFile:[self scriptSupportPath] atomically:NO updateFilenames:NO];
	NSAssert1(result == YES, @"Failed to write script support files to temporary directory '%@'", [self scriptSupportPath]);
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self cleanupTemporaryFilePath];
	[sessionID release];
	[scriptTask release];
	[temporaryFilePath release];
	[variables release];
	[additionalEnvironment release];
	[runCommand release];
	[argumentString release];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ScriptSession %p:%@>", self, [self scriptPath]];
}

#pragma mark Accessors

- (NSString *)sessionID
{
	return sessionID;
}

- (NSString *)temporaryFilePath
{
	return temporaryFilePath;
}

- (NSString *)temporaryWorkPath
{
	return [[self temporaryFilePath] stringByAppendingPathComponent:@"tmp"];
}

- (NSString *)scriptSupportPath
{
	return [[self temporaryFilePath] stringByAppendingPathComponent:@"support"];
}

- (JGBufferedTask *)scriptTask
{
	return scriptTask;
}

- (NSString *)scriptPath
{
	return scriptPath;
}

- (void)setScriptPath:(NSString *)newPath
{
	if (newPath != scriptPath) {
		[scriptPath release];
		scriptPath = [newPath copy];
	}
}

- (NSArray *)variables
{
    return variables; 
}

- (void)setVariables:(NSArray *)newVariables
{
    if (variables != newVariables) {
        [variables release];
        variables = [newVariables copy];
    }
}

- (NSDictionary *)additionalEnvironment
{
	return additionalEnvironment;
}

- (void)setAdditionalEnvironment:(NSDictionary *)newEnvironment
{
	if (newEnvironment != additionalEnvironment) {
		[additionalEnvironment release];
		additionalEnvironment = [newEnvironment copy];
	}
}

- (NSString *)runCommand
{
	return runCommand;
}

- (void)setRunCommand:(NSString *)newCommand
{
	if (newCommand != runCommand) {
		[runCommand release];
		runCommand = [newCommand copy];
	}
}

- (NSString *)argumentString
{
	return argumentString;
}

- (void)setArgumentString:(NSString *)newArguments
{
	if (newArguments != argumentString) {
		[argumentString release];
		argumentString = [newArguments copy];
	}
}

#pragma mark Variable Support

- (id)variableWithName:(NSString *)variableName
{
	NSEnumerator *variableEnumerator;
	ScriptVariable *currentVariable;
	
	NSParameterAssert(variableName != nil);
	
	variableEnumerator = [[self variables] objectEnumerator];
	while ((currentVariable = [variableEnumerator nextObject])) {
		if ([[currentVariable name] isEqualToString:variableName]) {
			return currentVariable;
		}
	}
	
	return nil;
}

#pragma mark Running Synchronously

- (NSData *)dataFromTransformingInputData:(NSData *)theData
{
	JGBufferedTask *newTask;
	NSData *resultData;
	
	NSParameterAssert(theData != nil);
	
	newTask = [self scriptTask];
	[[newTask inputBuffer] appendData:theData];
	[self launch];
	[newTask waitUntilReadingComplete];
	resultData = [[[newTask outputBuffer] copy] autorelease];
	
	return resultData;
}

#pragma mark Temporary File Management

- (void)setupTemporaryFilePath
{
	NSDictionary *temporaryFilePathAttributes;
	BOOL result;
	
	if (temporaryFilePath == nil)
		return;

	temporaryFilePathAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:0700], NSFilePosixPermissions,
		nil];
	
	result = [[NSFileManager defaultManager] createDirectoryAtPath:temporaryFilePath attributes:temporaryFilePathAttributes];
	NSAssert1(result == TRUE, @"Failed to create temporary directory '%@'", temporaryFilePath);
	
	result = [[NSFileManager defaultManager] createDirectoryAtPath:[self temporaryWorkPath] attributes:temporaryFilePathAttributes];
	NSAssert1(result == TRUE, @"Failed to create temporary directory '%@'", [self temporaryWorkPath]);
}

- (void)cleanupTemporaryFilePath
{
	if (temporaryFilePath == nil)
		return;
	
	NSAssert2([temporaryFilePath hasPrefix:NSTemporaryDirectory()], @"Temporary directory '%@' is not below system-wide temp path '%@'; refusing to delete", temporaryFilePath, NSTemporaryDirectory());
	
	[[NSFileManager defaultManager] removeFileAtPath:temporaryFilePath handler:nil];
}

- (void)launch
{
	NSMutableDictionary *taskEnvironment;
	NSMutableArray *taskArguments;
	NSEnumerator *variableEnumerator;
	ScriptVariable *currentVariable;
	NSTask *systemTask;
	NSEnumerator *componentEnumerator;
	NSString *currentComponent;
	
	systemTask = [[self scriptTask] lowLevelTask];
		
	// Prepare the script environment...
	taskEnvironment = [NSMutableDictionary dictionary];

	// Start with system environment
	[taskEnvironment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
	
	// Merge additional environment variables
	[taskEnvironment addEntriesFromDictionary:[self additionalEnvironment]];
	
	// Set session ID and script support path (managed by us)
	[taskEnvironment setObject:[self sessionID] forKey:PipeSessionIDEnvironmentKey];
	[taskEnvironment setObject:[self scriptSupportPath] forKey:PipeScriptSupportPathEnvironmentKey];
	[taskEnvironment setObject:[self temporaryWorkPath] forKey:PipeTemporaryWorkPathEnvironmentKey];
	
	// Add non-sensitive variables
	variableEnumerator = [[self variables] objectEnumerator];
	while ((currentVariable = [variableEnumerator nextObject])) {
		id value = [currentVariable value];
		if ((value != nil) && ([currentVariable isSensitive] == NO)) {
			switch ([currentVariable type]) {
				case ScriptTextVariableType:
				case ScriptPasswordVariableType:
					[taskEnvironment setObject:value forKey:[currentVariable name]];
					break;
				case ScriptBooleanVariableType:
					if ([value boolValue])
						[taskEnvironment setObject:@"1" forKey:[currentVariable name]];
					break;
				case ScriptEnumVariableType:
					if (([value intValue] >= 0) && ([value intValue] < [[currentVariable possibleValues] count])) {
						[taskEnvironment setObject:[[currentVariable possibleValues] objectAtIndex:[value intValue]] forKey:[currentVariable name]];
					}
					break;
			}
		}
	}
	
	// Environment done!
	[systemTask setEnvironment:taskEnvironment];
	
	[taskEnvironment setObject:[self scriptPath] forKey:@"script"];

	// Prepare arguments
	taskArguments = [NSMutableArray array];
	
	if ([self runCommand] != nil) {
		NSArray *runComponents;
								
		runComponents = [[self runCommand] commandLineComponents];
		
		NSAssert([runComponents count] > 0, @"Invalid run command (must contain at least a full path to an executable)");
		
		currentComponent = [[runComponents objectAtIndex:0] stringByReplacingPlaceholdersStartingWith:@"$" withStringsFromDictionary:taskEnvironment options:(JGPlaceholderCaseInsensitiveOption|JGPlaceholderKeepNonMatchingOption)];
		
		// The actual task to be launched is the first component of the run command
		[systemTask setLaunchPath:currentComponent];
		
		// Build the argument array while expanding all environment variables.
		componentEnumerator = [runComponents objectEnumerator];
		[componentEnumerator nextObject]; // skip the first component
		while ((currentComponent = [componentEnumerator nextObject])) {
			currentComponent = [currentComponent stringByReplacingPlaceholdersStartingWith:@"$" withStringsFromDictionary:taskEnvironment options:(JGPlaceholderCaseInsensitiveOption|JGPlaceholderKeepNonMatchingOption)];
			[taskArguments addObject:currentComponent];
		}
		
		// Now append the actual script arguments, again expanding environment variables.
		componentEnumerator = [[[self argumentString] commandLineComponents] objectEnumerator];
		while ((currentComponent = [componentEnumerator nextObject])) {
			currentComponent = [currentComponent stringByReplacingPlaceholdersStartingWith:@"$" withStringsFromDictionary:taskEnvironment options:(JGPlaceholderCaseInsensitiveOption|JGPlaceholderKeepNonMatchingOption)];
			[taskArguments addObject:currentComponent];
		}					
	}
	else {
		[systemTask setLaunchPath:[self scriptPath]];
		
		componentEnumerator = [[[self argumentString] commandLineComponents] objectEnumerator];
		while ((currentComponent = [componentEnumerator nextObject])) {
			currentComponent = [currentComponent stringByReplacingPlaceholdersStartingWith:@"$" withStringsFromDictionary:taskEnvironment options:(JGPlaceholderCaseInsensitiveOption|JGPlaceholderKeepNonMatchingOption)];
			[taskArguments addObject:currentComponent];
		}					
	}
	
	[taskEnvironment removeObjectForKey:@"script"];

	NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:[systemTask launchPath]], @"Script launch path '%@' does not exist", [systemTask launchPath]);

	[systemTask setArguments:taskArguments];
	[systemTask setCurrentDirectoryPath:[self temporaryFilePath]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptTaskDidTerminate:) name:JGBufferedTaskDidTerminateNotification object:scriptTask];
	[[self scriptTask] launch];
	[[self scriptTask] flushInputDataInBackground];
	[self retain];
}

- (void)abort
{
	[[self scriptTask] abort];
}

- (void)scriptTaskDidTerminate:(NSNotification *)aNotification
{
	[self autorelease];
}

@end
