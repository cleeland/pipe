//
//  VariableTableColumn.h
//  Pipe
//
//  Created by Ren� Puls on 10.04.05.
//  Copyright 2005 Ren� Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ScriptVariable.h"

@interface VariableTableColumn : NSTableColumn {
	NSTextFieldCell *textCell;
	NSButtonCell *boolCell;
	NSPopUpButtonCell *enumCell;
	NSSecureTextFieldCell *passwordCell;
}
@end

@interface NSObject (VariableTableColumnDataSource)
- (ScriptVariableType)tableView:(NSTableView *)aTableView variableTypeForRow:(int)rowIndex;
- (NSArray *)tableView:(NSTableView *)aTableView possibleEnumValuesForRow:(int)rowIndex;
@end
