//
//  ScriptDocument.m
//  Pipe
//
//  Created by René Puls on 18.01.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptDocument.h"
#import "ScriptDocument+Running.h"
#import "ScriptVariable.h"
#import "UserDefaults.h"
#import "ScriptSession.h"
#import "SupportFileReference.h"

static NSString * const VariableChangeContext = @"VariableChangeContext";

NSString * const ScriptDocumentErrorNotification = @"ScriptDocumentErrorNotification";
NSString * const ScriptDocumentScriptDidTerminateNotification = @"ScriptDocumentScriptDidTerminateNotification";
NSString * const ScriptDocumentWillRunNotification = @"ScriptDocumentWillRunNotification";
NSString * const ScriptDocumentWillSaveNotification = @"ScriptDocumentWillSaveNotification";
NSString * const ScriptDocumentWillRevertNotification = @"ScriptDocumentWillRevertNotification";

@implementation ScriptDocument

#pragma mark Init and Cleanup

- (id)init
{
	NSStringEncoding defaultStringEncoding;
	
	if ((self = [super init])) {
		variables = [[NSMutableArray alloc] init];
		supportFiles = [[NSMutableArray alloc] init];
		
		[[self undoManager] disableUndoRegistration];
		defaultStringEncoding = [JGUserDefaultValue(PipeTextEncodingDefaultKey) unsignedIntValue];
		[self setOutputType:ScriptTextOutputType];
		[self setScriptStringEncoding:defaultStringEncoding];
		[self setInputStringEncoding:defaultStringEncoding];
		[self setOutputStringEncoding:defaultStringEncoding];
		[self setServiceCapable:YES];
		[[self undoManager] enableUndoRegistration];
	}
	return self;
}

- (void)dealloc
{
	NSEnumerator *keyEnumerator;
	NSString *currentKey;
	NSIndexSet *indexSet;
	
	keyEnumerator = [[ScriptVariable observableKeys] objectEnumerator];
	indexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, [variables count])];
	while ((currentKey = [keyEnumerator nextObject])) {
		[variables removeObserver:self fromObjectsAtIndexes:indexSet forKeyPath:currentKey];
	}
	[indexSet release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[variables release];
	[supportFiles release];
	[script release];
	[input release];
	[inputData release];
	[output release];
	[outputData release];
	[errors release];
	[runCommand release];
	[argumentString release];
	[currentSession release];
	[usageInfo release];
	[homeURL release];
	[preferredScriptFileName release];
	
	[super dealloc];
}

#pragma mark Accessors

- (NSString *)script
{
    return script; 
}

- (void)setScript:(NSString *)newScript
{
    if (script != newScript) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setScript:) object:[[script copy] autorelease]];
        [script release];
        script = [newScript copy];
    }
}

- (NSData *)scriptData
{
	return [[[self script] stringWithLineEndings:JGLineEndingsTypeUNIX] dataUsingEncoding:[self scriptStringEncoding]];
}

- (NSString *)input
{
    return input; 
}

- (void)setInput:(NSString *)newInput
{
    if (input != newInput) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setInput:) object:[[input copy] autorelease]];
        [input release];
        input = [newInput copy];
		[self setInputData:nil];
    }
}

- (NSData *)inputData
{
	if ((inputData == nil) && (input != nil)) {
		inputData = [[[[self input] stringWithLineEndings:[self inputLineEndings]] dataUsingEncoding:[self inputStringEncoding]] retain];
	}
	return inputData;
}

- (void)setInputData:(NSData *)newData
{
	if (newData != inputData) {
		[inputData release];
		inputData = [newData copy];
	}
}

- (NSString *)output
{
	if ((output == nil) && (outputData != nil)) {
		output = [[NSString alloc] initWithData:[self outputData] encoding:[self outputStringEncoding]];
		if (output == nil) {
			output = [[NSString stringByGuessingEncodingOfData:[self outputData]] retain];
		}
	}
    return output; 
}

- (void)setOutput:(NSString *)newOutput
{
    if (output != newOutput) {
        [output release];
        output = [newOutput copy];
    }
}

- (NSData *)outputData
{
	return outputData;
}

- (void)setOutputData:(NSData *)newData
{
	if (outputData != newData) {
		[outputData release];
		outputData = [newData copy];
		[self setOutput:nil];
	}
}

- (ScriptOutputType)outputType
{
	return outputType;
}

- (void)setOutputType:(ScriptOutputType)newType
{
	if (newType != outputType) {
		[[[self undoManager] prepareWithInvocationTarget:self] setOutputType:outputType];
		outputType = newType;
	}
}

- (NSString *)errors
{
	return errors;
}

