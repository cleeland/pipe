//
//  KwikiController.m
//  PipeIt
//
//  Created by René Puls on 19.01.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "KwikiController.h"
#import "ScriptReference.h"
#import "SoftwareLicenseController.h"
#import "AppController.h"

@implementation KwikiController

static KwikiController *SharedInstance = nil;

#pragma mark Init and Cleanup

+ (id)sharedController
{
	if (SharedInstance == nil)
		SharedInstance = [[self alloc] init];
	return SharedInstance;
}

- (id)init
{
	if (SharedInstance != nil) {
		[self release];
		return SharedInstance;
	}
	
	if ((self = [super init])) {
		kwikis = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveKwikiList:) name:NSApplicationWillTerminateNotification object:NSApp];
		SharedInstance = self;
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[kwikis release];
	[super dealloc];
}

#pragma mark Accessors

- (unsigned int)countOfKwikis 
{
	NSAssert(didLoadKwikiList, @"Script browser list not loaded yet!");
    return [kwikis count];
}

- (ScriptReference *)objectInKwikisAtIndex:(unsigned int)anIndex 
{
	NSAssert(didLoadKwikiList, @"Script browser list not loaded yet!");
    return [kwikis objectAtIndex:anIndex];
}

- (void)insertObject:(ScriptReference *)newScriptReference inKwikisAtIndex:(unsigned int)anIndex 
{
	NSAssert(didLoadKwikiList, @"Script browser list not loaded yet!");
    [kwikis insertObject:newScriptReference atIndex:anIndex];
}

- (void)removeObjectFromKwikisAtIndex:(unsigned int)anIndex 
{
	NSAssert(didLoadKwikiList, @"Script browser list not loaded yet!");
    [kwikis removeObjectAtIndex:anIndex];
}

- (unsigned int)indexOfKwikiWithPath:(NSString *)fileName
{
	NSEnumerator *kwikiEnumerator;
	ScriptReference *currentKwiki;
	unsigned int currentIndex = 0;
	
	kwikiEnumerator = [[self valueForKey:@"kwikis"] objectEnumerator];
	while ((currentKwiki = [kwikiEnumerator nextObject])) {
		if ([[currentKwiki path] isEqualToString:fileName])
			return currentIndex;
		currentIndex++;
	}
	return NSNotFound;
}

- (NSString *)version10KwikiListPath
{
	return [NSString stringWithFormat:@"%@/Library/Application Support/%@/ScriptBrowserReferences.keyedarchive", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]];
}

- (NSString *)kwikiListPath
{
	return [NSString stringWithFormat:@"%@/Library/Application Support/%@/ScriptBrowserData", NSHomeDirectory(), [[NSProcessInfo processInfo] processName]];
}

- (BOOL)savesKwikiList
{
	return savesKwikiList;
}

- (void)setSavesKwikiList:(BOOL)flag
{
	savesKwikiList = flag;
}

#pragma mark Persistence

- (void)loadKwikiList:(id)sender
{
	NSData *archivedData, *savedInstallationSignature, *savedInstallationInfo;
	NSKeyedUnarchiver *unarchiver;
	SoftwareLicenseController *softwareLicenseController = [SoftwareLicenseController sharedController];
	unsigned int archiveVersion = 0;
	
	didLoadKwikiList = YES;
	
	archivedData = [NSData dataWithContentsOfFile:[self kwikiListPath]];
	if (archivedData != nil) {
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:archivedData];
		archiveVersion = [[unarchiver decodeObjectForKey:@"archiveVersion"] unsignedIntValue];
		
		[[self mutableArrayValueForKey:@"kwikis"] setArray:[unarchiver decodeObjectForKey:@"scriptReferences"]];
		
		savedInstallationInfo = [unarchiver decodeObjectForKey:@"installationInfo"];
		savedInstallationSignature = [unarchiver decodeObjectForKey:@"installationSignature"];

		if (savedInstallationInfo != nil) {
			if ([softwareLicenseController loadInstallationInfo:savedInstallationInfo] == NO)
				[softwareLicenseController setWarningFlag:YES];
		}
		else if (savedInstallationSignature != nil) {
			if ([savedInstallationSignature isEqualToData:[softwareLicenseController installationSignature]] == NO) {
			// possible crack attempt
				[softwareLicenseController setWarningFlag:YES];
			}
		}
		else [softwareLicenseController setWarningFlag:YES];
	}
	else {
		[self loadVersion10KwikiList:self];
	}
}

- (void)loadVersion10KwikiList:(id)sender
{
	NSMutableArray *loadedKwikis;
	
	loadedKwikis = [NSKeyedUnarchiver unarchiveObjectWithFile:[self version10KwikiListPath]];
	if (loadedKwikis != nil) {
		[[self mutableArrayValueForKey:@"kwikis"] setArray:loadedKwikis];
	}
}

- (void)saveKwikiList:(id)sender
{
	NSMutableData *archivedData = [NSMutableData data];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
	SoftwareLicenseController *softwareLicenseController = [SoftwareLicenseController sharedController];
	
	if ([self savesKwikiList]) {
		[archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
		[archiver encodeObject:[self valueForKey:@"kwikis"] forKey:@"scriptReferences"];
		[archiver encodeObject:[softwareLicenseController installationInfo] forKey:@"installationInfo"];
		[archiver encodeObject:[NSNumber numberWithUnsignedInt:1] forKey:@"archiveVersion"];
		[archiver finishEncoding];
		[archiver release];
		
		if (![archivedData writeToFile:[self kwikiListPath] atomically:YES]) {
			NSLog(@"WARNING: Failed to archive script browser data to file %@", [self kwikiListPath]);
		}
		[[KwikiController sharedController] setSavesKwikiList:YES];
	} else NSLog(@"WARNING: Not saving script browser data");
}

@end

@implementation ScriptDocument (ScriptReferences)

- (ScriptReference *)reference
{
	unsigned int kwikiIndex;
	
	kwikiIndex = [[KwikiController sharedController] indexOfKwikiWithPath:[self fileName]];
	if (kwikiIndex != NSNotFound)
		return [[KwikiController sharedController] objectInKwikisAtIndex:kwikiIndex];
	else
		return nil;
}

@end
