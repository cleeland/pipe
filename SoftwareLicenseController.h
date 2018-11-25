//
//  SoftwareLicenseController.h
//  PipeIt
//
//  Created by René Puls on 04.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

/* License key structure:

1-F1D4-2F92-E986-86FC
^ ^^^^^^^^^ ^^^^^^^^^
| |         +---- HMAC of random data
| +-- random data
|
+-- key version

*/

#import <Cocoa/Cocoa.h>

#undef LICENSE_KEY_GENERATION

@interface SoftwareLicenseController : NSObject {
	NSData *productKey;
	NSString *licenseKey;
	NSDate *firstLaunchDate;
	NSTimeInterval allowedTrialPeriod;
	BOOL warningFlag;
}
+ (id)sharedController;
#ifdef LICENSE_KEY_GENERATION
- (NSDictionary *)generateKeyComponents;
- (NSString *)encodeKeyComponents:(NSDictionary *)keyComponents;
#endif
- (NSDictionary *)componentsOfKey:(NSString *)key;
- (BOOL)verifyKeyComponents:(NSDictionary *)keyComponents;
- (BOOL)verifyKey:(NSString *)key;
- (BOOL)softwareIsLicensed;
- (BOOL)softwareIsTrialVersion;
- (NSData *)productKey;
- (void)setProductKey:(NSData *)newKey;
- (NSString *)licenseKey;
- (void)setLicenseKey:(NSString *)newKey;
- (NSDate *)firstLaunchDate;
- (void)setFirstLaunchDate:(NSDate *)newDate;
- (NSData *)installationSignature;
- (NSTimeInterval)remainingTrialPeriod;
- (NSTimeInterval)allowedTrialPeriod;
- (void)setAllowedTrialPeriod:(NSTimeInterval)period;
- (BOOL)warningFlag;
- (void)setWarningFlag:(BOOL)flag;
- (NSData *)installationInfo;
- (BOOL)loadInstallationInfo:(NSData *)info;
@end
