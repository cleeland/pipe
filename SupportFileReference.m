//
//  SupportFileReference.m
//  Pipe
//
//  Created by René Puls on 16.04.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SupportFileReference.h"

@implementation SupportFileReference

- (void)dealloc
{
	[sourceAlias release];
	[fileWrapper release];
	[icon release];
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init])) {
		sourceAlias = [[decoder decodeObjectForKey:@"sourceAlias"] retain];
		fileWrapper = [[decoder decodeObjectForKey:@"fileWrapper"] retain];
		icon = [[decoder decodeObjectForKey:@"icon"] retain];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	if (sourceAlias != nil)
		[encoder encodeObject:sourceAlias forKey:@"sourceAlias"];
	if (icon != nil)
		[encoder encodeObject:icon forKey:@"icon"];
	[encoder encodeObject:fileWrapper forKey:@"fileWrapper"];
}

- (NDAlias *)sourceAlias
{
	return sourceAlias;
}

- (void)setSourceAlias:(NDAlias *)newAlias
{
	if (newAlias != sourceAlias) {
		NSAssert([newAlias path] != nil, @"Failed to resolve alias");
		[sourceAlias release];
		sourceAlias = [newAlias retain];
		[sourceAlias setAllowUserInteraction:NO];
		[self setFileWrapper:[[[NSFileWrapper alloc] initWithPath:[newAlias path]] autorelease]];
		[self setIcon:[[NSWorkspace sharedWorkspace] iconForFile:[newAlias path]]];
	}
}

- (NSFileWrapper *)fileWrapper
{
	return fileWrapper;
}

- (void)setFileWrapper:(NSFileWrapper *)newWrapper
{
	if (newWrapper != fileWrapper) {
		[fileWrapper release];
		fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:[newWrapper serializedRepresentation]];
	}
}

- (BOOL)updateFromSource
{
	NSString *sourcePath;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	sourcePath = [sourceAlias path];
	if ((sourcePath != nil) && [fileManager fileExistsAtPath:sourcePath]) {
		if ([fileWrapper needsToBeUpdatedFromPath:sourcePath])
			[self setFileWrapper:[[[NSFileWrapper alloc] initWithPath:sourcePath] autorelease]];
		return YES;
	} else return NO;
}

- (NSImage *)icon
{
	return icon;
}

- (void)setIcon:(NSImage *)newIcon
{
	if (newIcon != icon) {
		[icon release];
		icon = [newIcon retain];
	}
}

@end
