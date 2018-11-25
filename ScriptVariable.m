//
//  ScriptVariable.m
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import "ScriptVariable.h"

NSString * const ScriptVariableErrorDomain = @"ScriptVariableErrorDomain";

@implementation ScriptVariable

+ (NSMutableArray *)arrayWithVariablesFromPropertyList:(id)propertyList
{
	NSEnumerator *variablesEnumerator;
	NSDictionary *variableDict;
	NSMutableArray *array = [NSMutableArray array];
	
	NSParameterAssert(propertyList != nil);
	NSParameterAssert([propertyList isKindOfClass:[NSArray class]]);
	
	variablesEnumerator = [propertyList objectEnumerator];
	while ((variableDict = [variablesEnumerator nextObject])) {
		ScriptVariable *newVariable;
		
		newVariable = [[ScriptVariable alloc] initWithType:[[variableDict objectForKey:@"type"] intValue] name:[variableDict objectForKey:@"name"] value:[variableDict objectForKey:@"value"]];
		[newVariable setSensitive:[[variableDict objectForKey:@"sensitive"] boolValue]];
		[newVariable setPossibleValues:[variableDict objectForKey:@"possibleValues"]];
		[array addObject:newVariable];
		[newVariable release];
	}
	
	return array;
}

+ (id)propertyListFromVariablesArray:(NSArray *)variables
{
	NSMutableArray *array = [NSMutableArray array];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	NSEnumerator *variableEnumerator;
	ScriptVariable *currentVariable;
	
	NSParameterAssert(variables != nil);
	
	variableEnumerator = [variables objectEnumerator];
	while ((currentVariable = [variableEnumerator nextObject])) {
		[dict removeAllObjects];
		[dict setObject:[currentVariable name] forKey:@"name"];
		[dict setObject:[NSNumber numberWithBool:[currentVariable isSensitive]] forKey:@"sensitive"];
		[dict setObject:[NSNumber numberWithInt:[currentVariable type]] forKey:@"type"];
		if ([currentVariable possibleValues] != nil)
			[dict setObject:[currentVariable possibleValues] forKey:@"possibleValues"];
		if ([currentVariable value] != nil)
			[dict setObject:[currentVariable value] forKey:@"value"];
		[array addObject:[[dict copy] autorelease]];
	}
	
	return array;
}

+ (NSArray *)observableKeys
{
	static NSArray *observableKeys = nil;
	
	if (observableKeys == nil) {
		observableKeys = [[NSArray alloc] initWithObjects:
			@"name", 
			@"value", 
			@"type",
			@"possibleValues",
			@"sensitive",
			nil];
	}
	return observableKeys;
}

- (id)init
{
	return [self initWithType:ScriptTextVariableType name:@"untitled" value:nil];
}

