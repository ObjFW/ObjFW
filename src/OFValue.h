//
//  OFValue.h
//
//  Created by Yury Vovk on 02.11.2017.
//

#import <ObjFW/ObjFW.h>

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFValue OFValue.h ObjFW/OFVAlue.h
 *
 * @brief OFValue is a simple container for a single C or Objective-C data item.
 */
@interface OFValue : OFObject <OFCopying>

/*!
 * A C string containing the Objective-C type of the data contained in the value object.
 *
 * @note This property provides the same string produced by the @encode() compiler directive.
 *
 */
@property (readonly) const char *objCType OF_RETURNS_INNER_POINTER;

/*!
 * @brief Creates a value object containing the specified value, 
 *    interpreted with the specified Objective-C type.
 *
 * This method has the same effect as valueWithBytes:objCType: and may be deprecated in a future release. 
 * You should use valueWithBytes:objCType: instead. (APPLE legacy)
 *
 * @param value A pointer to data to be stored in the new value object
 * @param type The Objective-C type of value, as provided by the @encode() compiler directive. 
 *    Do not hard-code this parameter as a C string.
 * @return A new, autoreleased value object that contains value, 
 *    which is interpreted as being of the Objective-C type type.
 */
+ (instancetype)value:(const void *)value withObjCType:(const char *)type;

/*!
 * @brief Creates a value object containing the specified value,
 *    interpreted with the specified Objective-C type.
 *
 * @param value A pointer to data to be stored in the new value object
 * @param type The Objective-C type of value, as provided by the @encode() compiler directive.
 *    Do not hard-code this parameter as a C string.
 * @return A new, autoreleased value object that contains value,
 *    which is interpreted as being of the Objective-C type type.
 */
+ (instancetype)valueWithBytes:(const void *)value objCType:(const char *)type;

/*!
 * @brief Initializes a value object to contain the specified value, 
 *    interpreted with the specified Objective-C type.
 *
 * @param value A pointer to data to be stored in the new value object
 * @param type The Objective-C type of value, as provided by the @encode() compiler directive.
 *    Do not hard-code this parameter as a C string.
 * @return An initialized value object that contains value, which is interpreted as being of the Objective-C 
 *    type type. The returned object might be different than the original receiver.
 */
- (instancetype)initWithBytes:(const void *)value objCType:(const char *)type;

/*!
 * @brief Copies the value into the specified buffer.
 *
 * @param value A buffer into which to copy the value. The buffer must be large enough to hold the value
 */
- (void)getValue:(void *)value;

/*!
 * @brief Copies the value into the specified buffer with specified size.
 *
 * @param value A buffer into which to copy the value. The buffer must be large enough to hold the value
 * @param size A size of buffer into which to copy the value.
 */
- (void)getValue:(void *)value size:(size_t)size;

@end

@interface OFValue (Pointers)

/*!
 * Returns the value as an untyped pointer.
 *
 * @note If the value object was not created to hold a pointer-sized data item, the result is undefined.
 *
 */
@property(readonly) void *pointerValue OF_RETURNS_INNER_POINTER;

/*!
 * The value as a non-retained pointer to an object.
 *
 * @note If the value was not created to hold a pointer-sized data item, the result is undefined.
 *
 */
@property(readonly) id nonretainedObjectValue;

/*!
 * @brief Creates a value object containing the specified pointer.
 *
 * @note This method does not copy the contents of aPointer, 
 *    so you must not to free the memory at the pointer destination while the OFValue object exists.
 *
 * @param pointer The value for the new object.
 *
 * @return A new, autoreleased value object that contains aPointer.
 */
+ (instancetype)valueWithPointer:(const void *)pointer;

/*!
 * @brief Creates a value object containing the specified object.
 *
 * @note This method is useful if you want to add an object to a Collection 
 *    but don’t want the collection to create a strong reference to it.
 *
 * @param anObject The value for the new object.
 *
 * @return A new, autoreleased value object that contains Objective-C object
 */
+ (instancetype)valueWithNonretainedObject:(id)anObject;

@end

@interface OFValue (Range)

/*!
 * of_range_t structure representation of the value.
 */
@property(readonly) of_range_t rangeValue;

/*!
 * @brief Creates a new value object containing the specified of_range_t structure.
 *
 * @param range The value for the new object.
 *
 * @return A new, autoreleased value object that contains the range information.
 */
+ (instancetype)valueWithRange:(of_range_t)range;

@end

@interface OFValue (Geometry)

/*!
 * of_point_t structure representation of the value.
 */
@property(readonly) of_point_t pointValue;

/*!
 * of_dimension_t structure representation of the value.
 */
@property(readonly) of_dimension_t sizeValue;

/*!
 * of_rectangle_t structure representation of the value.
 */
@property(readonly) of_rectangle_t rectValue;

/*!
 * @brief Creates a new value object containing the specified of_point_t structure.
 *
 * @param point The value for the new object.
 *
 * @return A new, autoreleased value object that contains the point information.
 */
+ (instancetype)valueWithPoint:(of_point_t)point;

/*!
 * @brief Creates a new value object containing the specified of_dimension_t structure.
 *
 * @param size The value for the new object.
 *
 * @return A new, autoreleased value object that contains the dimension information.
 */
+ (instancetype)valueWithSize:(of_dimension_t)size;

/*!
 * @brief Creates a new value object containing the specified of_rectangle_t structure.
 *
 * @param rect The value for the new object.
 *
 * @return A new, autoreleased value object that contains the data in the rect structure.
 */
+ (instancetype)valueWithRect:(of_rectangle_t)rect;

@end

OF_ASSUME_NONNULL_END

#if !defined(NSINTEGER_DEFINED) && !__has_feature(modules)
/* Required for boxed expressions support construction of OFValue objects to work */
@compatibility_alias NSValue OFValue;
#endif
