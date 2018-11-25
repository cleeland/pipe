//
//  AppearancePreferencePane.h
//  Pipe
//
//  Created by René Puls on 12.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>

@interface AppearancePreferencePane : JGPreferencePane {
    IBOutlet NSTextField *fontTextField;
}
- (void)applyPrefs:(id)sender;
- (IBAction)showFontSelector:(id)sender;
@end
