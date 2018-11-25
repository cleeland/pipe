//
//  ServicesController.h
//  Pipe
//
//  Created by René Puls on 11.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ServicesController : NSObject {
	NSMutableDictionary *currentServiceRequest;
}
+ (id)sharedController;
- (NSDictionary *)currentServiceRequest;
- (void)beginServiceRequestAndBringToFront:(BOOL)flag;
- (void)endServiceRequestRestoringLastFrontApp:(BOOL)flag;
- (void)pipeThroughScript:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
- (void)useAsInput:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
- (void)presentEmptyScriptBrowserAlert;
- (void)presentNoServicesScriptBrowserAlert;
@end
