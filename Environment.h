/*
 *  Environment.h
 *  Pipe
 *
 *  Created by René Puls on 16.04.05.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

/*! Environment variable containing the expected output charset of a script as an IANA name. */
extern NSString * const PipeExpectedOutputCharsetEnvironmentKey;

/*! Environment variable containing the expected output type of a script (either text, image or html). */
extern NSString * const PipeExpectedOutputTypeEnvironmentKey;

/*! Environment variable containing the input charset of a script as an IANA name. */
extern NSString * const PipeInputCharsetEnvironmentKey;

/*! Environment variable which is set to "1" if Pipe is in Reverse Transformation mode. */
extern NSString * const PipeReverseTransformationEnvironmentKey;

/*! Environment variable containing the source code charset of a script as an IANA name. */
extern NSString * const PipeScriptCharsetEnvironmentKey;

/*! Environment variable containing the path to the script's own support directory. */
extern NSString * const PipeScriptSupportPathEnvironmentKey;

/*! Environment variable containing the bundle identifier of the application currently requesting this script as a service. */
extern NSString * const PipeServiceRequestingAppBundleIdentifierEnvironmentKey;

/*! Environment variable containing the bundle name of the application currently requesting this script as a service. */
extern NSString * const PipeServiceRequestingAppBundleNameEnvironmentKey;

/*! Environment variable containing the bundle path of the application currently requesting this script as a service. */
extern NSString * const PipeServiceRequestingAppBundlePathEnvironmentKey;

/*! Environment variable containing an opqaue string that uniquely identifies the current script session. */
extern NSString * const PipeSessionIDEnvironmentKey;

/*! Environment variable containing an opqaue string that contains information necessary to contact the session server for interaction with Pipe. */
extern NSString * const PipeSessionServerEnvironmentKey;

/*! Environment variable containing the path to the global script support directory of Pipe. */
extern NSString * const PipeSupportPathEnvironmentKey;

/*! Environment variable containing the current version of Pipe as an integer (e.g. 130 for version 1.3.0). */
extern NSString * const PipeVersionEnvironmentKey;

/*! Environment variable containing a temporary path for exclusive access by the script which will be cleaned up upon termination. */
extern NSString * const PipeTemporaryWorkPathEnvironmentKey;
