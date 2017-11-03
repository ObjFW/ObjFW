//
//  OFValue.m
//
//  Created by Yury Vovk on 02.11.2017.
//

#import "OFValue.h"
#import "OFValue_adjacent.h"

static struct {
    Class isa;
} placeholder;

@interface OFValue_placeholder: OFValue
@end

@implementation OFValue_placeholder

- (instancetype)init {
    return [(id)[OFValue_adjacent alloc] init];
}

- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type {
    return [(id)[OFValue_adjacent alloc] initWithBytes:value objCType:type];
}

- (instancetype)retain {
    return self;
}

- (void)release {
    
}

- (void)dealloc {
    OF_DEALLOC_UNSUPPORTED;
}

@end

@implementation OFValue

+ (void)initialize {
    if (self == [OFValue class])
        placeholder.isa = [OFValue_placeholder class];
}

+ (instancetype)alloc {
    if (self == [OFValue class])
        return (id)&placeholder;
    
    return [super alloc];
}

+ (instancetype)value:(const void *)value withObjCType:(const char *)type {
    return [[[self alloc] initWithBytes:value objCType:type] autorelease];
}

+ (instancetype)valueWithBytes:(const void *)value objCType:(const char *)type {
    return [[[self alloc] initWithBytes:value objCType:type] autorelease];
}

- (instancetype)init {
    
    if ([self class] == [OFValue class]) {
        @try {
            [self doesNotRecognizeSelector:_cmd];
        } @catch (id e) {
            [self release];
            
            @throw e;
        }
    }
    
    return [super init];
}

- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type {
    OF_INVALID_INIT_METHOD;
    
    OF_UNREACHABLE;
}

- (id)copy {
    return [self retain];
}

- (const char *)objCType {
    OF_UNRECOGNIZED_SELECTOR;
    
    OF_UNREACHABLE;
}

- (void)getValue:(void *)value {
    OF_UNRECOGNIZED_SELECTOR;
}

- (void)getValue:(void *)value size:(size_t)size {
    OF_UNRECOGNIZED_SELECTOR;
}

@end

@implementation OFValue (Pointers)

+ (instancetype)valueWithPointer:(const void *)pointer {
    return [self valueWithBytes:&pointer objCType:@encode(void *)];
}

+ (instancetype)valueWithNonretainedObject:(id)anObject {
    return [self valueWithBytes:&anObject objCType:@encode(id)];
}

- (void *)pointerValue {
    void *value;
    
    [self getValue:&value size:of_sizeof_type_encoding(@encode(void *))];
    
    return value;
}

- (id)nonretainedObjectValue {
    id value;
    
    [self getValue:&value size:of_sizeof_type_encoding(@encode(id))];
    
    return value;
}

@end

@implementation OFValue (Range)

+ (instancetype)valueWithRange:(of_range_t)range {
    return [self valueWithBytes:&range objCType:@encode(of_range_t)];
}

- (of_range_t)rangeValue {
    of_range_t value;
    
    [self getValue:&value size:of_sizeof_type_encoding(@encode(of_range_t))];
    
    return value;
}

@end

@implementation OFValue (Geometry)

+ (instancetype)valueWithRect:(of_rectangle_t)rect {
    return [self valueWithBytes:&rect objCType:@encode(of_rectangle_t)];
}

+ (instancetype)valueWithPoint:(of_point_t)point {
    return [self valueWithBytes:&point objCType:@encode(of_point_t)];
}

+ (instancetype)valueWithSize:(of_dimension_t)size {
    return [self valueWithBytes:&size objCType:@encode(of_dimension_t)];
}

- (of_rectangle_t)rectValue {
    of_rectangle_t value;
    
    [self getValue:&value size:of_sizeof_type_encoding(@encode(of_rectangle_t))];
    
    return value;
}

- (of_dimension_t)sizeValue {
    of_dimension_t value;
    
    [self getValue:&value size:of_sizeof_type_encoding(@encode(of_dimension_t))];
    
    return value;
}

- (of_point_t)pointValue {
    of_point_t value;
    
    [self getValue:&value size:of_sizeof_type_encoding(@encode(of_point_t))];
    
    return value;
}

@end
