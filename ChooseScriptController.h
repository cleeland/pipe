/* ChooseScriptController */

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>

@class ScriptReference, ScriptServicesArrayController;

@interface ChooseScriptController : NSWindowController
{
    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *okayButton;
	IBOutlet NSPopUpButton *scriptPopUpButton;
	IBOutlet ScriptServicesArrayController *scriptReferencesController;
	IBOutlet NSButton *variablesDisclosureButton;
	IBOutlet JGExtendedTableView *variablesTableView;
	ScriptReference *selectedScriptReference;
	BOOL reverseTransformation;
	BOOL shouldSaveToFile;
	BOOL showsVariables;
	NSArray *variables;
}
+ (id)sharedController;
- (BOOL)hasScripts;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (ScriptReference *)selectedScriptReference;
- (void)setSelectedScriptReference:(ScriptReference *)newReference;
- (int)runModal;
- (BOOL)reverseTransformation;
- (void)setReverseTransformation:(BOOL)flag;
- (BOOL)shouldSaveToFile;
- (void)setShouldSaveToFile:(BOOL)flag;
- (NSArray *)variables;
- (void)setVariables:(NSArray *)newVariables;
- (BOOL)showsVariables;
- (void)setShowsVariables:(BOOL)flag;
- (void)clearPasswordVariables;
@end
