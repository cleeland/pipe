//
//  VariableTableColumn.m
//  Pipe
//
//  Created by René Puls on 10.04.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "VariableTableColumn.h"


@implementation VariableTableColumn

- (void)jg_setupCells
{
	if (textCell == nil) {
		textCell = [[NSTextFieldCell alloc] initTextCell:@""];
		[textCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	}
	if (boolCell == nil) {
		boolCell = [[NSButtonCell alloc] initTextCell:@""];
		[boolCell setButtonType:NSSwitchButton];
		[boolCell setControlSize:NSSmallControlSize];
		[boolCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	}
	if (enumCell == nil) {
		enumCell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
		[enumCell setBordered:NO];
		[enumCell setControlSize:NSMiniControlSize];
		[enumCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	}
	if (passwordCell == nil) {
		passwordCell = [[NSSecureTextFieldCell alloc] initTextCell:@""];
		[passwordCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	}
}

- (id)initWithIdentifier:(id)anObject
{
	if ((self = [super initWithIdentifier:anObject])) {
		[self jg_setupCells];
	}
	return self;
}

- (void)awakeFromNib
{
	[self jg_setupCells];
}

- (void)dealloc
{
	[textCell release];
	[boolCell release];
	[enumCell release];
	[passwordCell release];
	[super dealloc];
}

- (id)dataCellForRow:(int)row
{
	ScriptVariableType variableType;
	
	if (row == -1)
		return [super dataCellForRow:row];
	
	if ([[[self tableView] dataSource] respondsToSelector:@selector(tableView:variableTypeForRow:)]) {
		variableType = [[[self tableView] dataSource] tableView:[self tableView] variableTypeForRow:row];
		switch (variableType) {
			case ScriptPasswordVariableType:
				[passwordCell setEditable:[self isEditable]];
				return passwordCell;
			case ScriptTextVariableType:
				[textCell setEditable:[self isEditable]];
				return textCell;
			case ScriptBooleanVariableType:
				return boolCell;
			case ScriptEnumVariableType:
				[enumCell removeAllItems];
				[enumCell addItemsWithTitles:[[[self tableView] dataSource] tableView:[self tableView] possibleEnumValuesForRow:row]];
				return enumCell;
			default:
				return [super dataCellForRow:row];
		}
	}
	
	return [super dataCellForRow:row];
}

@end
