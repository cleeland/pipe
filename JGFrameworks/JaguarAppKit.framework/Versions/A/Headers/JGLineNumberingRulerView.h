//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSRulerView.h"

@interface JGLineNumberingRulerView : NSRulerView
{
}

+ (void)initialize;
- (id)initWithScrollView:(id)arg1;
- (void)dealloc;
- (struct _NSRect)lineNumberRectForDocumentLineRect:(struct _NSRect)arg1 visibleRect:(struct _NSRect)arg2;
- (void)drawHashMarksAndLabelsInRect:(struct _NSRect)arg1;
- (id)attributedStringForLineNumber:(unsigned int)arg1;
- (void)scrollPositionChanged:(id)arg1;
- (void)invalidateHashMarks;

@end
