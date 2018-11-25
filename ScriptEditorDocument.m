//
//	ScriptEditorDocument.m
//	Pipe
//
//	Created by René Puls on 14.02.05.
//	Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptEditorDocument.h"
#import "ScriptWindowController.h"
#import "ScriptDocumentError.h"
#import "ScriptVariable.h"
#import "KwikiController.h"
#import "ScriptReference.h"
#import "UserDefaults.h"
#import "SupportFileReference.h"

// Pipe Script document type names
// Don't forget to sync changes with the application Info.plist!
NSString * const PipeScriptDocumentType = @"Pipe Script";
NSString * const PipeScriptFlatDocumentType = @"Pipe Script (flattened)";
NSString * const PipeShellScriptDocumentType = @"Shell Script";

// Property list keys used in Pipe Script bundles
NSString * const PipeScriptArgumentStringPlistKey = @"PipeArgumentString";
NSString * const PipeScriptCodeStringEncodingPlistKey = @"PipeScriptStringEncoding";
NSString * const PipeScriptEditorWindowPropertiesPlistKey = @"PipeEditorWindowProperties";
NSString * const PipeScriptExecutesDirectlyPlistKey = @"PipeExecutesDirectly";
NSString * const PipeScriptHomeURLPlistKey = @"PipeHomeURL";
NSString * const PipeScriptInputStringEncodingPlistKey = @"PipeInputStringEncoding";
NSString * const PipeScriptLastSavedPlistKey = @"PipeLastSaved";
NSString * const PipeScriptOutputStringEncodingPlistKey = @"PipeOutputStringEncoding";
NSString * const PipeScriptOutputTypePlistKey = @"PipeOutputType";
NSString * const PipeScriptPreferredFileNameKey = @"PipePreferredScriptFileName";
NSString * const PipeScriptRunCommandPlistKey = @"PipeRunCommand";
NSString * const PipeScriptServiceCapablePlistKey = @"PipeServiceCapable";
NSString * const PipeScriptSourceAliasPlistKey = @"PipeScriptSourceAlias";
NSString * const PipeScriptVariablesPlistKey = @"PipeVariables";
NSString * const PipeScriptVersionPlistKey = @"PipeScriptVersion";
NSString * const PipeScriptInputWritingDirectionPlistKey = @"PipeInputWritingDirection";
NSString * const PipeScriptOutputWritingDirectionPlistKey = @"PipeOutputWritingDirection";

// Notifications
NSString * const ScriptEditorDocumentApplySavedPropertyListNotification = @"ScriptEditorDocumentApplySavedPropertyListNotification";
NSString * const ScriptEditorDocumentCollectSavedPropertyListNotification = @"ScriptEditorDocumentCollectSavedPropertyListNotification";


@implementation ScriptEditorDocument

#pragma mark Init and Cleanup

