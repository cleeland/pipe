//
//  DataControlView.h
//  DataViewTest
//
//  Created by Ren� Puls on 27.02.05.
//  Copyright 2005 Ren� Puls. All rights reserved.
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
