//
//  ScriptDocumentError.h
//  Pipe
//
//  Created by René Puls on 12.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>

JGDeclareStringName(ScriptDocumentErrorDomain)

enum {
	ScriptDocumentNotABundleError,
	ScriptDocumentIncompleteError, // with "missingFileName" key
	ScriptDocumentBadInfoPlistError, // with "errorString" key
	ScriptDocumentBadEncodingError // with "fileName", "expectedEncoding" keys
};

@interface ScriptDocumentError : NSError {
}
+ (id)errorWithCode:(int)code userInfo:(NSDictionary *)dict;
@end
