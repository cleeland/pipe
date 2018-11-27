//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import "NSObject.h"

#import "NSCoding.h"

@interface NDAlias : NSObject <NSCoding>
{
    struct AliasRecord **aliasHandle;
    unsigned char changed;
    unsigned long mountFlags;
}

+ (id)aliasWithURL:(id)arg1;
+ (id)aliasWithURL:(id)arg1 fromURL:(id)arg2;
+ (id)aliasWithPath:(id)arg1;
+ (id)aliasWithPath:(id)arg1 fromPath:(id)arg2;
+ (id)aliasWithData:(id)arg1;
- (id)initWithPath:(id)arg1;
- (id)initWithPath:(id)arg1 fromPath:(id)arg2;
- (id)initWithURL:(id)arg1;
- (id)initWithURL:(id)arg1 fromURL:(id)arg2;
- (id)initWithCoder:(id)arg1;
- (id)initWithData:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (void)dealloc;
- (void)setAllowUserInteraction:(BOOL)arg1;
- (BOOL)allowUserInteraction;
- (void)setTryFileIDFirst:(BOOL)arg1;
- (BOOL)tryFileIDFirst;
- (id)url;
- (id)path;
- (BOOL)changed;
- (BOOL)setURL:(id)arg1;
- (BOOL)setURL:(id)arg1 fromURL:(id)arg2;
- (BOOL)setPath:(id)arg1;
- (BOOL)setPath:(id)arg1 fromPath:(id)arg2;
- (id)description;
- (id)data;

@end
