//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <JaguarAppKit/ODBEditor.h>

@interface ODBEditor (Private)
- (BOOL)_launchExternalEditor;
- (id)_tempFileForEditingString:(id)arg1 extensionHint:(id)arg2;
- (BOOL)_editFile:(id)arg1 isEditingString:(BOOL)arg2 options:(id)arg3 forClient:(id)arg4 context:(id)arg5;
- (void)handleModifiedFileEvent:(id)arg1 withReplyEvent:(id)arg2;
- (void)handleClosedFileEvent:(id)arg1 withReplyEvent:(id)arg2;
@end
