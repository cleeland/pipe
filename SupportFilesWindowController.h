//
//  SupportFilesWindowController.h
//  Pipe
//
//  Created by René Puls on 16.04.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SupportFilesWindowController : NSWindowController {
	IBOutlet NSArrayController *supportFilesArrayController;
	IBOutlet NSTableView *filesTableView;
	NSMutableArray *supportFiles;
	NSInvocation *endSheetInvocation;
}
- (NSArray *)supportFiles;
- (void)setSupportFiles:(NSArray *)newFiles;
- (void)beginSheetModalForWindow:(NSWindow *)aWindow modalDelegate:(id)delegate didEndSelector:(SEL)aSelector contextInfo:(void *)contextInfo;
- (IBAction)addFile:(id)sender;
- (IBAction)okay:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
@end
