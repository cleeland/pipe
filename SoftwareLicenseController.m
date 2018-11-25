//
//  SoftwareLicenseController.m
//  PipeIt
//
//  Created by René Puls on 04.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "SoftwareLicenseController.h"
#import <JaguarFoundation/JaguarFoundation.h>

static int const KeyBlockLength __attribute__((unused)) = 2;
static int const KeyBlockCount = 2;

static int const SignatureBlockLength = 2;
static int const SignatureBlockCount = 2;

@implementation SoftwareLicenseController

+ (void)initialize
{
}

+ (id)sharedController
{
	static id sharedInstance = nil;
	
	if (sharedInstance == nil)
		sharedInstance = [[self alloc] init];
	return sharedInstance;
}

- (id)init
{
	if ((self = [super init])) {
		[self setFirstLaunchDate:[NSDate date]];
	}
	return self;
}

- (void)dealloc
{
	[firstLaunchDate release];
    [productKey release];
	[licenseKey release];
    [super dealloc];
}

#pragma mark Licenses

#ifdef LICENSE_KEY_GENERATION

- (NSDictionary *)generateKeyComponents
{
	NSData *keyData, *signatureData;
	
	keyData = [NSData randomDataOfLength:(KeyBlockLength * KeyBlockCount)];
	signatureData = [[keyData SHA1MACWithKeyData:[self productKey]] subdataWithRange:NSMakeRange(0, (SignatureBlockLength * SignatureBlockCount))];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:1], @"keyVersion",
		keyData, @"keyData",
		signatureData, @"signatureData",
		nil];
}

- (NSString *)encodeKeyComponents:(NSDictionary *)keyComponents
{
	int keyVersion;
	NSData *keyData, *signatureData;
	NSMutableString *keyString = [NSMutableString string];

	NSParameterAssert(keyComponents != nil);
	
	keyVersion = [[keyComponents objectForKey:@"keyVersion"] intValue];
	keyData = [keyComponents objectForKey:@"keyData"];
	signatureData = [keyComponents objectForKey:@"signatureData"];
	
	[keyString appendFormat:@"%d", keyVersion];
	
	for (int blockNum = 0; blockNum < KeyBlockCount; blockNum++) {
		[keyString appendString:@"-"];
		[keyString appendString:[[keyData subdataWithRange:NSMakeRange(blockNum*KeyBlockLength, KeyBlockLength)] hexString]];
	}

	for (int blockNum = 0; blockNum < SignatureBlockCount; blockNum++) {
		[keyString appendString:@"-"];
		[keyString appendString:[[signatureData subdataWithRange:NSMakeRange(blockNum*SignatureBlockLength, SignatureBlockLength)] hexString]];
	}
	
	return keyString;
}

#endif

- (NSDictionary *)componentsOfKey:(NSString *)key
{
	NSScanner *keyScanner;
	NSCharacterSet *hexCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789AaBbCcDdEeFf"];
	int keyVersion;
	NSString *part;
	NSMutableString *keyData = [NSMutableString string];
	NSMutableString *signatureData = [NSMutableString string];
	NSMutableDictionary *keyDict = [NSMutableDictionary dictionary];
	
	NSParameterAssert(key != nil);
	
	keyScanner = [NSScanner scannerWithString:key];

	// Read the key version
	if (![keyScanner scanInt:&keyVersion])
		return nil;
	[keyDict setObject:[NSNumber numberWithInt:keyVersion] forKey:@"keyVersion"];

	if (keyVersion == 1) {
		// Read key data
		for (int i=0; i<KeyBlockCount; i++) {
			if (![keyScanner scanString:@"-" intoString:NULL])
				return nil;
			if (![keyScanner scanCharactersFromSet:hexCharacterSet intoString:&part])
				return nil;
			[keyData appendString:part];
		}
		[keyDict setObject:[NSData dataWithHexString:keyData] forKey:@"keyData"];

		// Read signature data
		for (int i=0; i<SignatureBlockCount; i++) {
			if (![keyScanner scanString:@"-" intoString:NULL])
				return nil;
			if (![keyScanner scanCharactersFromSet:hexCharacterSet intoString:&part])
				return nil;
			[signatureData appendString:part];
		}
		[keyDict setObject:[NSData dataWithHexString:signatureData] forKey:@"signatureData"];
	}
	
	return keyDict;
}

- (BOOL)verifyKeyComponents:(NSDictionary *)keyComponents
{
	NSParameterAssert(keyComponents != nil);
	NSData *computedSignature;
	
	if ([[keyComponents objectForKey:@"keyVersion"] intValue] != 1)
		return NO;
	
	computedSignature = [[[keyComponents objectForKey:@"keyData"] SHA1MACWithKeyData:[self productKey]] subdataWithRange:NSMakeRange(0, (SignatureBlockLength * SignatureBlockCount))];
	return [[keyComponents objectForKey:@"signatureData"] isEqualToData:computedSignature];
}

