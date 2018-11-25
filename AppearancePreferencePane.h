//
//  AppearancePreferencePane.h
//  Pipe
//
//  Created by Ren� Puls on 12.03.05.
//  Copyright 2005 Ren� Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarAppKit/JaguarAppKit.h>

@interface AppearancePreferencePane : JGPreferencePane {
    IBOutlet NSTextField *fontTextField;
}
- (void)applyPrefs:(id)sender;
- (IBAction)showFontSelector:(id)sender;
@end
