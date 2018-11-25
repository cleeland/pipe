//
//  ScriptEditorDocument.h
//  Pipe
//
//  Created by René Puls on 14.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>

#import "ScriptDocument.h"

// Pipe Script document type names

/*! Document type representing a script bundle (containing an Info.plist, as well as files for input, output, script source, and usage information). */
extern NSString * const PipeScriptDocumentType;

/*! Document type representing a flat script file, which is a specially encoded version of a normal script bundle using NSFileWrapper's serializedRepresentation. */
extern NSString * const PipeScriptFlatDocumentType;

/*! Document type representing a "bare" script source file. This type can only be used as a "template" type for opening new scripts based on some external source code file. */
extern NSString * const PipeShellScriptDocumentType;

// Property list keys used in Pipe Script bundles

/*! Property list key containing the argument string to be used for a script. */
extern NSString * const PipeScriptArgumentStringPlistKey;

/*! Property list key containing the NSStringEncoding used for a script's source code. */
extern NSString * const PipeScriptCodeStringEncodingPlistKey;

/*! Property list key containing the saved properties of a script's editor window. */
extern NSString * const PipeScriptEditorWindowPropertiesPlistKey;

/*! Property list key (boolean) defining whether a script should be executed directly or with a run command. */
extern NSString * const PipeScriptExecutesDirectlyPlistKey;

/*! Property list key containing the home page URL of a script (as a string). */
extern NSString * const PipeScriptHomeURLPlistKey;

/*! Property list key containing the NSStringEncoding used for a script's input. */
extern NSString * const PipeScriptInputStringEncodingPlistKey;

/*! Property list key containing the date when a script was last saved. */
extern NSString * const PipeScriptLastSavedPlistKey;

/*! Property list key containing the string encoding used for a script's output. */
extern NSString * const PipeScriptOutputStringEncodingPlistKey;

/*! Property list key containing the output type of a script (as a ScriptOutputType enumeration constant). */
extern NSString * const PipeScriptOutputTypePlistKey;

/*! Property list key containing the file name that should be used when running a script. */
extern NSString * const PipeScriptPreferredFileNameKey;

/*! Property list key containing the run command used for a script. */
extern NSString * const PipeScriptRunCommandPlistKey;

/*! Property list key containing a boolean defining wheter a script can be run as a system service. */
extern NSString * const PipeScriptServiceCapablePlistKey;

/*! Property list key containing alias data to its original source code file. */
extern NSString * const PipeScriptSourceAliasPlistKey;

/*! Property list key containing information about a script's variables. */
extern NSString * const PipeScriptVariablesPlistKey;

/*! Property list key containing the file format version number of a script bundle. */
extern NSString * const PipeScriptVersionPlistKey;

/*! Property list key describing the writing direction of a script's input. */
extern NSString * const PipeScriptInputWritingDirectionPlistKey;

/*! Property list key describing the writing direction of a script's output. */
extern NSString * const PipeScriptOutputWritingDirectionPlistKey;

// Notifications

/*! Notification posted when the document has loaded a property list from a file. Observers should read the dictionary contained in the userInfo key @"propertyList" and apply it to their state where appropriate. */
extern NSString * const ScriptEditorDocumentApplySavedPropertyListNotification;

/*! Notification posted when the document wants to collect a property list for saving. The userInfo contains an NSMutableDictionary for the key @"propertyList". Observers may add their own property list data to this dictionary. */
extern NSString * const ScriptEditorDocumentCollectSavedPropertyListNotification;

@class ScriptReference, ScriptWindowController;

/*! A ScriptEditorDocument represents an actual script that can be edited by the user, as well as opened from and saved to disk in various formats. */

@interface ScriptEditorDocument : ScriptDocument {
	BOOL didMakeWindowControllers;
	NSDictionary *lastLoadedPropertyList;
	NDAlias *scriptSourceAlias;
}

/*! Creates a new document by loading the contents of aPath as a template. After loading, the fileName of this document is set to nil, so it is treated as a new document. */
- (id)initWithTemplatePath:(NSString *)aPath;

/*! An alias to the script source file used to create the receiver. */
- (NDAlias *)scriptSourceAlias;
- (void)setScriptSourceAlias:(NDAlias *)newAlias;

/*! Saves the receiver as a new template by opening a new save panel at the default template directory. */
- (IBAction)saveDocumentAsTemplate:(id)sender;

/*! Reverts the receiver's script source back to the contents of scriptSourceAlias. */
- (IBAction)revertToExternalScriptSource:(id)sender;

/*! Returns a property list describing various attributes of the document. This is used as the content for the Info.plist when saving to a script bundle. */
- (NSDictionary *)propertyList;

/*! The last property list that was read from disk. */
- (NSDictionary *)lastLoadedPropertyList;
- (void)setLastLoadedPropertyList:(NSDictionary *)newPropertyList;

@end
