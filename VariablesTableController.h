//
//  VariablesTableController.h
//  Pipe
//
//  Created by René Puls on 10.04.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VariablesTableController : NSObject {
	IBOutlet NSWindow *sheetWindow;
	IBOutlet NSArrayController *arrayController;
	IBOutlet JGExtendedTableView *tableView;
	BOOL editable;
	NSPopUpButtonCell *currentPopUpCell;
	NSMutableArray *observedVariables;
}
- (void)setArrayController:(NSArrayController *)newController;
- (BOOL)isEditable;
- (void)setEditable:(BOOL)flag;
@end
