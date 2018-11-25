//
//  GeneralPreferencePane.m
//  Pipe
//
//  Created by René Puls on 12.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "GeneralPreferencePane.h"
#import "EncodingManager.h"
#import "UserDefaults.h"

@implementation GeneralPreferencePane

- (NSString *)title
{
	return NSLocalizedString(@"General", @"Preferences panel (TOOL)");
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"General Preferences"];
}

- (void)contentViewDidLoad
{
	[[EncodingManager sharedInstance] setupPopUp:encodingPopUpButton selectedEncoding:[JGUserDefaultValue(PipeTextEncodingDefaultKey) unsignedIntValue] withDefaultEntry:NO]; 
}

@end