- (BOOL)verifyKey:(NSString *)key
{
	NSDictionary *components;
	
	if (key == nil)
		return NO;
	
	components = [self componentsOfKey:key];
	if (components != nil)
		return [self verifyKeyComponents:components];
	else
		return NO;
}

- (BOOL)softwareIsLicensed
{
	if ([self remainingTrialPeriod] > [self allowedTrialPeriod])
		return NO;

	return ([self remainingTrialPeriod] > 0) || [self verifyKey:[self licenseKey]];
}

- (BOOL)softwareIsTrialVersion
{
	return ![self verifyKey:[self licenseKey]];
}

- (NSTimeInterval)remainingTrialPeriod
{
	NSDate *endDate;
	float remainingPeriod;
	
	endDate = [[self firstLaunchDate] addTimeInterval:[self allowedTrialPeriod]];
	remainingPeriod = [endDate timeIntervalSinceDate:[NSDate date]];
	
	if (remainingPeriod > [self allowedTrialPeriod])
		remainingPeriod = 0;

	return remainingPeriod;
}

#pragma mark Accessors

- (NSData *)productKey
{
    return productKey; 
}

- (void)setProductKey:(NSData *)newKey
{
	if (newKey != productKey) {
		[productKey release];
		productKey = [newKey copy];
	}
}

- (NSString *)licenseKey
{
	return licenseKey;
}

- (void)setLicenseKey:(NSString *)newKey
{
	if (licenseKey != newKey) {
		[licenseKey release];
		licenseKey = [newKey copy];
	}
}

- (NSDate *)firstLaunchDate
{
	return firstLaunchDate;
}

- (void)setFirstLaunchDate:(NSDate *)newDate
{
	if (newDate != firstLaunchDate) {
		[firstLaunchDate release];
		firstLaunchDate = [newDate copy];
	}
}

- (NSData *)installationSignature
{
	NSData *installationData;
	
	NSAssert([self firstLaunchDate] != nil, @"First launch date not set");
	
	installationData = [[NSString stringWithFormat:@"%.0f", [[self firstLaunchDate] timeIntervalSince1970]] dataUsingEncoding:NSUTF8StringEncoding];
	return [installationData SHA1MACWithKeyData:[self productKey]];
}

- (NSTimeInterval)allowedTrialPeriod
{
	return allowedTrialPeriod;
}

- (void)setAllowedTrialPeriod:(NSTimeInterval)period
{
	allowedTrialPeriod = period;
}

- (BOOL)warningFlag
{
	return warningFlag;
}

- (void)setWarningFlag:(BOOL)flag
{
	warningFlag = flag;
}

- (NSData *)installationInfo
{
	NSMutableDictionary *installInfo = [NSMutableDictionary dictionary];
	NSDictionary *installInfoPackage;
	NSData *installInfoData, *installInfoSignature;
	
	// Generate the information property list
	[installInfo setObject:[self firstLaunchDate] forKey:@"firstLaunchDate"];
	[installInfo setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"lastLaunchVersion"];
	
	// Serialize the property list
	installInfoData = [NSPropertyListSerialization dataFromPropertyList:installInfo format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	
	// Sign the serialized data
	installInfoSignature = [installInfoData SHA1MACWithKeyData:[self productKey]];
	
	// Pack the property list data and signature into a dictionary for archiving
	installInfoPackage = [NSDictionary dictionaryWithObjectsAndKeys:
		installInfoData, @"data",
		installInfoSignature, @"signature",
		[NSNumber numberWithInt:1], @"version",
		nil];
	
	return [NSArchiver archivedDataWithRootObject:installInfoPackage];
}

- (BOOL)loadInstallationInfo:(NSData *)info
{
	NSDictionary *infoPackage, *installInfo;
	NSData *installInfoData, *installInfoSignature;
	
	infoPackage = [NSUnarchiver unarchiveObjectWithData:info];
	if (infoPackage == nil)
		return NO;
	
	installInfoData = [infoPackage objectForKey:@"data"];
	installInfoSignature = [infoPackage objectForKey:@"signature"];
	
	if ([[installInfoData SHA1MACWithKeyData:[self productKey]] isEqualToData:installInfoSignature] == NO) {
		return NO;
	}
	
	installInfo = [NSPropertyListSerialization propertyListFromData:installInfoData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
	if (installInfo == nil)
		return NO;
	
	[self setFirstLaunchDate:[installInfo objectForKey:@"firstLaunchDate"]];

	return YES;
}

@end
