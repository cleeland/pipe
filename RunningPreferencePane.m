//
//  RunningPreferencePane.m
//  Pipe
//
//  Created by Ren� Puls on 12.03.05.
//  Copyright 2005 Ren� Puls. All rights reserved.
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