- (void)setErrors:(NSString *)newString
{
	if (newString != errors) {
		[errors release];
		errors = [newString copy];
	}
}

- (NSString *)argumentString
{
	return argumentString;
}

- (void)setArgumentString:(NSString *)newString
{
	if (argumentString != newString) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setArgumentString:) object:argumentString];
		[argumentString release];
		argumentString = [newString copy];
	}
}

- (NSString *)runCommand
{
	return runCommand;
}

- (void)setRunCommand:(NSString *)newString
{
	if (newString != runCommand) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setRunCommand:) object:runCommand];
		[runCommand release];
		runCommand = [newString copy];
	}
}

- (BOOL)executesDirectly
{
	return executesDirectly;
}

- (void)setExecutesDirectly:(BOOL)flag
{
	if (flag != executesDirectly) {
		[[[self undoManager] prepareWithInvocationTarget:self] setExecutesDirectly:executesDirectly];
		executesDirectly = flag;
	}
}

- (BOOL)isReverseTransformation
{
	return reverseTransformation;
}

- (void)setReverseTransformation:(BOOL)flag
{
	if (flag != reverseTransformation) {
		[[[self undoManager] prepareWithInvocationTarget:self] setReverseTransformation:reverseTransformation];
		reverseTransformation = flag;
	}
}

- (NSAttributedString *)usageInfo
{
	return usageInfo;
}

- (void)setUsageInfo:(NSAttributedString *)newString
{
	if (newString != usageInfo) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setUsageInfo:) object:usageInfo];
		[usageInfo release];
		usageInfo = [newString copy];
	}
}

- (NSURL *)homeURL
{
	return homeURL;
}

- (void)setHomeURL:(NSURL *)newURL
{
	if (newURL != homeURL) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setHomeURL:) object:homeURL];
		[homeURL release];
		homeURL = [newURL copy];
	}
}

- (NSFileWrapper *)supportDirectoryWrapper
{
	NSFileWrapper *directoryWrapper, *fileWrapper;
	NSMutableDictionary *fileWrappers;
	NSEnumerator *referenceEnumerator;
	SupportFileReference *currentReference;
	
	// Build a directory wrapper from all file wrappers
	fileWrappers = [[NSMutableDictionary alloc] init];
	referenceEnumerator = [[self valueForKey:@"supportFiles"] objectEnumerator];
	while ((currentReference = [referenceEnumerator nextObject])) {
		fileWrapper = [currentReference fileWrapper];
		[fileWrappers setObject:fileWrapper forKey:[fileWrapper preferredFilename]];
	}
	directoryWrapper = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers] autorelease];
	[directoryWrapper setPreferredFilename:@"Support Files"];
	[fileWrappers release];
	
	return directoryWrapper;
}

- (JGLineEndingsType)inputLineEndings
{
	return [JGUserDefaultValue(PipeInputLineEndingsConversionDefaultKey) intValue];
}

- (NSStringEncoding)scriptStringEncoding
{
    return scriptStringEncoding;
}

- (void)setScriptStringEncoding:(NSStringEncoding)newScriptStringEncoding
{
	if (newScriptStringEncoding != scriptStringEncoding) {
		[[[self undoManager] prepareWithInvocationTarget:self] setScriptStringEncoding:newScriptStringEncoding];
		scriptStringEncoding = newScriptStringEncoding;
	}
}

- (NSStringEncoding)inputStringEncoding
{
    return inputStringEncoding;
}

- (void)setInputStringEncoding:(NSStringEncoding)newInputStringEncoding
{
	if (inputStringEncoding != newInputStringEncoding) {
		[[[self undoManager] prepareWithInvocationTarget:self] setInputStringEncoding:newInputStringEncoding];
		inputStringEncoding = newInputStringEncoding;
		if ([self input] != nil)
			[self setInputData:nil];
	}
}

- (NSStringEncoding)outputStringEncoding
{
    return outputStringEncoding;
}

- (void)setOutputStringEncoding:(NSStringEncoding)newOutputStringEncoding
{
	if (outputStringEncoding != newOutputStringEncoding) {
		[[[self undoManager] prepareWithInvocationTarget:self] setOutputStringEncoding:newOutputStringEncoding];
		outputStringEncoding = newOutputStringEncoding;
	}
}

- (NSStringEncoding)errorStringEncoding
{
	return NSUTF8StringEncoding;
}

- (NSWritingDirection)inputWritingDirection
{
	return inputWritingDirection;
}

- (void)setInputWritingDirection:(NSWritingDirection)newDirection
{
	inputWritingDirection = newDirection;
}

- (NSWritingDirection)outputWritingDirection
{
	return outputWritingDirection;
}

