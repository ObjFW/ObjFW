//
//  OFValue.h
//
//  Created by Юрий Вовк on 02.11.2017.
//

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

@interface OFValue : OFObject <OFCopying>

@property (readonly) const char *objCType OF_RETURNS_INNER_POINTER;

+ (instancetype)value:(const void *)value withObjCType:(const char *)type;
+ (instancetype)valueWithBytes:(const void *)value objCType:(const char *)type;
- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type;

- (void)getValue:(void *)value;
- (void)getValue:(void *)value size:(size_t)size;

@end

@interface OFValue (Pointers)

@property(readonly) void *pointerValue OF_RETURNS_INNER_POINTER;
@property(readonly) id nonretainedObjectValue;

+ (instancetype)valueWithPointer:(const void *)pointer;
+ (instancetype)valueWithNonretainedObject:(id)anObject;

@end

@interface OFValue (Range)

@property(readonly) of_range_t rangeValue;

+ (instancetype)valueWithRange:(of_range_t)range;

@end

@interface OFValue (Geometry)

@property(readonly) of_point_t pointValue;
@property(readonly) of_dimension_t sizeValue;
@property(readonly) of_rectangle_t rectValue;

+ (instancetype)valueWithPoint:(of_point_t)point;
+ (instancetype)valueWithSize:(of_dimension_t)size;
+ (instancetype)valueWithRect:(of_rectangle_t)rect;

@end

OF_ASSUME_NONNULL_END

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for array literals to work */
@compatibility_alias NSValue OFValue;
#endif
