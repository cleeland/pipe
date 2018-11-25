//
//  SupportFileReference.h
//  Pipe
//
//  Created by René Puls on 16.04.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>
#import <JaguarFoundation/JaguarFoundation.h>

@interface SupportFileReference : NSObject <NSCoding> {
	NDAlias *sourceAlias;
	NSFileWrapper *fileWrapper;
	NSImage *icon;
}
- (NDAlias *)sourceAlias;
- (void)setSourceAlias:(NDAlias *)newAlias;
- (NSFileWrapper *)fileWrapper;
- (void)setFileWrapper:(NSFileWrapper *)newWrapper;
- (NSImage *)icon;
- (void)setIcon:(NSImage *)icon;
- (BOOL)updateFromSource;
@end
