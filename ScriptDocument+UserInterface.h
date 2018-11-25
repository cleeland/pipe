//
//  ScriptDocument+UserInterface.h
//  Pipe
//
//  Created by René Puls on 14.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptDocument.h"

/*! This category contains user interface actions common to both the ScriptEditorDocument and ScriptBrowserDocument classes. */

@interface ScriptDocument (UserInterface)

/*! Opens the home page for the current script. */
- (IBAction)openScriptHomePage:(id)sender;

/*! Saves the current script output to a file. */
- (IBAction)saveOutputToFile:(id)sender;

/*! Switches the output type of the current script from sender's tag (which should be one of the ScriptOutputType enumeration constants. */
- (IBAction)switchOutputType:(id)sender;

/*! Takes the current output as input. */
- (IBAction)takeInputFromOutput:(id)sender;

/*! Toggles reverse transformation mode. */
- (IBAction)toggleReverseTransformation:(id)sender;

@end
