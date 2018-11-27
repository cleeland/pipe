//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <JaguarFoundation/JGFrameSet.h>

@interface JGMutableStackedFrameSet : JGFrameSet
{
    float framePadding;
    int stackingDirection;
}

- (id)initWithStackingDirection:(int)arg1 padding:(float)arg2;
- (float)framePadding;
- (void)setFramePadding:(float)arg1;
- (int)stackingDirection;
- (void)setStackingDirection:(int)arg1;
- (void)shiftFramesStartingAtIndex:(unsigned int)arg1 by:(float)arg2;
- (void)setSize:(struct _NSSize)arg1 forFrameAtIndex:(unsigned int)arg2;
- (void)insertFrameOfSize:(struct _NSSize)arg1 atIndex:(unsigned int)arg2 userInfo:(void *)arg3 isObject:(BOOL)arg4;
- (void)insertFrameOfSize:(struct _NSSize)arg1 atIndex:(unsigned int)arg2;
- (void)insertFrameOfSize:(struct _NSSize)arg1 atIndex:(unsigned int)arg2 userInfo:(void *)arg3;
- (void)insertFrameOfSize:(struct _NSSize)arg1 atIndex:(unsigned int)arg2 userObject:(id)arg3;
- (void)removeFrameAtIndex:(unsigned int)arg1;
- (id)description;
- (struct _NSRect)enclosingFrame;

@end