- (id)initWithType:(ScriptVariableType)aType name:(NSString *)aName value:(id)aValue;
{
	NSParameterAssert(aName != nil);
	
	if ((self = [super init])) {
		name = [aName copy];
		value = [aValue copy];
		variableType = aType;
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[value release];
	[possibleValues release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	id newInstance;
	
	newInstance = [[[self class] allocWithZone:zone] initWithType:variableType name:name value:value];
	[newInstance setPossibleValues:possibleValues];
	return newInstance;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	if ([encoder allowsKeyedCoding]) {
		[encoder encodeObject:[self name] forKey:@"name"];
		[encoder encodeObject:[self value] forKey:@"value"];
		[encoder encodeInt:[self type] forKey:@"type"];
		[encoder encodeBool:[self isSensitive] forKey:@"sensitive"];
		[encoder encodeObject:[self possibleValues] forKey:@"possibleValues"];
	}
	else {
		[encoder encodeObject:[self name]];
		[encoder encodeObject:[self value]];
		[encoder encodeValueOfObjCType:@encode(ScriptVariableType) at:&variableType];
		[encoder encodeValueOfObjCType:@encode(BOOL) at:&sensitive];
		[encoder encodeObject:[self possibleValues]];
	}
}

- (id)initWithCoder:(NSCoder *)decoder
{
	NSParameterAssert(decoder != nil);
	
	if ((self = [super init])) {
		if ([decoder allowsKeyedCoding]) {
			name = [[decoder decodeObjectForKey:@"name"] retain];
			value = [[decoder decodeObjectForKey:@"value"] retain];
			variableType = [decoder decodeIntForKey:@"type"];
			sensitive = [decoder decodeBoolForKey:@"sensitive"];
			possibleValues = [[decoder decodeObjectForKey:@"possibleValues"] retain];
		}
		else {
			name = [[decoder decodeObject] retain];
			value = [[decoder decodeObject] retain];
			[decoder decodeValueOfObjCType:@encode(ScriptVariableType) at:&variableType];
			[decoder decodeValueOfObjCType:@encode(BOOL) at:&sensitive];
			possibleValues = [[decoder decodeObject] retain];
		}
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ScriptVariable %p: name=\"%@\", value=\"%@\">", 
		self, 
		[self name], 
		[self value]];
}

- (NSString *)name
{
	return name;
}

- (void)setName:(NSString *)newName
{
	if (newName != name) {
		[name release];
		name = [newName copy];
	}
}

- (BOOL)validateName:(id *)aName error:(NSError **)outError
{
	if ((*aName == nil) || ([(NSString *)*aName length] == 0)) {
		*outError = [NSError errorWithDomain:ScriptVariableErrorDomain
										code:ScriptVariableNoNameError
						localizedDescription:NSLocalizedString(@"Variable name must not be empty.", @"Error message for attempt to set an empty script variable name") 
									userInfo:nil];
		return NO;
	}
	else return YES;
}

- (id)value
{
	return value;
}

- (void)setValue:(id)newValue
{
	if (newValue != value) {
		[value release];
		value = [newValue copy];
	}
}

- (BOOL)isSensitive
{
	return sensitive;
}

- (void)setSensitive:(BOOL)flag
{
	sensitive = flag;
}

- (ScriptVariableType)type
{
	return variableType;
}

- (void)setVariableType:(ScriptVariableType)newType
{
	NSLog(@"WARNING: Obsolete method -[ScriptVariable setVariableType:] called (use setType: instead)");
	[self setType:newType];
}

- (void)setType:(ScriptVariableType)newType
{
	if (newType != variableType) {
		switch (newType) {
			case ScriptTextVariableType:
				if (variableType == ScriptEnumVariableType) {
					[self setValue:[[self possibleValues] objectAtIndex:[[self value] intValue]]];
				}
				else if (variableType == ScriptBooleanVariableType) {
					[self setValue:([[self value] boolValue] ? @"1" : nil)];
				}
				else [self setValue:nil];
				break;
			case ScriptPasswordVariableType:
				if (variableType != ScriptTextVariableType)
					[self setValue:nil];
				break;
			case ScriptEnumVariableType:
				if ((variableType == ScriptTextVariableType) && ([self value] != nil))
					[self setPossibleValues:[NSArray arrayWithObject:[self value]]];
				else
					[self setPossibleValues:[NSArray arrayWithObject:@"default"]];
				[self setValue:[[self possibleValues] objectAtIndex:0]];
				break;
			case ScriptBooleanVariableType:
				if (([self value] != nil) && (![[self value] isEqual:@""]))
					[self setValue:[NSNumber numberWithBool:YES]];
				else
					[self setValue:[NSNumber numberWithBool:NO]];
				break;
		}
		variableType = newType;
	}
}

- (NSArray *)possibleValues
{
	return possibleValues;
}

- (void)setPossibleValues:(NSArray *)newValues
{
	if (newValues != possibleValues) {
		[possibleValues release];
		possibleValues = [newValues retain];
	}
}

@end
