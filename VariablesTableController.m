//
//  VariablesTableController.m
//  Pipe
//
//  Created by RenŽ Puls on 10.04.05.
//  Copyright 2005 RenŽ Puls. All rights reserved.
//

#import "VariablesTableController.h"
#import "ScriptVariable.h"

static NSString * const ArrangedObjectsContext = @"ArrangedObjectsContext";

@implementation VariablesTableController

- (id)init
{
	if ((self = [super init])) {
		[self setEditable:YES];
		observedVariables = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[self setArrayController:nil];
	[observedVariables release];
	[super dealloc];
}

- (void)refreshObservedVariables
{
	NSEnumerator *keyEnumerator;
	NSString *currentKey;
	
	if ([observedVariables count] > 0) {
		keyEnumerator = [[ScriptVariable observableKeys] objectEnumerator];
		while ((currentKey = [keyEnumerator nextObject])) {
			[observedVariables removeObserver:self fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[observedVariables count])] forKeyPath:currentKey];
		}
	}

	[observedVariables removeAllObjects];
	if (arrayController != nil) {
		[observedVariables setArray:[arrayController arrangedObjects]];
		
		// Start observing the new variables
		if ([observedVariables count] > 0) {
			keyEnumerator = [[ScriptVariable observableKeys] objectEnumerator];
			while ((currentKey = [keyEnumerator nextObject])) {
				[observedVariables addObserver:self toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[observedVariables count])] forKeyPath:currentKey options:0 context:NULL];
			}
		}
	}
}

- (BOOL)isEditable
{
	return editable;
}

- (void)setEditable:(BOOL)flag
{
	editable = flag;
}

- (void)setArrayController:(NSArrayController *)newController
{
	if (newController != arrayController) {
		if (arrayController != nil) {
			[arrayController removeObserver:self forKeyPath:@"arrangedObjects"];
		}
		[arrayController release];
		arrayController = [newController retain];
		if (arrayController != nil) {
			[arrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:ArrangedObjectsContext];
		}
		[self refreshObservedVariables];
		[tableView reloadData];
	}
}

- (ScriptVariableType)tableView:(NSTableView *)aTableView variableTypeForRow:(int)rowIndex
{
	ScriptVariable *variable = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
	
	return [variable type];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[arrayController arrangedObjects] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ScriptVariable *variable = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
	NSString *columnIdentifier = [aTableColumn identifier];

	if ([columnIdentifier isEqualToString:@"name"]) {
		return [variable name];
	}
	else if ([columnIdentifier isEqualToString:@"value"]) {
		return [variable value];
	}
	else return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ScriptVariable *variable = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
	NSString *columnIdentifier = [aTableColumn identifier];
	
	if ([columnIdentifier isEqualToString:@"name"] && [self isEditable]) {
		[variable setName:anObject];
	}
	else if ([columnIdentifier isEqualToString:@"value"]) {
		[variable setValue:anObject];
	}
}

- (NSArray *)tableView:(NSTableView *)aTableView possibleEnumValuesForRow:(int)rowIndex
{
	ScriptVariable *variable = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
	
	return [variable possibleValues];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == ArrangedObjectsContext) {
		[self refreshObservedVariables];
	}
	[tableView reloadData];
}

- (void)configureEnumValues:(id)sender
{
	JGInputRequest *inputRequest;
	ScriptVariable *variable = [[arrayController arrangedObjects] objectAtIndex:[tableView selectedRow]];
	
	inputRequest = [[JGInputRequest alloc] init];
	[inputRequest setAllowsEmptyInputString:NO];
	[inputRequest setMessageText:NSLocalizedString(@"Enter possible values, separated by commas:", @"Input request for configuring enum type variables")];
	[inputRequest setInputString:[[variable possibleValues] componentsJoinedByString:@","]];
	[inputRequest beginSheetModalForWindow:sheetWindow modalDelegate:self didEndSelector:@selector(configureEnumValuesDidEnd:returnCode:contextInfo:) contextInfo:variable];
	[inputRequest release];
}