- (id)init
{
	if ((self = [super init])) {
		[self setHasUndoManager:YES];
		[[self undoManager] disableUndoRegistration];
		[self setExecutesDirectly:YES];
		[[self undoManager] enableUndoRegistration];
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType
{
	if ((self = [super initWithContentsOfFile:fileName ofType:docType])) {
		if ([docType isEqualToString:PipeShellScriptDocumentType]) {
			[self setFileType:PipeScriptDocumentType];
			[self setFileName:nil];
		}
		[[self undoManager] removeAllActions];
	}
	return self;
}

- (id)initWithTemplatePath:(NSString *)aPath
{
	NSParameterAssert(aPath != nil);
	
	if ((self = [self initWithContentsOfFile:aPath ofType:PipeScriptDocumentType])) {
		[self setFileName:nil];
		[self setScriptSourceAlias:nil];
	}
	return self;
}

- (void)dealloc
{
	[lastLoadedPropertyList release];
	[scriptSourceAlias release];
	[super dealloc];
}

#pragma mark Accessors

- (NDAlias *)scriptSourceAlias
{
	return scriptSourceAlias; 
}

- (void)setScriptSourceAlias:(NDAlias *)newScriptSourceAlias
{
	if (scriptSourceAlias != newScriptSourceAlias) {
		[scriptSourceAlias release];
		scriptSourceAlias = [newScriptSourceAlias retain];
	}
}

- (NSDictionary *)propertyList
{
	NSMutableDictionary *propertyList;
	
	propertyList = [NSMutableDictionary dictionary];

	// Collect saved property lists from other document components
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptEditorDocumentCollectSavedPropertyListNotification object:self userInfo:[NSDictionary dictionaryWithObject:propertyList forKey:@"propertyList"]];
	
	[propertyList setObject:[NSNumber numberWithBool:[self executesDirectly]]
					 forKey:PipeScriptExecutesDirectlyPlistKey];
	[propertyList setObject:[NSNumber numberWithInt:[self outputType]]
					 forKey:PipeScriptOutputTypePlistKey];
	[propertyList setObject:[NSDate date]
					 forKey:PipeScriptLastSavedPlistKey];
	[propertyList setObject:[NSNumber numberWithInt:1] 
					 forKey:PipeScriptVersionPlistKey];
	if ([self runCommand] != nil)
		[propertyList setObject:[self runCommand] 
						 forKey:PipeScriptRunCommandPlistKey];
	if ([self argumentString] != nil)
		[propertyList setObject:[self argumentString] 
						 forKey:PipeScriptArgumentStringPlistKey];
	if ([self homeURL] != nil)
		[propertyList setObject:[[self homeURL] absoluteString]
						 forKey:PipeScriptHomeURLPlistKey];
	[propertyList setObject:[NSNumber numberWithUnsignedInt:[self scriptStringEncoding]]
					 forKey:PipeScriptCodeStringEncodingPlistKey];
	[propertyList setObject:[NSNumber numberWithUnsignedInt:[self inputStringEncoding]]
					 forKey:PipeScriptInputStringEncodingPlistKey];
	[propertyList setObject:[NSNumber numberWithUnsignedInt:[self outputStringEncoding]]
					 forKey:PipeScriptOutputStringEncodingPlistKey];
	if ([self preferredScriptFileName] != nil)
		[propertyList setObject:[self preferredScriptFileName] 
						 forKey:PipeScriptPreferredFileNameKey];
	if ([self scriptSourceAlias])
		[propertyList setObject:[NSArchiver archivedDataWithRootObject:[self scriptSourceAlias]]
						 forKey:PipeScriptSourceAliasPlistKey];
	[propertyList setObject:[ScriptVariable propertyListFromVariablesArray:[self valueForKey:@"variables"]]
					 forKey:PipeScriptVariablesPlistKey];
	[propertyList setObject:[NSNumber numberWithBool:[self isServiceCapable]]
					 forKey:PipeScriptServiceCapablePlistKey];
	[propertyList setObject:[NSNumber numberWithInt:[self inputWritingDirection]]
					 forKey:PipeScriptInputWritingDirectionPlistKey];
	[propertyList setObject:[NSNumber numberWithInt:[self outputWritingDirection]]
					 forKey:PipeScriptOutputWritingDirectionPlistKey];
	
	return propertyList;
}

/*! The last property list that was read from disk. */
- (NSDictionary *)lastLoadedPropertyList
{
	return lastLoadedPropertyList;
}

- (void)setLastLoadedPropertyList:(NSDictionary *)newPropertyList
{
	if (newPropertyList != lastLoadedPropertyList) {
		[lastLoadedPropertyList release];
		lastLoadedPropertyList = [newPropertyList copy];
	}
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
	id newWindowController;
	
	if (!didMakeWindowControllers) {
		newWindowController = [[ScriptWindowController alloc] init];
		[self addWindowController:newWindowController];
		[newWindowController release];
		
		if ([self lastLoadedPropertyList] != nil) {
			[[NSNotificationCenter defaultCenter] postNotificationName:ScriptEditorDocumentApplySavedPropertyListNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self lastLoadedPropertyList] forKey:@"propertyList"]];
			[self setLastLoadedPropertyList:nil];
		}
		
		didMakeWindowControllers = YES;
	}
}

