//
//  AppearancePreferencePane.m
//  Pipe
//
//  Created by René Puls on 12.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "AppearancePreferencePane.h"
#import "UserDefaults.h"

@implementation AppearancePreferencePane

- (id)init
{
	if ((self = [super init])) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey] options:nil context:NULL];
	}
	return self;
}

- (void)contentViewDidLoad
{
	[self applyPrefs:self];
}

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"values.%@", PipeFontDefaultKey]];
	[super dealloc];
}

- (NSString *)title
{
	return NSLocalizedString(@"Appearance", @"Preferences panel (TOOL)");
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Appearance Preferences"];
}

- (void)showFontSelector:(id)sender
{
	NSFont *myFont;

	myFont = [NSUnarchiver unarchiveObjectWithData:JGUserDefaultValue(PipeFontDefaultKey)];

	[[NSFontManager sharedFontManager] setSelectedFont:myFont isMultiple:NO];
	[[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
	NSFont *myFont;
	
	myFont = [NSUnarchiver unarchiveObjectWithData:JGUserDefaultValue(PipeFontDefaultKey)];
	myFont = [sender convertFont:myFont];
	
	JGSetUserDefaultValue(PipeFontDefaultKey, [NSArchiver archivedDataWithRootObject:myFont]);
}

- (void)applyPrefs:(id)sender
{
	NSFont *myFont = [NSUnarchiver unarchiveObjectWithData:JGUserDefaultValue(PipeFontDefaultKey)];
	NSFont *displayFont = [NSFont fontWithName:[myFont fontName] size:12];
	
	[fontTextField setStringValue:[NSString stringWithFormat:@"%@ %.0f", [myFont displayName], [myFont pointSize]]];
	[fontTextField setFont:displayFont];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self applyPrefs:self];
}

@end
