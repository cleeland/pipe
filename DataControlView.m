//
//  DataControlView.m
//  DataViewTest
//
//  Created by René Puls on 27.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "DataControlView.h"
#import "DataView.h"

@implementation DataControlView

#pragma mark Init and Cleanup

+ (float)defaultHeight
{
	return 28.0;
}

- (id)initWithFrame:(NSRect)aFrame dataView:(DataView *)myDataView
{
	NSRect myFrame;
	
	NSParameterAssert(myDataView != nil);
	
	myFrame = NSMakeRect(NSMinX(aFrame), NSMinY(aFrame), NSWidth(aFrame), [[self class] defaultHeight]);
    if ((self == [super initWithFrame:myFrame])) {
		dataView = myDataView;
		
		// Initialize the type selector
		typeSegmentedControl = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect];
		{
			NSSegmentedCell *segmentedCell = [typeSegmentedControl cell];
			NSString *segmentLabel;
			int segmentTag;
			NSRect segmentedFrame;
			int segmentCount = 3;
			
			// Set up appearance
			[segmentedCell setControlSize:NSSmallControlSize];
			[segmentedCell setFont:[NSFont controlContentFontOfSize:10.0]];
			
			// Set up segments
			[segmentedCell setSegmentCount:segmentCount];
			for (int currentSegment=0; currentSegment<segmentCount; currentSegment++) {
				switch (currentSegment) {
					case 0:
						segmentLabel = @"Text";
						segmentTag = DataViewTextContentType;
						break;
					case 1:
						segmentLabel = @"Image";
						segmentTag = DataViewImageContentType;
						break;
					case 2:
						segmentLabel = @"HTML";
						segmentTag = DataViewWebContentType;
						break;
					default:
						segmentLabel = nil;
						segmentTag = 0;
						NSAssert(FALSE, @"Unhandled content type");
						break;
				}
				[segmentedCell setLabel:segmentLabel forSegment:currentSegment];
				[segmentedCell setTag:segmentTag forSegment:currentSegment];
			}
			[typeSegmentedControl setSelectedSegment:0];
			[typeSegmentedControl sizeToFit];
			
			// Adjust the frame to make it right-aligned
			segmentedFrame = [typeSegmentedControl frame];
			segmentedFrame.origin.x = NSWidth(myFrame) - NSWidth(segmentedFrame) - 16;
			segmentedFrame.origin.y = NSHeight(myFrame) / 2 - NSHeight(segmentedFrame) / 2 - 1;
			[typeSegmentedControl setFrameOrigin:segmentedFrame.origin];
			[typeSegmentedControl setAutoresizingMask:NSViewMinXMargin];
			[typeSegmentedControl setTarget:self];
			[typeSegmentedControl setAction:@selector(switchContentType:)];
			
			[self addSubview:typeSegmentedControl];
			[typeSegmentedControl release];
		}
    }
    return self;
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark Drawing and Geometry

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *borderPath;
	
	[[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
	NSRectFill(rect);
	
	[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
	borderPath = [[NSBezierPath alloc] init];
	[borderPath moveToPoint:NSMakePoint(0,0)];
	[borderPath lineToPoint:NSMakePoint(NSWidth([self bounds]), 0)];
	[borderPath moveToPoint:NSMakePoint(0,NSHeight([self bounds])-1)];
	[borderPath lineToPoint:NSMakePoint(NSWidth([self bounds]), NSHeight([self bounds])-1)];
//	[borderPath stroke];
	[borderPath release];
}

#pragma mark Actions

- (void)setSelectedContentType:(DataViewContentType)newType
{
	int segmentNum = -1;
	
	switch (newType) {
		case DataViewTextContentType:
			segmentNum = 0;
			break;
		case DataViewImageContentType:
			segmentNum = 1;
			break;
		case DataViewWebContentType:
			segmentNum = 2;
			break;
		default:
			NSAssert(FALSE, @"Unhandled content type");
			break;
	}
	
	[typeSegmentedControl setSelectedSegment:segmentNum];
}

- (void)switchContentType:(id)sender
{
	int tag;
	
	tag = [[sender cell] tagForSegment:[sender selectedSegment]];
	[dataView setContentType:tag];
}

@end
