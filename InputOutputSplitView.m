//
//  InputOutputSplitView.m
//  PipeIt
//
//  Created by René Puls on 03.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "InputOutputSplitView.h"

@implementation InputOutputSplitView

- (float)dividerThickness
{
	return 14.0;
}

- (void)drawDividerInRect:(NSRect)aRect
{
	NSRect leftRect, rightRect;
	NSDictionary *labelAttributes;
	NSMutableParagraphStyle *paragraphStyle;
	
	NSDivideRect(aRect, &leftRect, &rightRect, NSWidth(aRect)/2.0, NSMinXEdge);
	
	[super drawDividerInRect:aRect];
	
	paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	labelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont labelFontOfSize:0], NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
		paragraphStyle, NSParagraphStyleAttributeName,
		nil];
	[paragraphStyle release];
	[NSLocalizedString(@"<up arrow> Input", @"Text on the split divider between input and output text fields") drawInRect:leftRect withAttributes:labelAttributes];
	[NSLocalizedString(@"Output <down arrow>", @"Text on the split divider between input and output text fields") drawInRect:rightRect withAttributes:labelAttributes];
}

@end
