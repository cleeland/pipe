//
//  ScriptBrowserDocument.m
//  Pipe
//
//  Created by René Puls on 14.02.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptBrowserDocument.h"
#import "ScriptBrowserController.h"

@implementation ScriptBrowserDocument

#pragma mark Init and Cleanup

+ (id)sharedDocument
{
	static id sharedInstance = nil;
	
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
		[sharedInstance makeWindowControllers];
	}
	return sharedInstance;
}

- (void)dealloc
{
	[browserWindowController release];
	[lastScriptAlias release];
	[lastModificationDate release];
	[super dealloc];
}

#pragma mark NSDocument

- (void)makeWindowControllers
{
	if (browserWindowController == nil) {
		browserWindowController = [[ScriptBrowserController alloc] init];
		[self addWindowController:browserWindowController];
	}
}

- (void)close
{
	// ignore
}

- (void)removeWindowController:(NSWindowController *)windowController
{
	// ignore
}

- (BOOL)isDocumentEdited
{
	return NO;
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType
{
	// do nothing
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];
	
	if (action == @selector(saveDocument:))
		return NO;
	else if (action == @selector(saveDocumentAs:))
		return NO;
	else if (action == @selector(print:))
		return NO;
	else if (action == @selector(runPageLayout:))
		return NO;
	else
		return [super validateMenuItem:anItem];
}

#pragma mark Script Management

- (void)loadScript:(ScriptDocument *)scriptDocument
{
	NSParameterAssert(scriptDocument != nil);
	
	[self setScript:[scriptDocument script]];
	[self setArgumentString:[scriptDocument argumentString]];
	[self setRunCommand:[scriptDocument runCommand]];
	[self setExecutesDirectly:[scriptDocument executesDirectly]];
	[self setLastScriptAlias:[NDAlias aliasWithPath:[scriptDocument fileName]]];
	[self setUsageInfo:[scriptDocument usageInfo]];
	[self setHomeURL:[scriptDocument homeURL]];
	[[self mutableArrayValueForKey:@"supportFiles"] setArray:[scriptDocument valueForKey:@"supportFiles"]];
	[[self mutableArrayValueForKey:@"variables"] setArray:[scriptDocument valueForKey:@"variables"]];
	if ([self outputType] != [scriptDocument outputType])
		[self setOutputData:nil];
	[self setOutputType:[scriptDocument outputType]];
	
	[[self undoManager] removeAllActions];
}

- (IBAction)openScriptInEditor:(id)sender;
{
	NSString *scriptPath;
	
	scriptPath = [[self lastScriptAlias] path];
	if (scriptPath != nil) {
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:scriptPath display:YES];
	}
}

- (IBAction)openLoadedScript:(id)sender
{
	[self openScriptInEditor:sender];
}

#pragma mark Accessors

- (NSDate *)lastModificationDate
{
	return lastModificationDate;
}

- (NSString *)displayName
{
	return NSLocalizedString(@"Script Browser", @"Title of the script browser window");
}

- (NDAlias *)lastScriptAlias
{
	return lastScriptAlias;
}

- (void)setLastScriptAlias:(NDAlias *)newAlias
{
	if (lastScriptAlias != newAlias) {
		[lastScriptAlias release];
		lastScriptAlias = [newAlias retain];
		
		[lastModificationDate release];
		lastModificationDate = [[[[NSFileManager defaultManager] fileAttributesAtPath:[newAlias path] traverseLink:YES] objectForKey:NSFileModificationDate] copy];
	}
}

@end
