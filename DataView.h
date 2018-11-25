//
//  DataView.h
//  Pipe
//
//  Created by René Puls on 27.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const DataViewDidChangeContentViewNotification;

typedef enum {
	DataViewDefaultContentType = 0,
	DataViewTextContentType = 1,
	DataViewImageContentType = 2,
	DataViewWebContentType = 3
} DataViewContentType;

@class DataControlView;

@interface DataView : NSView {
	id delegate;
	DataViewContentType contentType;
	NSView *contentView;
	DataControlView *controlView;
	NSData *data;
	NSStringEncoding dataStringEncoding;
	NSWritingDirection baseWritingDirection;
	BOOL isEditable;
	BOOL isControlViewVisible;
}
- (id)delegate;
- (void)setDelegate:(id)newDelegate;
- (DataControlView *)controlView;
- (BOOL)isControlViewVisible;
- (void)setControlViewVisible:(BOOL)flag;
- (NSData *)data;
- (void)setData:(NSData *)newData;
- (NSStringEncoding)dataStringEncoding;
- (void)setDataStringEncoding:(NSStringEncoding)newStringEncoding;
- (NSWritingDirection)baseWritingDirection;
- (void)setBaseWritingDirection:(NSWritingDirection)newDirection;
- (BOOL)isEditable;
- (void)setEditable:(BOOL)flag;
- (DataViewContentType)contentType;
- (void)setContentType:(DataViewContentType)newType;
- (id)contentView;
- (void)setContentView:(id)newView;
- (NSRect)contentFrame;
- (id)preparedContentViewForType:(DataViewContentType)aType;
- (void)updateContentView;
- (void)tile;
@end

@interface NSObject (DataViewDelegate)
- (void)dataViewDidChangeContentView:(NSNotification *)aNotification;
@end
