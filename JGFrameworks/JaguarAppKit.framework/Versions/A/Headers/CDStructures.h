//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#pragma mark Named Structures

struct _NSPoint {
    float _field1;
    float _field2;
};

struct _NSRange {
    unsigned int _field1;
    unsigned int _field2;
};

struct _NSRect {
    struct _NSPoint _field1;
    struct _NSSize _field2;
};

struct _NSSize {
    float _field1;
    float _field2;
};

struct _Vector_impl {
    struct _NSRange *_M_start;
    struct _NSRange *_M_finish;
    struct _NSRange *_M_end_of_storage;
};

struct vector<_NSRange, std::allocator<_NSRange>> {
    struct _Vector_impl _field1;
};
