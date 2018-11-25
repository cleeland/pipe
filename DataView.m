//
//  DataView.m
//  Pipe
//
//  Created by René Puls on 27.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "DataView.h"
#import "DataControlView.h"

#import <WebKit/WebKit.h>
#import <JaguarFoundation/JaguarFoundation.h>
#import <JaguarAppKit/JaguarAppKit.h>

#define NSAppKitVersionNumber10_3 743

NSString * const DataViewDidChangeContentViewNotification = @"DataViewDidChangeContentViewNotification";

@implementation DataView

#pragma mark Init and Cleanup

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
		controlView = [[DataControlView alloc] initWithFrame:[self frame] dataView:self];
		[controlView setAutoresizingMask:NSViewWidthSizable];
		[self addSubview:controlView];
		[self setControlViewVisible:NO];
		[self setContentType:DataViewTextContentType];
    }
    return self;
}

- (void)dealloc
{
	[controlView release];
	[self setDelegate:nil];
	[data release];
	[super dealloc];
}

#pragma mark Accessors

- (DataControlView *)controlView
{
	return controlView;
}

- (BOOL)isControlViewVisible
{
	return isControlViewVisible;
}

- (void)setControlViewVisible:(BOOL)flag
{
	isControlViewVisible = flag;
	[self tile];
}

- (NSData *)data
{
	return data;
}

- (void)setData:(NSData *)newData
{
	if (newData != data) {
		[data release];
		data = [newData copy];
		[self updateContentView];
	}
}

- (NSStringEncoding)dataStringEncoding
{
	return dataStringEncoding;
}

- (void)setDataStringEncoding:(NSStringEncoding)newStringEncoding
{
	if (newStringEncoding != dataStringEncoding) {
		dataStringEncoding = newStringEncoding;
		[self updateContentView];
	}
}

- (NSWritingDirection)baseWritingDirection
{
	return baseWritingDirection;
}

- (void)setBaseWritingDirection:(NSWritingDirection)newDirection
{
	if (newDirection != baseWritingDirection) {
		baseWritingDirection = newDirection;
		[self updateContentView];
	}
}

- (BOOL)isEditable
{
	return isEditable;
}

- (void)setEditable:(BOOL)flag
{
	isEditable = flag;
	[self updateContentView];
}

- (BOOL)isOpaque
{
	return NO;
}

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	if (newDelegate != delegate) {
	    // Deregister the old delegate
		if ([delegate respondsToSelector:@selector(dataViewDidChangeContentView:)]) {
			[[NSNotificationCenter defaultCenter] removeObserver:delegate name:DataViewDidChangeContentViewNotification object:self];
		}
		delegate = newDelegate;
		if ([delegate respondsToSelector:@selector(dataViewDidChangeContentView:)]) {
			[[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(dataViewDidChangeContentView:) name:DataViewDidChangeContentViewNotification object:self];
		}
	}
}

- (DataViewContentType)contentType
{
	return contentType;
}

- (void)setContentType:(DataViewContentType)newType
{
	if (newType != contentType) {
		contentType = newType;
		[self setContentView:[self preparedContentViewForType:contentType]];
		[controlView setSelectedContentType:newType];
	}
}

- (id)preparedContentViewForType:(DataViewContentType)aType
{
	id preparedView = nil, subView;
	
	switch (aType) {
		case DataViewWebContentType:
			preparedView = [[WebView alloc] initWithFrame:[self contentFrame]];
			[preparedView setPolicyDelegate:self];
			break;
		case DataViewImageContentType:
			preparedView = [[NSScrollView alloc] initWithFrame:[self contentFrame]];
			[preparedView setBorderType:NSBezelBorder];
			subView = [[NSImageView alloc] initWithFrame:[self contentFrame]];
			[subView setImageFrameStyle:NSImageFrameNone];
			[preparedView setDocumentView:subView];
			[subView release];
			[subView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
			break;
		case DataViewTextContentType:
		default:
			preparedView = [[JGExtendedTextView fullyConfiguredTextView] retain];
			[preparedView setFrame:[self contentFrame]];
			subView = [preparedView documentView];
			[subView setUsesFontPanel:NO];
			[subView setUsesFindPanel:YES];
			[subView setRichText:NO];
			[subView setUsesRuler:NO];
			break;
	}
	
	NSAssert(preparedView != nil, @"Failed to prepare content view");
	
	[preparedView setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
	return [preparedView autorelease];
}

- (NSRect)contentFrame
{
	return [self bounds];
}

- (id)contentView
{
	return contentView;
}

- (void)setContentView:(id)newView
{
	if (newView != contentView) {
		if ((contentView != nil) && (newView != nil))
			[self replaceSubview:contentView with:newView];
		else if (contentView == nil)
			[self addSubview:newView];
		else if (newView == nil)
			[contentView removeFromSuperview];
		
		contentView = newView;

		[self tile];

		[[NSNotificationCenter defaultCenter] postNotificationName:DataViewDidChangeContentViewNotification object:self];
		[self updateContentView];
	}
}

- (void)updateContentView
{
	JGExtendedTextView *textView;
	NSString *newString;
	NSImage *newImage;
	
	switch ([self contentType]) {
		case DataViewImageContentType:
			newImage = [[[NSImage alloc] initWithData:[self data]] autorelease];
			if (([self data] != nil) && (newImage == nil))
				newImage = [NSImage imageNamed:@"Bad Image Placeholder"];
			[[[self contentView] documentView] setImage:newImage];
			break;
		case DataViewWebContentType:
			[[[self contentView] mainFrame] loadData:[self data] MIMEType:@"text/html" textEncodingName:[NSString IANANameOfStringEncoding:[self dataStringEncoding]] baseURL:nil];
			break;
		case DataViewTextContentType:
		default:
			textView = [[self contentView] documentView];
			[textView setEditable:[self isEditable]];
			if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3) {
				[textView setBaseWritingDirection:[self baseWritingDirection]];
			}
			newString = [[[NSString alloc] initWithData:[self data] encoding:[self dataStringEncoding]] autorelease];
			if (newString == nil) {
				newString = [NSString stringByGuessingEncodingOfData:[self data]];
			}
			if ((newString == nil) && ([self data] != nil)) {
				newString = [NSString stringWithFormat:NSLocalizedString(@"(Cannot convert data to encoding %@.)", @"Placeholder text in data view (e.g. script output) when text could not be decoded."), [NSString localizedNameOfStringEncoding:[self dataStringEncoding]]];
			}
			[textView setString:(newString ? newString : @"")];
			break;
	}
}

#pragma mark User Interface Validation

- (BOOL)validateMenuItem:(id <NSMenuItem>)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(switchContentType:)) {
		[anItem setState:([anItem tag] == [self contentType])];
	}
	
	return YES;
}

#pragma mark Drawing and Geometry

- (BOOL)isFlipped
{
	return YES;
}

- (void)tile
{
	NSRect myRect, controlRect, contentRect;
	float controlViewHeight;
	
	controlViewHeight = NSHeight([[self controlView] frame]);
	
	myRect = [self bounds];
	NSDivideRect(myRect, &controlRect, &contentRect, ([self isControlViewVisible] ? controlViewHeight : 0), NSMinYEdge);
	
	[[self controlView] setFrame:controlRect];
	[[self contentView] setFrame:contentRect];
}

- (void)drawRect:(NSRect)rect 
{
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	[super drawRect:rect];
}

#pragma mark Web View Delegate

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
	if ([[[request URL] scheme] isEqualToString:@"about"] || [[[request URL] scheme]  isEqualToString:@"applewebdata"]) {
		[listener use];
	}
	else {
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
}

@end