- (void)configureEnumValuesDidEnd:(JGInputRequest *)request returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	ScriptVariable *variable = contextInfo;
	
	if (returnCode == NSOKButton) {
		[variable setPossibleValues:[[request inputString] componentsSeparatedByString:@","]];
		[variable setValue:[[variable possibleValues] objectAtIndex:0]];
	}
}

- (void)switchVariableType:(id)sender
{
	ScriptVariable *variable = [[arrayController arrangedObjects] objectAtIndex:[tableView selectedRow]];
	ScriptVariableType newType = [sender tag];
	
	[variable setType:newType];
	if (newType == ScriptEnumVariableType)
		[self configureEnumValues:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	SEL action = [anItem action];
	ScriptVariable *variable = nil;
	
	if ([tableView selectedRow] != -1)
		variable = [[arrayController arrangedObjects] objectAtIndex:[tableView selectedRow]];
	
	if (action == @selector(switchVariableType:)) {
		[anItem setState:([anItem tag] == [variable type])];
		return [self isEditable] && ([tableView selectedRow] != -1);
	}
	else if (action == @selector(configureEnumValues:)) {
		return [self isEditable] && ([variable type] == ScriptEnumVariableType);
	}
	else if (action == @selector(add:)) {
		return [self isEditable] && [arrayController canAdd];
	}
	else if (action == @selector(remove:)) {
		return [self isEditable] && (variable != nil);
	}
	else return YES;
}

#pragma mark Table View Delegate

- (BOOL)extendedTableView:(JGExtendedTableView *)aTableView shouldHandleKeyDown:(NSEvent *)event
{
	unichar keyCharacter;
	ScriptVariable *variable = nil;
	int selectedRow = [tableView selectedRow];
	
	if (selectedRow == -1)
		return YES;
	
	if ([event isARepeat])
		return NO;

	variable = [[arrayController arrangedObjects] objectAtIndex:[tableView selectedRow]];
	keyCharacter = [[event characters] characterAtIndex:0];
	
	if ((keyCharacter == ' ') || (keyCharacter == 13)) {
		switch ([variable type]) {
			case ScriptTextVariableType:
			case ScriptPasswordVariableType:
				[tableView editColumn:[tableView columnWithIdentifier:@"value"] row:selectedRow withEvent:event select:YES];
				return NO;
			case ScriptBooleanVariableType:
				[variable setValue:[NSNumber numberWithBool:![[variable value] boolValue]]];
				return NO;
			case ScriptEnumVariableType:
				// this is an ugly hack to activate the popup cell manually
				[currentPopUpCell release];
				currentPopUpCell = [[[tableView tableColumnWithIdentifier:@"value"] dataCellForRow:selectedRow] copy];
				[currentPopUpCell setTarget:self];
				[currentPopUpCell setAction:@selector(switchEnumValue:)];
				[currentPopUpCell selectItemAtIndex:[[variable value] intValue]];
				[currentPopUpCell performClickWithFrame:[tableView frameOfCellAtColumn:[tableView columnWithIdentifier:@"value"] row:selectedRow] inView:tableView];
				return NO;
		}
	}
	return YES;
}

- (void)switchEnumValue:(id)sender
{
	ScriptVariable *variable = nil;
	
	// part two of ugly hack for manual popup cell activation
	
	variable = [[arrayController arrangedObjects] objectAtIndex:[tableView selectedRow]];
	[variable setValue:[NSNumber numberWithInt:[currentPopUpCell indexOfSelectedItem]]];
	[currentPopUpCell autorelease];
	currentPopUpCell = nil;
	[tableView setNeedsDisplay:YES];
}

- (void)add:(id)sender
{
	[arrayController add:sender];
}

- (void)remove:(id)sender
{
	[arrayController removeObjectAtArrangedObjectIndex:[tableView selectedRow]];
}

@end
