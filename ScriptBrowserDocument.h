//
//  ScriptBrowserDocument.h
//  Pipe
//
//  Created by René Puls on 14.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>

#import "ScriptDocument.h"

@class ScriptBrowserController;

/*! A ScriptBrowserDocument is a special ScriptDocument subclass which can "mutate" into different scripts by opening them and taking on their attributes (except input and output). It is used to implement a script browser which allows the user to quickly switch between multiple scripts while keeping the same input. */

@interface ScriptBrowserDocument : ScriptDocument {
@private
	NDAlias *lastScriptAlias;
	NSDate *lastModificationDate;
	ScriptBrowserController *browserWindowController;
}

/*! Returns the shared script browser document instance (there is usually only one per application). */
+ (id)sharedDocument;

/*! Returns an alias to the most recently loaded script. */
- (NDAlias *)lastScriptAlias;

/*! Makes newAlias the alias to the most recently loaded script. This is automatically called by the loadScript: method. */
- (void)setLastScriptAlias:(NDAlias *)newAlias;

/*! Returns the last modification date of the most recently loaded script. */
- (NSDate *)lastModificationDate;

/*! Opens the most recently loaded script in a separate editor. */
- (IBAction)openScriptInEditor:(id)sender;
- (IBAction)openLoadedScript:(id)sender; // DEPRECATED, use openScriptInEditor:

/*! Loads scriptDocument by taking on most of its attributes, except input and output. */
- (void)loadScript:(ScriptDocument *)scriptDocument;

@end
