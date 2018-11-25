//
//  ScriptVariable.h
//  Pipe
//
//  Created by René Puls on 22.03.05.
//  Copyright 2005 René Puls. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JaguarFoundation/JaguarFoundation.h>

extern NSString * const ScriptVariableErrorDomain;

enum {
	ScriptVariableNoNameError = -1,
	ScriptVariableDuplicateNameError = -2
};

typedef enum {
	ScriptTextVariableType = 0,
	ScriptBooleanVariableType = 1,
	ScriptEnumVariableType = 2,
	ScriptPasswordVariableType = 3
} ScriptVariableType;

@interface ScriptVariable : NSObject <NSCopying, NSCoding> {
	NSString *name;
	id value;
	BOOL sensitive;
	ScriptVariableType variableType;
	NSArray *possibleValues;
}
+ (NSArray *)observableKeys;
+ (NSMutableArray *)arrayWithVariablesFromPropertyList:(id)propertyList;
+ (id)propertyListFromVariablesArray:(NSArray *)variables;
- (id)initWithType:(ScriptVariableType)aType name:(NSString *)aName value:(id)defaultValue;
- (NSString *)name;
- (void)setName:(NSString *)newName;
- (id)value;
- (void)setValue:(id)newValue;
- (BOOL)isSensitive;
- (void)setSensitive:(BOOL)flag;
- (ScriptVariableType)type;
- (void)setType:(ScriptVariableType)newType;
- (NSArray *)possibleValues;
- (void)setPossibleValues:(NSArray *)newValues;
@end
