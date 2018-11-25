//
//  ScriptDocumentError.m
//  Pipe
//
//  Created by René Puls on 12.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptDocumentError.h"

JGDefineStringName(ScriptDocumentErrorDomain)

@implementation ScriptDocumentError

+ (id)errorWithCode:(int)code userInfo:(NSDictionary *)dict
{
	return [self errorWithDomain:ScriptDocumentErrorDomain code:code userInfo:dict];
}

- (NSString *)localizedDescription
{
	if ([[self domain] isEqualToString:ScriptDocumentErrorDomain]) {
		switch ([self code]) {
			case ScriptDocumentNotABundleError:
				return NSLocalizedString(@"Script should be a bundle, not a regular file.", @"Script loading failure (ERR)");
			case ScriptDocumentIncompleteError:
				return [NSString stringWithFormat:NSLocalizedString(@"Missing file '%@' in script bundle.", @"Script loading failure (ERR)"), [[self userInfo] objectForKey:@"missingFileName"]];
			case ScriptDocumentBadInfoPlistError:
				return [NSString stringWithFormat:NSLocalizedString(@"Malformed property list in script bundle: %@", @"Script loading failure (ERR)"), [[self userInfo] objectForKey:@"errorString"]];
			case ScriptDocumentBadEncodingError:
				if ([[self userInfo] objectForKey:@"fileName"])
					return [NSString stringWithFormat:NSLocalizedString(@"Text file '%@' in bundle has bad encoding -- expected %@", @"Script loading failure (ERR)"), [[self userInfo] objectForKey:@"fileName"], [NSString localizedNameOfStringEncoding:[[[self userInfo] objectForKey:@"expectedEncoding"] unsignedIntValue]]];
				else
					return [NSString stringWithFormat:NSLocalizedString(@"Script text file has bad encoding -- expected %@", @"Script loading failure (ERR)"), [NSString localizedNameOfStringEncoding:[[[self userInfo] objectForKey:@"expectedEncoding"] unsignedIntValue]]];
			default:
				return nil;
		}
	}
	else return [super localizedDescription];
}

@end
