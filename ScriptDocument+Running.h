//
//  ScriptDocument+Running.h
//  Pipe
//
//  Created by René Puls on 09.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptDocument.h"

@class ScriptSession;

// Running Scripts

/*! This category adds the code required for executing scripts. */

@interface ScriptDocument (Running)

/*! Returns the default environment used for launching new scripts. */
- (NSDictionary *)environment;

/*! Returns a prepared script session using the specified variables. */
- (ScriptSession *)preparedScriptSessionWithVariables:(NSArray *)variables;

/*! Returns the preferred file name to be used when writing the script to a file for running. */
- (NSString *)scriptFileName;

/*! Returns the preferred file attributes to be used when writing the script to a file for running. */
- (NSDictionary *)scriptFileAttributes;

/*! Runs the current script, stopping the currently running script first if necessary. */
- (IBAction)runScript:(id)sender;

/*! Runs the current script if auto-run is enabled, otherwise does nothing. */
- (IBAction)autoRunScript:(id)sender;

/*! Stops the current script. If no script is currently running, this method does nothing. */
- (IBAction)stopScript:(id)sender;

@end
