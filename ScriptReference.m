//
//  ScriptReference.m
//  PipeIt
//
//  Created by RenŽ Puls on 18.01.05.
//  Copyright 2005 RenŽ Puls. All rights reserved.
//

#import "ScriptReference.h"
#import "ScriptEditorDocument.h"

@implementation ScriptReference

+ (void)initialize
{
	[self setKeys:[NSArray arrayWithObject:@"outputType"] triggerChangeNotificationsForDependentKey:@"icon"];
	[self setKeys:[NSArray arrayWithObject:@"cachedPropertyList"] triggerChangeNotificationsForDependentKey:@"outputType"];
	[self setKeys:[NSArray arrayWithObject:@"cachedPropertyList"] triggerChangeNotificationsForDependentKey:@"serviceCapable"];
}

- (id)initWithPath:(NSString *)aPath
{
	NSParameterAssert(aPath != nil);
	
	if ((self = [super init])) {
		alias = [[NDAlias alloc] initWithPath:aPath];
		[self updateFromPath:aPath];
	}
	return self;
}

- (void)dealloc
{
	[alias release];
	[name release];
	[lastModificationDate release];
	[cachedPropertyList release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	ScriptReference *newReference = [[ScriptReference allocWithZone:zone] init];
	
	newReference->alias = [[NDAlias aliasWithData:[alias data]] retain];
	newReference->name = [name copyWithZone:zone];
	newReference->cachedPropertyList = [cachedPropertyList retain];
	newReference->outputType = outputType;
	newReference->serviceCapable = serviceCapable;
	return newReference;
}

- (void)updateFromPath:(NSString *)path
{
	NSString *docType;
	
	NSParameterAssert(path != nil);
	
	[self willChangeValueForKey:@"name"];
	[name release];
	name = [[[path lastPathComponent] stringByDeletingPathExtension] retain];
	[self didChangeValueForKey:@"name"];
	
	[self setLastModificationDate:[[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES] objectForKey:NSFileModificationDate]];
	
	docType = [[NSDocumentController sharedDocumentController] typeFromFileExtension:[path pathExtension]];
	if ([docType isEqualToString:PipeScriptDocumentType]) {
		NSBundle *scriptBundle;

		scriptBundle = [NSBundle bundleWithPath:path];
		[self setCachedPropertyList:[NSDictionary dictionaryWithContentsOfURL:[scriptBundle objectForInfoDictionaryKey:@"CFBundleInfoPlistURL"]]];
	}
	else if ([docType isEqualToString:PipeScriptFlatDocumentType]) {
		NSData *serializedData, *plistData;
		NSFileWrapper *docWrapper;
		id propertyList;
		
		serializedData = [NSData dataWithContentsOfFile:path];
		docWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:serializedData];
		plistData = [[[[[docWrapper fileWrappers] objectForKey:@"Contents"] fileWrappers] objectForKey:@"Info.plist"] regularFileContents];
		[docWrapper release];
		propertyList = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
		[self setCachedPropertyList:propertyList];
	}
}

- (void)updateFromPropertyList:(NSDictionary *)propertyList
{
	id property;
	
	outputType = [[propertyList objectForKey:PipeScriptOutputTypePlistKey] intValue];
	
	if ((property = [propertyList objectForKey:PipeScriptServiceCapablePlistKey]))
		serviceCapable = [property boolValue];
	else
		serviceCapable = YES;
}

- (void)updateFromDocument:(ScriptEditorDocument *)aDocument
{
	NSParameterAssert(aDocument != nil);
	
	[self setCachedPropertyList:[aDocument propertyList]];
	[self setLastModificationDate:[NSDate date]];
}

- (NSString *)path
{
	NSString *path;
	
	path = [alias path];
	if ([alias changed])
		[self updateFromPath:path];
	
	return path;
}

- (NSString *)name
{
	return name;
}

- (ScriptOutputType)outputType
{
	return outputType;
}

- (NSDictionary *)cachedPropertyList
{
	return cachedPropertyList;
}

- (void)setCachedPropertyList:(NSDictionary *)newPropertyList
{
	if (newPropertyList != cachedPropertyList) {
		[cachedPropertyList release];
		cachedPropertyList = [newPropertyList retain];
		[self updateFromPropertyList:newPropertyList];
	}
}

- (NSImage *)icon
{
	static NSImage *textIcon = nil;
	static NSImage *imageIcon = nil;
	static NSImage *htmlIcon = nil;
	
	if (textIcon == nil) {
		textIcon = [[NSImage imageNamed:@"Text Script Icon"] retain];
		[textIcon setSize:NSMakeSize(16,16)];
	}
	if (imageIcon == nil) {
		imageIcon = [[NSImage imageNamed:@"Image Script Icon"] retain];
		[imageIcon setSize:NSMakeSize(16,16)];
	}
	if (htmlIcon == nil) {
		htmlIcon = [[NSImage imageNamed:@"HTML Script Icon"] retain];
		[htmlIcon setSize:NSMakeSize(16,16)];
	}
	
	switch (outputType) {
		case ScriptImageOutputType:
			return imageIcon;
		case ScriptWebOutputType:
			return htmlIcon;
		case ScriptUnknownOutputType:
		case ScriptTextOutputType:
		default:
			return textIcon;
	}
}

- (BOOL)isServiceCapable
{
	return serviceCapable;
}

- (NSDate *)lastModificationDate
{
    return lastModificationDate; 
}

- (void)setLastModificationDate:(NSDate *)newLastModificationDate
{
    if (lastModificationDate != newLastModificationDate) {
        [lastModificationDate release];
        lastModificationDate = [newLastModificationDate copy];
    }
}

- (void)checkForUpdate
{
	[self path];
}

#pragma mark Coding

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:alias forKey:@"alias"];
	[encoder encodeObject:name forKey:@"name"];
	[encoder encodeObject:cachedPropertyList forKey:@"cachedPropertyList"];
}

- (id)initWithCoder:(NSCoder *)encoder
{
	if ((self = [super init])) {
		alias = [[encoder decodeObjectForKey:@"alias"] retain];
		name = [[encoder decodeObjectForKey:@"name"] retain];
		cachedPropertyList = [[encoder decodeObjectForKey:@"cachedPropertyList"] retain];
		if (cachedPropertyList != nil) {
			[self updateFromPropertyList:cachedPropertyList];
		}
		else {
			outputType = [encoder decodeIntForKey:@"outputType"];
		}
	}
	return self;
}

@end