- (BOOL)revertToSavedFromFile:(NSString *)fileName ofType:(NSString *)type
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentWillRevertNotification object:self];
	
	if ([type isEqualToString:PipeShellScriptDocumentType]) {
		[[self undoManager] setActionName:NSLocalizedString(@"Revert to External Source", @"Undo action name (revert to external script source)")];
		return [self readFromFile:fileName ofType:type];
	}
	else {
		return [super revertToSavedFromFile:fileName ofType:type];
	}
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
	NSFileWrapper *fileWrapper;
	
	fileWrapper = [[[NSFileWrapper alloc] initWithPath:fileName] autorelease];
	if ([docType isEqualToString:PipeShellScriptDocumentType])
		[self setScriptSourceAlias:[NDAlias aliasWithPath:fileName]];
	
	return [self loadFileWrapperRepresentation:fileWrapper ofType:docType];
}

- (BOOL)loadFileWrapperRepresentation:(NSFileWrapper *)wrapper ofType:(NSString *)docType
{
	NSDictionary *newPropertyList;
	NSString *errorString = nil;
	NSError *error = nil;
	NSData *data;
	NSString *string;
	NSFileWrapper *usageWrapper, *supportWrapper;
	id property;
	
	if ([docType isEqualToString:PipeScriptFlatDocumentType]) {
		NSFileWrapper *myWrapper;
		NSData *serializedData;
		
		serializedData = [wrapper regularFileContents];
		myWrapper = [[[NSFileWrapper alloc] initWithSerializedRepresentation:serializedData] autorelease];
		return [self loadFileWrapperRepresentation:myWrapper ofType:PipeScriptDocumentType];
	}
	else if ([docType isEqualToString:PipeScriptDocumentType]) {
		
		// Check if the file wrapper represents a bundle
		if (![wrapper isDirectory]) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentNotABundleError userInfo:nil];
			goto openError;
		}
		
		if ([[wrapper fileWrappers] objectForKey:@"Contents"])
			wrapper = [[wrapper fileWrappers] objectForKey:@"Contents"];
		
		// Read Info.plist
		data = [[[wrapper fileWrappers] objectForKey:@"Info.plist"] regularFileContents];
		if (data == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentIncompleteError userInfo:[NSDictionary dictionaryWithObject:@"Info.plist" forKey:@"missingFileName"]];
			goto openError;
		}
		
		newPropertyList = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
		if (newPropertyList == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentBadInfoPlistError userInfo:[NSDictionary dictionaryWithObject:errorString forKey:@"errorString"]];
			goto openError;
		}
		
		[self setArgumentString:[newPropertyList objectForKey:PipeScriptArgumentStringPlistKey]];
		[self setRunCommand:[newPropertyList objectForKey:PipeScriptRunCommandPlistKey]];
		
		if ((property = [newPropertyList objectForKey:PipeScriptHomeURLPlistKey]))
			[self setHomeURL:[NSURL URLWithString:property]];
		else
			[self setHomeURL:nil];
		
		if ((property = [newPropertyList objectForKey:PipeScriptExecutesDirectlyPlistKey]))
			[self setExecutesDirectly:[property boolValue]];
		else 
			[self setExecutesDirectly:YES];
		
		if ((property = [newPropertyList objectForKey:PipeScriptOutputTypePlistKey])) 
			[self setOutputType:[property intValue]];
		
		if ((property = [newPropertyList objectForKey:PipeScriptCodeStringEncodingPlistKey]))
			[self setScriptStringEncoding:[property unsignedIntValue]];
		else 
			[self setScriptStringEncoding:[JGUserDefaultValue(PipeTextEncodingDefaultKey) unsignedIntValue]];
		
		if ((property = [newPropertyList objectForKey:PipeScriptInputStringEncodingPlistKey]))
			[self setInputStringEncoding:[property unsignedIntValue]];
		else 
			[self setInputStringEncoding:[JGUserDefaultValue(PipeTextEncodingDefaultKey) unsignedIntValue]];
		
		if ((property = [newPropertyList objectForKey:PipeScriptOutputStringEncodingPlistKey]))
			[self setOutputStringEncoding:[property unsignedIntValue]];
		else 
			[self setOutputStringEncoding:[JGUserDefaultValue(PipeTextEncodingDefaultKey) unsignedIntValue]];
		
		if ((property = [newPropertyList objectForKey:PipeScriptSourceAliasPlistKey]))
			[self setScriptSourceAlias:[NSUnarchiver unarchiveObjectWithData:property]];
		else
			[self setScriptSourceAlias:nil];
		
		if ((property = [newPropertyList objectForKey:PipeScriptServiceCapablePlistKey]))
			[self setServiceCapable:[property boolValue]];
		else
			[self setServiceCapable:YES];
		
		if ((property = [newPropertyList objectForKey:PipeScriptPreferredFileNameKey]))
			[self setPreferredScriptFileName:property];
		else
			[self setPreferredScriptFileName:nil];
		
		if ((property = [newPropertyList objectForKey:PipeScriptInputWritingDirectionPlistKey]))
			[self setInputWritingDirection:[property intValue]];
		else
			[self setInputWritingDirection:NSWritingDirectionLeftToRight];

		if ((property = [newPropertyList objectForKey:PipeScriptOutputWritingDirectionPlistKey]))
			[self setOutputWritingDirection:[property intValue]];
		else
			[self setOutputWritingDirection:NSWritingDirectionLeftToRight];
		
		[[self mutableArrayValueForKey:@"variables"] removeAllObjects];
		if ((property = [newPropertyList objectForKey:PipeScriptVariablesPlistKey])) {
			[[self mutableArrayValueForKey:@"variables"] setArray:[ScriptVariable arrayWithVariablesFromPropertyList:property]];
		}
		
		// Load script source
		data = [[[wrapper fileWrappers] objectForKey:@"Script.txt"] regularFileContents];
		if (data == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentIncompleteError userInfo:[NSDictionary dictionaryWithObject:@"Script.txt" forKey:@"missingFileName"]];
			goto openError;
		}
		string = [[NSString alloc] initWithData:data encoding:[self scriptStringEncoding]];
		if (string == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentBadEncodingError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:[self scriptStringEncoding]], @"expectedEncoding", @"Script.txt", @"fileName", nil]];
			goto openError;
		}
		[self setScript:string];
		[string release];
		
		// Load input
		data = [[[wrapper fileWrappers] objectForKey:@"Input.txt"] regularFileContents];
		if (data == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentIncompleteError userInfo:[NSDictionary dictionaryWithObject:@"Input.txt" forKey:@"missingFileName"]];
			goto openError;
		}
		string = [[NSString alloc] initWithData:data encoding:[self inputStringEncoding]];
		if (string == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentBadEncodingError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:[self scriptStringEncoding]], @"expectedEncoding", @"Input.txt", @"fileName", nil]];
			goto openError;
		}
		[self setInput:string];
		[string release];
		
		// Load output
		data = [[[wrapper fileWrappers] objectForKey:@"Output.txt"] regularFileContents];
		if (data == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentIncompleteError userInfo:[NSDictionary dictionaryWithObject:@"Output.txt" forKey:@"missingFileName"]];
			goto openError;
		}
		[self setOutputData:data];
		
		// Load usage info
		usageWrapper = [[wrapper fileWrappers] objectForKey:@"Usage.rtfd"];
		if (usageWrapper != nil) {
			[self setUsageInfo:[[[NSAttributedString alloc] initWithRTFDFileWrapper:usageWrapper documentAttributes:nil] autorelease]];
		}
		
		// Load support files
		[[self mutableArrayValueForKey:@"supportFiles"] removeAllObjects];
		data = [[[wrapper fileWrappers] objectForKey:@"SupportFiles.keyedarchive"] regularFileContents];
		if (data != nil) {
			[[self mutableArrayValueForKey:@"supportFiles"] setArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
		} 
		else if ((supportWrapper = [[wrapper fileWrappers] objectForKey:@"Support Files"])) {
			// Import old support directory from previous versions
			if ([supportWrapper isDirectory]) {
				NSEnumerator *nameEnumerator;
				NSString *currentName;
				NSFileWrapper *currentWrapper;
				SupportFileReference *reference;
				
				nameEnumerator = [[supportWrapper fileWrappers] keyEnumerator];
				while ((currentName = [nameEnumerator nextObject])) {
					currentWrapper = [[supportWrapper fileWrappers] objectForKey:currentName];
					reference = [[SupportFileReference alloc] init];
					[reference setFileWrapper:currentWrapper];
					[self insertObject:reference inSupportFilesAtIndex:[self countOfSupportFiles]];
					[reference release];
				}
			}
		}

		// Broadcast the property list to all observers, so they can restore their state
		[[NSNotificationCenter defaultCenter] postNotificationName:ScriptEditorDocumentApplySavedPropertyListNotification object:self userInfo:[NSDictionary dictionaryWithObject:newPropertyList forKey:@"propertyList"]];
		if (!didMakeWindowControllers)
			[self setLastLoadedPropertyList:newPropertyList];
	}
	else if ([docType isEqualToString:PipeShellScriptDocumentType]) {
		NSStringEncoding scriptEncoding;
		
		scriptEncoding = [JGUserDefaultValue(PipeLastSelectedTextEncodingInFilePanelDefaultKey) unsignedIntValue];
		
		string = [[NSString alloc] initWithData:[wrapper regularFileContents] encoding:scriptEncoding];
		if (string == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentBadEncodingError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:[self scriptStringEncoding]], @"expectedEncoding", nil]];
			goto openError;
		}
		[self setScript:string];
		[string release];
	}
	
	return YES;
	
