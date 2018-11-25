//
//  ScriptDocument+Tests.m
//  Pipe
//
//  Created by René Puls on 29.03.05.
//  Copyright (c) 2005 René Puls. All rights reserved.
//

#import "ScriptDocument+Tests.h"
#import "ScriptDocument.h"

@implementation ScriptDocument_Tests

- (id)init
{
	if ((self = [super init])) {
		testDocument = [[ScriptDocument alloc] init];
		[testDocument setScript:@"#!/bin/sh\ncat\n"];
		[testDocument setInput:@"hello world"];
		[testDocument setOutputData:[@"not hello world" dataUsingEncoding:NSUTF8StringEncoding]];
	}
	return self;
}

- (void)dealloc
{
	[testDocument release];
	[super dealloc];
}

- (void)testEquality
{
	ScriptDocument *otherDocument;
	
	otherDocument = [[testDocument copy] autorelease];
	UKObjectsEqual(testDocument, otherDocument);
	UKObjectsEqual([testDocument script], [otherDocument script]);
	UKObjectsEqual([testDocument input], [otherDocument input]);
	UKObjectsEqual([testDocument output], [otherDocument output]);
	
	[otherDocument setReverseTransformation:YES];
	UKObjectsNotEqual(testDocument, otherDocument);
}

@end
