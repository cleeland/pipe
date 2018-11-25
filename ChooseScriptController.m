#import "ChooseScriptController.h"
#import "ScriptReference.h"
#import "ScriptVariable.h"
#import "ScriptServicesArrayController.h"
#import <JaguarAppKit/JaguarAppKit.h>

@implementation ChooseScriptController

+ (id)sharedController
{
	static id sharedInstance = nil;
	
	if (sharedInstance == nil)
		sharedInstance = [[self alloc] init];
	return sharedInstance;
}

- (id)init
{
	if ((self = [super initWithWindowNibName:@"ChooseScript"])) {
		showsVariables = YES;
	}
	return self;
}

- (void)dealloc
{
	[selectedScriptReference release];
	[variables release];
	[super dealloc];
}

- (void)windowDidLoad
{
	[scriptReferencesController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
	[variablesTableView setSelectsNextCellOnEndEditing:NO];
}

- (int)runModal
{
	[self window];
	[scriptReferencesController rearrangeObjects];
	if ([self selectedScriptReference] == nil) {
		if ([[scriptReferencesController arrangedObjects] count] > 0)
			[self setSelectedScriptReference:[[scriptReferencesController arrangedObjects] objectAtIndex:0]];
	}
	[self clearPasswordVariables];
	return [NSApp runModalForWindow:[self window]];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModalWithCode:NSCancelButton];
	[[self window] orderOut:self];
}

- (IBAction)okay:(id)sender
{
	[NSApp stopModalWithCode:NSOKButton];
	[[self window] orderOut:self];
}

- (BOOL)hasScripts
{
	[self window];
	return ([[scriptReferencesController arrangedObjects] count] > 0);
}

- (ScriptReference *)selectedScriptReference
{
	return selectedScriptReference;
}

- (void)setSelectedScriptReference:(ScriptReference *)newReference
{
	id variablesProperty;
	
	if (newReference != selectedScriptReference) {
		[selectedScriptReference release];
		selectedScriptReference = [newReference retain];
		if ((variablesProperty = [[selectedScriptReference cachedPropertyList] objectForKey:PipeScriptVariablesPlistKey])) {
			[self setVariables:[ScriptVariable arrayWithVariablesFromPropertyList:variablesProperty]];
		} else [self setVariables:[NSArray array]];
	}
}

- (BOOL)reverseTransformation
{
	return reverseTransformation;
}

- (void)setReverseTransformation:(BOOL)flag
{
	reverseTransformation = flag;
}

- (BOOL)shouldSaveToFile
{
	return shouldSaveToFile;
}

- (void)setShouldSaveToFile:(BOOL)flag
{
	shouldSaveToFile = flag;
}

- (NSArray *)variables
{
	return variables;
}

- (void)setVariables:(NSArray *)newVariables
{
	if (newVariables != variables) {
		[variables release];
		variables = [newVariables copy];
		[self setShowsVariables:([variables count] > 0)];
	}
}

- (BOOL)showsVariables
{
	return showsVariables;
}

- (void)setShowsVariables:(BOOL)flag
{
	float heightDiff;
	NSSize newSize;
	
	if (showsVariables != flag) {
		showsVariables = flag;
		heightDiff = NSHeight([[variablesTableView enclosingScrollView] frame]);
		heightDiff += (NSMinY([[variablesTableView enclosingScrollView] frame])-NSMaxY([okayButton frame]));
		
		if (flag == NO) {
			heightDiff = -heightDiff;
			[[variablesTableView enclosingScrollView] setHidden:YES];
		}
		
		newSize.width = NSWidth([[self window] frame]);
		newSize.height = NSHeight([[self window] frame]) + heightDiff;

		[[self window] setFrameSizeMaintainingScreenLocation:newSize display:YES animate:YES];
		
		if (flag == YES) {
			[[variablesTableView enclosingScrollView] setHidden:NO];
		}
	}
}

- (void)clearPasswordVariables
{
	NSEnumerator *enumerator;
	ScriptVariable *currentVar;
	
	enumerator = [[self variables] objectEnumerator];
	while ((currentVar = [enumerator nextObject])) {
		if ([currentVar type] == ScriptPasswordVariableType)
			[currentVar setValue:nil];
	}
}

#pragma mark Table View Delegate

- (BOOL)extendedTableView:(JGExtendedTableView *)aTableView shouldHandleKeyDown:(NSEvent *)event
{
	unichar keyCharacter;
	
	keyCharacter = [[event characters] characterAtIndex:0];
	
	if (aTableView == variablesTableView) {
		if ((keyCharacter == ' ') || (keyCharacter == 13)) {
			if ([variablesTableView selectedRow] != -1) {
				[variablesTableView editColumn:[variablesTableView columnWithIdentifier:@"value"] row:[variablesTableView selectedRow] withEvent:event select:YES];
				return NO;
			}
		}
	}
	return YES;
}

@end