openError:
		NSLog(@"Error reading script: %@", error);
	return NO;
	
}

- (void)saveToFile:(NSString *)fileName saveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	[super saveToFile:fileName saveOperation:saveOperation delegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
	[[self reference] updateFromDocument:self];
}

- (BOOL)writeToFile:(NSString *)fullDocumentPath ofType:(NSString *)docType originalFile:(NSString *)fullOriginalDocumentPath saveOperation:(NSSaveOperationType)saveOperationType
{
	if (docType == nil)
		docType = PipeScriptDocumentType;
	
	// Ugly undo bug workaround
	[[NSRunLoop currentRunLoop] performSelector:@selector(fixUpUndoAfterSave:) target:self argument:nil order:NSUndoCloseGroupingRunLoopOrdering+1 modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];

	return [super writeToFile:fullDocumentPath ofType:docType originalFile:fullOriginalDocumentPath saveOperation:saveOperationType];
}

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)docType
{
	NSFileWrapper *contentsWrapper, *dirWrapper, *scriptWrapper, *inputWrapper, *outputWrapper, *propertyListWrapper, *usageWrapper, *supportWrapper;
	NSMutableDictionary *wrapperDict;
	NSDictionary *newPropertyList;
	NSData *propertyListData;
	NSString *errorString = nil;
	NSError *error = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentWillSaveNotification object:self];
		
	if ([docType isEqualToString:PipeScriptFlatDocumentType]) {
		NSFileWrapper *myWrapper;
		NSData *serializedData;

		myWrapper = [self fileWrapperRepresentationOfType:PipeScriptDocumentType];
		serializedData = [myWrapper serializedRepresentation];
		return [[[NSFileWrapper alloc] initRegularFileWithContents:serializedData] autorelease];
	}
	else if ([docType isEqualToString:PipeScriptDocumentType]) {
		// Create a property list
		newPropertyList = [self propertyList];
		propertyListData = [NSPropertyListSerialization dataFromPropertyList:newPropertyList format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
		if (propertyListData == nil) {
			error = [ScriptDocumentError errorWithCode:ScriptDocumentBadInfoPlistError userInfo:[NSDictionary dictionaryWithObject:errorString forKey:@"errorString"]];
			return nil;
		}
		
		scriptWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[script dataUsingEncoding:[self scriptStringEncoding]]];
		inputWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[self inputData]];
		outputWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[self outputData]];
		propertyListWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:propertyListData];
		usageWrapper = [[self usageInfo] RTFDFileWrapperFromRange:NSMakeRange(0, [[self usageInfo] length]) documentAttributes:nil];
		supportWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:[NSKeyedArchiver archivedDataWithRootObject:[self valueForKey:@"supportFiles"]]];
		
		wrapperDict = [[NSMutableDictionary alloc] init];
		
		[wrapperDict setObject:scriptWrapper forKey:@"Script.txt"];
		[wrapperDict setObject:inputWrapper forKey:@"Input.txt"];
		[wrapperDict setObject:outputWrapper forKey:@"Output.txt"];
		[wrapperDict setObject:propertyListWrapper forKey:@"Info.plist"];
		[wrapperDict setObject:supportWrapper forKey:@"SupportFiles.keyedarchive"];
		
		if (usageWrapper != nil)
			[wrapperDict setObject:usageWrapper forKey:@"Usage.rtfd"];
		
		[scriptWrapper release];
		[inputWrapper release];
		[outputWrapper release];
		[propertyListWrapper release];
		[supportWrapper release];
		
		contentsWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrapperDict];
		[wrapperDict release];
		dirWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:[NSDictionary dictionaryWithObject:contentsWrapper forKey:@"Contents"]];
		[contentsWrapper release];
		
		return [dirWrapper autorelease];
	}
	
	return nil;
}

