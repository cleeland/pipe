//
//  ScriptServicesArrayController.m
//  Pipe
//
//  Created by René Puls on 26.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptServicesArrayController.h"
#import "ScriptReference.h"

@implementation ScriptServicesArrayController

- (NSArray *)arrangeObjects:(NSArray *)objects
{
	NSMutableArray *filteredArray;
	NSEnumerator *referenceEnumerator;
	ScriptReference *currentReference;
	unsigned int currentIndex;
	
	filteredArray = [NSMutableArray arrayWithArray:objects];
	
	referenceEnumerator = [objects reverseObjectEnumerator];
	currentIndex = [objects count];
	while ((currentReference = [referenceEnumerator nextObject])) {
		currentIndex--;
		if ([currentReference isServiceCapable] == NO) {
			[filteredArray removeObjectAtIndex:currentIndex];
		}
	}
	
	return [super arrangeObjects:filteredArray];
}

@end
