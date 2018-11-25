//
//  KwikiController.h
//  PipeIt
//
//  Created by René Puls on 19.01.05.
//  Copyright 2005 René Puls. All rights reserved.
//

// A "kwiki" (registered trademark of Kiza) is a script referenced by the script browser.

#import <Cocoa/Cocoa.h>

#import "ScriptDocument.h"

@class ScriptReference;

@interface KwikiController : NSObject {
	NSMutableArray *kwikis;
	BOOL didLoadKwikiList;
	BOOL savesKwikiList;
}
+ (id)sharedController;
// Accessors
- (unsigned int)countOfKwikis;
- (ScriptReference *)objectInKwikisAtIndex:(unsigned int)index;
- (void)insertObject:(ScriptReference *)newScriptReference inKwikisAtIndex:(unsigned int)index;
- (void)removeObjectFromKwikisAtIndex:(unsigned int)index;
- (unsigned int)indexOfKwikiWithPath:(NSString *)fileName;
- (NSString *)kwikiListPath;
- (BOOL)savesKwikiList;
- (void)setSavesKwikiList:(BOOL)flag;
// Persistence
- (void)loadVersion10KwikiList:(id)sender;
- (void)loadKwikiList:(id)sender;
- (void)saveKwikiList:(id)sender;
@end

@interface ScriptDocument (ScriptReferences)
- (ScriptReference *)reference;
@end
