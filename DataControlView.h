//
//  DataControlView.h
//  DataViewTest
//
//  Created by René Puls on 27.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataView.h"

enum DataViewContentType;

@interface DataControlView : NSView {
	DataView *dataView;
	NSSegmentedControl *typeSegmentedControl;
}
+ (float)defaultHeight;
- (id)initWithFrame:(NSRect)aFrame dataView:(DataView *)superView;
- (void)setSelectedContentType:(DataViewContentType)newType;
@end
