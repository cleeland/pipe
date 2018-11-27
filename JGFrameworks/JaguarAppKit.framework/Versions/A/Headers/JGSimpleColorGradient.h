//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

@interface JGSimpleColorGradient : NSObject
{
    struct CGShading *shading;
    struct CGColorSpace *colorSpace;
    struct CGFunction *function;
}

+ (id)horizontalGradientWithStartColor:(id)arg1 endColor:(id)arg2 inRect:(struct _NSRect)arg3 reverse:(BOOL)arg4;
+ (id)verticalGradientWithStartColor:(id)arg1 endColor:(id)arg2 inRect:(struct _NSRect)arg3 reverse:(BOOL)arg4;
- (id)initAxialWithStartColor:(id)arg1 startPoint:(struct _NSPoint)arg2 extendStart:(BOOL)arg3 endColor:(id)arg4 endPoint:(struct _NSPoint)arg5 extendEnd:(BOOL)arg6;
- (id)initRadialWithStartColor:(id)arg1 startPoint:(struct _NSPoint)arg2 startRadius:(float)arg3 extendStart:(BOOL)arg4 endColor:(id)arg5 endPoint:(struct _NSPoint)arg6 endRadius:(float)arg7 extendEnd:(BOOL)arg8;
- (void)fill;
- (void)dealloc;

@end