- (void)saveDocument:(id)sender
{
	[super saveDocument:sender];
	[[self reference] updateFromDocument:self];
}

#pragma mark Actions

- (IBAction)saveDocumentAsTemplate:(id)sender
{
	NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSString *directory;

	directory = [NSString stringWithFormat:@"%@/Library/Application Support/%@/Templates", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:[[documentController fileExtensionsFromType:PipeScriptDocumentType] objectAtIndex:0], [[documentController fileExtensionsFromType:PipeScriptFlatDocumentType] objectAtIndex:0], nil]];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel beginSheetForDirectory:directory file:nil modalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(saveDocumentAsTemplateDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)saveDocumentAsTemplateDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[self setFileType:PipeScriptDocumentType];
		[self saveToFile:[sheet filename] saveOperation:NSSaveAsOperation delegate:nil didSaveSelector:NULL contextInfo:NULL];
		
		// FIXME some other time -- fileTypeFromLastBlah... returns nil
		[self setFileType:PipeScriptDocumentType];
	}
}

- (IBAction)revertToExternalScriptSource:(id)sender
{
	NSAlert *alert;
	
	alert = [[NSAlert alloc] init];
	[alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to revert to the last saved revision of the external source file '%@'?", @"Alert message requesting confirmation for a 'Revert to Script Source' command"), [[NSFileManager defaultManager] displayNameAtPath:[[self scriptSourceAlias] path]]]];
	[alert setInformativeText:NSLocalizedString(@"Your current changes to the script source will be lost.", @"Informative text for alert message requesting confirmation for a 'Revert to Script Source' command")];
	[alert addButtonWithTitle:NSLocalizedString(@"Revert", @"Button confirming a 'Revert to Script Source' command")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Button cancelling a 'Revert to Script Source' command")];
	[alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(revertToExternalScriptSourceDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[alert release];
}

- (void)revertToExternalScriptSourceDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
		[self revertToSavedFromFile:[[self scriptSourceAlias] path] ofType:PipeShellScriptDocumentType];
	}
}

- (IBAction)saveScriptSourceToFile:(id)sender
{
	NSSavePanel *savePanel;
	NSString *sourcePath;
	
	sourcePath = [[self scriptSourceAlias] path];
	
	if (([sender tag] == 1) && (sourcePath != nil)) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentWillSaveNotification object:self];
		[[self scriptData] writeToFile:sourcePath atomically:YES];
	}
	else {
		savePanel = [NSSavePanel savePanel];
		[savePanel beginSheetForDirectory:[sourcePath stringByDeletingLastPathComponent] file:[sourcePath lastPathComponent]  modalForWindow:[self windowForSheet] modalDelegate:self  didEndSelector:@selector(saveScriptSourceToFileDialogDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	}
}

- (void)saveScriptSourceToFileDialogDidEnd:(NSSavePanel *)savePanel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ScriptDocumentWillSaveNotification object:self];
		if ([[self scriptData] writeToFile:[savePanel filename] atomically:YES])
			[self setScriptSourceAlias:[NDAlias aliasWithPath:[savePanel filename]]];
	}
}

#pragma mark User Interface Validation

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(revertToExternalScriptSource:)) {
		return [[self scriptSourceAlias] path] != nil;
	}
	return [super validateMenuItem:anItem];
}

#pragma mark Misc Stuff

- (void)fixUpUndoAfterSave:(id)sender
{
	[self updateChangeCount:NSChangeCleared];
}


@end