- (void)setOutputWritingDirection:(NSWritingDirection)newDirection
{
	outputWritingDirection = newDirection;
}

- (BOOL)isServiceCapable
{
	return serviceCapable;
}

- (void)setServiceCapable:(BOOL)flag
{
	if (flag != serviceCapable) {
		[[[self undoManager] prepareWithInvocationTarget:self] setServiceCapable:serviceCapable];
		serviceCapable = flag;
	}
}

- (ScriptSession *)currentSession
{
	return currentSession;
}

- (void)setCurrentSession:(ScriptSession *)newSession
{
	if (newSession != currentSession) {
		if ([currentSession scriptTask]) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[currentSession scriptTask]];
			[[self currentSession] abort];
		}
		[currentSession release];
		currentSession = [newSession retain];
		if (currentSession != nil) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scriptTaskDidTerminate:) name:JGBufferedTaskDidTerminateNotification object:[currentSession scriptTask]];
		}
	}
}

- (NSString *)preferredScriptFileName
{
	return preferredScriptFileName;
}

- (void)setPreferredScriptFileName:(NSString *)newName
{
	if (newName != preferredScriptFileName) {
		[[self undoManager] registerUndoWithTarget:self selector:@selector(setPreferredScriptFileName:) object:preferredScriptFileName];
		[preferredScriptFileName release];
		preferredScriptFileName = [newName copy];
	}
}

#pragma mark Variables

- (unsigned int)countOfVariables 
{
    return [variables count];
}

- (id)objectInVariablesAtIndex:(unsigned int)anIndex 
{
    return [variables objectAtIndex:anIndex];
}

- (void)insertObject:(id)anObject inVariablesAtIndex:(unsigned int)anIndex 
{
	NSEnumerator *keyEnumerator;
	NSString *currentKey;
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeObjectFromVariablesAtIndex:anIndex];
    [variables insertObject:anObject atIndex:anIndex];
	keyEnumerator = [[ScriptVariable observableKeys] objectEnumerator];
	while ((currentKey = [keyEnumerator nextObject])) {
		[variables addObserver:self toObjectsAtIndexes:[NSIndexSet indexSetWithIndex:anIndex] forKeyPath:currentKey options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:VariableChangeContext];
	}
	
	if (![[self undoManager] isUndoing] && ![[self undoManager] isRedoing])
		[[self undoManager] setActionName:NSLocalizedString(@"Add Variable", @"Undo action name")];
}

- (void)removeObjectFromVariablesAtIndex:(unsigned int)anIndex 
{
	id anObject = [variables objectAtIndex:anIndex];
	NSEnumerator *keyEnumerator;
	NSString *currentKey;
	
	keyEnumerator = [[ScriptVariable observableKeys] objectEnumerator];
	while ((currentKey = [keyEnumerator nextObject])) {
		[variables removeObserver:self fromObjectsAtIndexes:[NSIndexSet indexSetWithIndex:anIndex] forKeyPath:currentKey];
	}

	[[[self undoManager] prepareWithInvocationTarget:self] insertObject:anObject inVariablesAtIndex:anIndex];
    [variables removeObjectAtIndex:anIndex];

	if (![[self undoManager] isUndoing] && ![[self undoManager] isRedoing])
		[[self undoManager] setActionName:NSLocalizedString(@"Delete Variable", @"Undo action name")];
}

#pragma mark Support Files

- (unsigned int)countOfSupportFiles 
{
    return [supportFiles count];
}

- (id)objectInSupportFilesAtIndex:(unsigned int)index 
{
    return [supportFiles objectAtIndex:index];
}

- (void)insertObject:(id)anObject inSupportFilesAtIndex:(unsigned int)index 
{
	[[[self undoManager] prepareWithInvocationTarget:self] removeObjectFromSupportFilesAtIndex:index];
    [supportFiles insertObject:anObject atIndex:index];
}

- (void)removeObjectFromSupportFilesAtIndex:(unsigned int)index 
{
	[[[self undoManager] prepareWithInvocationTarget:self] insertObject:[supportFiles objectAtIndex:index] inVariablesAtIndex:index];
    [supportFiles removeObjectAtIndex:index];
}

