//
//  RunningPreferencePane.m
//  Pipe
//
//  Created by René Puls on 12.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "RunningPreferencePane.h"


@implementation RunningPreferencePane

- (NSString *)title
{
	return NSLocalizedString(@"Running", @"Preferences panel (TOOL)");
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Run Button"];
}

@end
