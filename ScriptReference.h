//
//  ScriptReference.h
//  PipeIt
//
//  Created by René Puls on 18.01.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>
#import "ScriptEditorDocument.h"

@interface ScriptReference : NSObject <NSCoding, NSCopying> {
	NDAlias *alias;
	NSString *name;
	ScriptOutputType outputType;
	NSDictionary *cachedPropertyList;
	BOOL serviceCapable;
	NSDate *lastModificationDate;
}
- (id)initWithPath:(NSString *)aPath;
- (void)updateFromPath:(NSString *)path;
- (void)updateFromDocument:(ScriptEditorDocument *)aDocument;
- (void)updateFromPropertyList:(NSDictionary *)propertyList;
- (NSString *)path;
- (NSString *)name;
- (NSDictionary *)cachedPropertyList;
- (void)setCachedPropertyList:(NSDictionary *)newPropertyList;
- (NSImage *)icon;
- (ScriptOutputType)outputType;
- (BOOL)isServiceCapable;
- (NSDate *)lastModificationDate;
- (void)setLastModificationDate:(NSDate *)newDate;
- (void)checkForUpdate;
@end