- (void)updateSupportFiles
{
	[[self valueForKey:@"supportFiles"] makeObjectsPerformSelector:@selector(updateFromSource)];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	NSDictionary *undoDict;
	static NSDictionary *keyToUndoActionDict = nil;
	
	if (keyToUndoActionDict == nil) {
		keyToUndoActionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"Change Variable Name", @"name",
			@"Change Variable Value", @"value",
			@"Change Variable Enum Values", @"possibleValues",
			@"Change Variable Type", @"type",
			@"Change Variable Sensitive Flag", @"sensitive",
			nil];
	}
	
	if (context == VariableChangeContext) {

		undoDict = [NSDictionary dictionaryWithObject:oldValue forKey:keyPath];
		[[self undoManager] registerUndoWithTarget:object selector:@selector(setValuesForKeysWithDictionary:) object:undoDict];

		if (![[self undoManager] isUndoing] && ![[self undoManager] isRedoing] && ([keyToUndoActionDict objectForKey:keyPath] != nil))
			[[self undoManager] setActionName:[keyToUndoActionDict objectForKey:keyPath]];
		[self autoRunScript:self];
	}
}

#pragma mark NSCopying and Equality

- (id)copyWithZone:(NSZone *)newZone
{
	ScriptDocument *newInstance;
	
	newInstance = [[[self class] allocWithZone:newZone] init];
	
	[newInstance setScriptStringEncoding:[self scriptStringEncoding]];
	[newInstance setInputStringEncoding:[self inputStringEncoding]];
	[newInstance setOutputStringEncoding:[self outputStringEncoding]];
	
	[newInstance setScript:[self script]];
	[newInstance setInput:[self input]];
	[newInstance setOutputData:[self outputData]];
	
	[newInstance setErrors:[self errors]];
	[newInstance setOutputType:[self outputType]];
	
	[newInstance setArgumentString:[self argumentString]];
	[newInstance setRunCommand:[self runCommand]];
	
	[newInstance setUsageInfo:[self usageInfo]];
	[newInstance setHomeURL:[self homeURL]];
	
	[newInstance setExecutesDirectly:[self executesDirectly]];
	[newInstance setReverseTransformation:[self isReverseTransformation]];
	[newInstance setServiceCapable:[self isServiceCapable]];

	[newInstance setPreferredScriptFileName:[self preferredScriptFileName]];
	[[newInstance mutableArrayValueForKey:@"variables"] setArray:[self valueForKey:@"variables"]];
	[[newInstance mutableArrayValueForKey:@"supportFiles"] setArray:[self valueForKey:@"supportFiles"]];
	
	return newInstance;
}

- (BOOL)isEqual:(id)otherObject
{
	if (otherObject == self)
		return YES;
	if (![otherObject isMemberOfClass:[self class]])
		return NO;

	if ([otherObject scriptStringEncoding] != [self scriptStringEncoding])
		return NO;
	if ([otherObject inputStringEncoding] != [self inputStringEncoding])
		return NO;
	if ([otherObject outputStringEncoding] != [self outputStringEncoding])
		return NO;

	if ([otherObject script] != [self script])
		if (![[otherObject script] isEqualToString:[self script]])
			return NO;
	
	if ([otherObject input] != [self input])
		if (![[otherObject input] isEqualToString:[self input]])
			return NO;
	
	if ([otherObject outputData] != [self outputData])
		if (![[otherObject outputData] isEqualToData:[self outputData]])
			return NO;

	if ([otherObject errors] != [self errors])
		if (![[otherObject errors] isEqualToString:[self errors]])
			return NO;
	
	if ([otherObject outputType] != [self outputType])
		return NO;
	
	if ([otherObject argumentString] != [self argumentString])
		if (![[otherObject argumentString] isEqualToString:[self argumentString]])
			return NO;

	if ([otherObject runCommand] != [self runCommand])
		if (![[otherObject runCommand] isEqualToString:[self runCommand]])
			return NO;
	
	if ([otherObject usageInfo] != [self usageInfo])
		if (![[otherObject usageInfo] isEqualToAttributedString:[self usageInfo]])
			return NO;
	
	if ([otherObject homeURL] != [self homeURL])
		if (![[otherObject homeURL] isEqual:[self homeURL]])
			return NO;

	if ([otherObject executesDirectly] != [self executesDirectly])
		return NO;
	if ([otherObject isReverseTransformation] != [self isReverseTransformation])
		return NO;
	if ([otherObject isServiceCapable] != [self isServiceCapable])
		return NO;
	
	if ([otherObject supportDirectoryWrapper] != [self supportDirectoryWrapper])
		if (![[[otherObject supportDirectoryWrapper] serializedRepresentation] isEqualToData:[[self supportDirectoryWrapper] serializedRepresentation]])
			return NO;
	
	if ([otherObject preferredScriptFileName] != [self preferredScriptFileName])
		if (![[otherObject preferredScriptFileName] isEqualToString:[self preferredScriptFileName]])
			return NO;
	
	if (![[otherObject valueForKey:@"variables"] isEqualToArray:[self valueForKey:@"variables"]])
		return NO;
	
	return YES;
}

@end
