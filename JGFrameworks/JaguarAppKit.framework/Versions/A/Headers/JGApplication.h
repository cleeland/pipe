//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSApplication.h"

@interface JGApplication : NSApplication
{
}

- (void)finishLaunching;
- (void)performAutoUpdateCheck:(id)arg1;
- (void)openApplicationWebSite:(id)arg1;
- (void)sendApplicationFeedback:(id)arg1;
- (void)showApplicationPreferences:(id)arg1;
- (BOOL)validateMenuItem:(id)arg1;
- (void)softwareUpdateChecker:(id)arg1 didDownloadUpdateInfo:(id)arg2;
- (void)softwareUpdateChecker:(id)arg1 didFailWithError:(id)arg2;

@end

