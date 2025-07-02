/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "objfw-defs.h"

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>
#include <math.h>

#include "macros.h"

#import "OFOnce.h"

/*
 * Some versions of MinGW require <winsock2.h> to be included before
 * <windows.h>. Do this here to make sure this is always done in the correct
 * order, even if another header includes just <windows.h>.
 */
#ifdef __MINGW32__
# include <_mingw.h>
# ifdef __MINGW64_VERSION_MAJOR
#  include <winsock2.h>
#  include <windows.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/** @file */

/**
 * @brief A result of a comparison.
 */
typedef enum {
	/** The left object is smaller than the right */
	OFOrderedAscending = -1,
	/** Both objects are equal */
	OFOrderedSame = 0,
	/** The left object is bigger than the right */
	OFOrderedDescending = 1
} OFComparisonResult;

/**
 * @brief A function to compare two objects.
 *
 * @param left The left object
 * @param right The right object
 * @param context Context passed along for comparing
 * @return The order of the objects
 */
typedef OFComparisonResult (*OFCompareFunction)(id _Nonnull left,
    id _Nonnull right, void *_Nullable context);

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A comparator to compare two objects.
 *
 * @param left The left object
 * @param right The right object
 * @return The order of the objects
 */
typedef OFComparisonResult (^OFComparator)(id _Nonnull left, id _Nonnull right);
#endif

/**
 * @brief An enum for representing endianness.
 */
typedef enum {
	/** Most significant byte first (big endian) */
	OFByteOrderBigEndian,
	/** Least significant byte first (little endian) */
	OFByteOrderLittleEndian,
	/** Native byte order of the system */
#ifdef OF_BIG_ENDIAN
	OFByteOrderNative = OFByteOrderBigEndian
#else
	OFByteOrderNative = OFByteOrderLittleEndian
#endif
} OFByteOrder;

/**
 * @struct OFRange OFObject.h ObjFW/ObjFW.h
 *
 * @brief A range.
 */
typedef struct OF_BOXABLE OFRange {
	/** The start of the range */
	size_t location;
	/** The length of the range */
	size_t length;
} OFRange;

/**
 * @brief Creates a new OFRange.
 *
 * @param start The starting index of the range
 * @param length The length of the range
 * @return An OFRange with the specified start and length
 */
static OF_INLINE OFRange OF_CONST_FUNC
OFMakeRange(size_t start, size_t length)
{
	OFRange range = { start, length };

	return range;
}

/**
 * @brief Returns whether the two ranges are equal.
 *
 * @param range1 The first range for the comparison
 * @param range2 The second range for the comparison
 * @return Whether the two ranges are equal
 */
static OF_INLINE bool
OFEqualRanges(OFRange range1, OFRange range2)
{
	if (range1.location != range2.location)
		return false;

	if (range1.length != range2.length)
		return false;

	return true;
}

/**
 * @brief Returns the end of the range, which is its location + its length.
 *
 * @param range The range whose end to return
 * @return The end of the range
 */
static OF_INLINE size_t
OFEndOfRange(OFRange range)
{
	return range.location + range.length;
}

/**
 * @brief Returns whether the specified location is in the specified range.
 *
 * @param location The location
 * @param range The range
 * @return Whether the specified location is in the specified range
 */
static OF_INLINE bool
OFLocationInRange(size_t location, OFRange range)
{
	return (location >= range.location &&
	    location < OFEndOfRange(range));
}

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The union of the two ranges if they are overlapping or adjacent,
 *	  otherwise returns a range with location @ref OFNotFound and length 0.
 *
 * @param range1 The first range
 * @param range2 The second range
 * @return The two ranges merged
 */
extern OFRange OFUnionRange(OFRange range1, OFRange range2);
#ifdef __cplusplus
}
#endif

/**
 * @brief A time interval in seconds.
 */
typedef double OFTimeInterval;

/**
 * @struct OFPoint OFObject.h ObjFW/ObjFW.h
 *
 * @brief A point in 2D space.
 */
typedef struct OF_BOXABLE OFPoint {
	/** The x coordinate of the point */
	float x;
	/** The y coordinate of the point */
	float y;
} OFPoint;

/**
 * @brief Creates a new OFPoint.
 *
 * @param x The x coordinate of the point
 * @param y The x coordinate of the point
 * @return An OFPoint with the specified coordinates
 */
static OF_INLINE OFPoint OF_CONST_FUNC
OFMakePoint(float x, float y)
{
	OFPoint point = { x, y };

	return point;
}

/**
 * @brief Returns whether the two points are equal.
 *
 * @param point1 The first point for the comparison
 * @param point2 The second point for the comparison
 * @return Whether the two points are equal
 */
static OF_INLINE bool
OFEqualPoints(OFPoint point1, OFPoint point2)
{
	if (point1.x != point2.x)
		return false;

	if (point1.y != point2.y)
		return false;

	return true;
}

/**
 * @struct OFSize OFObject.h ObjFW/ObjFW.h
 *
 * @brief A size.
 */
typedef struct OF_BOXABLE OFSize {
	/** The width of the size */
	float width;
	/** The height of the size */
	float height;
} OFSize;

/**
 * @brief Creates a new OFSize.
 *
 * @param width The width of the size
 * @param height The height of the size
 * @return An OFSize with the specified width and height
 */
static OF_INLINE OFSize OF_CONST_FUNC
OFMakeSize(float width, float height)
{
	OFSize size = { width, height };

	return size;
}

/**
 * @brief Returns whether the two sizes are equal.
 *
 * @param size1 The first size for the comparison
 * @param size2 The second size for the comparison
 * @return Whether the two sizes are equal
 */
static OF_INLINE bool
OFEqualSizes(OFSize size1, OFSize size2)
{
	if (size1.width != size2.width)
		return false;

	if (size1.height != size2.height)
		return false;

	return true;
}

/**
 * @struct OFRect OFObject.h ObjFW/ObjFW.h
 *
 * @brief A rectangle.
 */
typedef struct OF_BOXABLE OFRect {
	/** The point from where the rectangle originates */
	OFPoint origin;
	/** The size of the rectangle */
	OFSize size;
} OFRect;

/**
 * @brief Creates a new OFRect.
 *
 * @param x The x coordinate of the top left corner of the rectangle
 * @param y The y coordinate of the top left corner of the rectangle
 * @param width The width of the rectangle
 * @param height The height of the rectangle
 * @return An OFRect with the specified origin and size
 */
static OF_INLINE OFRect OF_CONST_FUNC
OFMakeRect(float x, float y, float width, float height)
{
	OFRect rect = {
		OFMakePoint(x, y),
		OFMakeSize(width, height)
	};

	return rect;
}

/**
 * @brief Returns whether the two rectangles are equal.
 *
 * @param rect1 The first rectangle for the comparison
 * @param rect2 The second rectangle for the comparison
 * @return Whether the two rectangles are equal
 */
static OF_INLINE bool
OFEqualRects(OFRect rect1, OFRect rect2)
{
	if (!OFEqualPoints(rect1.origin, rect2.origin))
		return false;

	if (!OFEqualSizes(rect1.size, rect2.size))
		return false;

	return true;
}

/**
 * @struct OFVector3D OFObject.h ObjFW/ObjFW.h
 *
 * @brief A vector in 3D space.
 */
typedef struct OF_BOXABLE OFVector3D {
	/** The x coordinate of the vector */
	float x;
	/** The y coordinate of the vector */
	float y;
	/** The z coordinate of the vector */
	float z;
} OFVector3D;

/**
 * @brief Creates a new OFVector3D.
 *
 * @param x The x coordinate of the vector
 * @param y The x coordinate of the vector
 * @param z The z coordinate of the vector
 * @return An OFVector3D with the specified coordinates
 */
static OF_INLINE OFVector3D OF_CONST_FUNC
OFMakeVector3D(float x, float y, float z)
{
	OFVector3D vector = { x, y, z };

	return vector;
}

/**
 * @brief Returns whether the two vectors are equal.
 *
 * @param vector1 The first vector for the comparison
 * @param vector2 The second vectors for the comparison
 * @return Whether the two vectors are equal
 */
static OF_INLINE bool
OFEqualVectors3D(OFVector3D vector1, OFVector3D vector2)
{
	if (vector1.x != vector2.x)
		return false;

	if (vector1.y != vector2.y)
		return false;

	if (vector1.z != vector2.z)
		return false;

	return true;
}

/**
 * @brief Adds the two specified vectors.
 *
 * @param vector1 The vector to add to
 * @param vector2 The vector to add
 * @return The sum of the two vectors
 */
static OF_INLINE OFVector3D
OFAddVectors3D(OFVector3D vector1, OFVector3D vector2)
{
	return OFMakeVector3D(vector1.x + vector2.x, vector1.y + vector2.y,
	    vector1.z + vector2.z);
}

/**
 * @brief Subtracts the second vector from the first vector.
 *
 * @param vector1 The vector to subtract from
 * @param vector2 The vector to subtract
 * @return The second vector subtracted from the first vector
 */
static OF_INLINE OFVector3D
OFSubtractVectors3D(OFVector3D vector1, OFVector3D vector2)
{
	return OFMakeVector3D(vector1.x - vector2.x, vector1.y - vector2.y,
	    vector1.z - vector2.z);
}

/**
 * @brief Multiplies the specified vector with a scalar.
 *
 * @param vector The vector
 * @param scalar The scalar to multiply with
 * @return The vector multiplied with the scalar
 */
static OF_INLINE OFVector3D
OFMultiplyVector3D(OFVector3D vector, float scalar)
{
	return OFMakeVector3D(vector.x * scalar, vector.y * scalar,
	    vector.z * scalar);
}

/**
 * @brief Calculates the dot product of the two specified vectors.
 *
 * @param vector1 The first vector
 * @param vector2 The second vector
 * @return The dot product of the two vectors
 */
static OF_INLINE float
OFDotProductOfVectors3D(OFVector3D vector1, OFVector3D vector2)
{
	return vector1.x * vector2.x + vector1.y * vector2.y +
	    vector1.z * vector2.z;
}

/**
 * @brief Calculates the distance between two vectors
 *
 * @param vector1 The first vector
 * @param vector2 The second vector
 * @return The distance of the two vectors
 */
static OF_INLINE float
OFDistanceOfVectors3D(OFVector3D vector1, OFVector3D vector2)
{
	OFVector3D difference = OFSubtractVectors3D(vector1, vector2);

	return sqrtf(OFDotProductOfVectors3D(difference, difference));
}

/**
 * @struct OFVector4D OFObject.h ObjFW/ObjFW.h
 *
 * @brief A vector in 4D space.
 */
typedef struct OF_BOXABLE OFVector4D {
	/** The x coordinate of the vector */
	float x;
	/** The y coordinate of the vector */
	float y;
	/** The z coordinate of the vector */
	float z;
	/** The w coordinate of the vector */
	float w;
} OFVector4D;

/**
 * @brief Creates a new OFVector4D.
 *
 * @param x The x coordinate of the vector
 * @param y The x coordinate of the vector
 * @param z The z coordinate of the vector
 * @param w The w coordinate of the vector
 * @return An OFVector4D with the specified coordinates
 */
static OF_INLINE OFVector4D OF_CONST_FUNC
OFMakeVector4D(float x, float y, float z, float w)
{
	OFVector4D vector = { x, y, z, w };

	return vector;
}

/**
 * @brief Returns whether the two vectors are equal.
 *
 * @param vector1 The first vector for the comparison
 * @param vector2 The second vectors for the comparison
 * @return Whether the two vectors are equal
 */
static OF_INLINE bool
OFEqualVectors4D(OFVector4D vector1, OFVector4D vector2)
{
	if (vector1.x != vector2.x)
		return false;

	if (vector1.y != vector2.y)
		return false;

	if (vector1.z != vector2.z)
		return false;

	if (vector1.w != vector2.w)
		return false;

	return true;
}

/**
 * @brief Adds the two specified vectors.
 *
 * @param vector1 The vector to add to
 * @param vector2 The vector to add
 * @return The sum of the two vectors
 */
static OF_INLINE OFVector4D
OFAddVectors4D(OFVector4D vector1, OFVector4D vector2)
{
	return OFMakeVector4D(vector1.x + vector2.x, vector1.y + vector2.y,
	    vector1.z + vector2.z, vector1.w + vector2.w);
}

/**
 * @brief Subtracts the second vector from the first vector.
 *
 * @param vector1 The vector to subtract from
 * @param vector2 The vector to subtract
 * @return The second vector subtracted from the first vector
 */
static OF_INLINE OFVector4D
OFSubtractVectors4D(OFVector4D vector1, OFVector4D vector2)
{
	return OFMakeVector4D(vector1.x - vector2.x, vector1.y - vector2.y,
	    vector1.z - vector2.z, vector1.w - vector2.w);
}

/**
 * @brief Multiplies the specified vector with a scalar.
 *
 * @param vector The vector
 * @param scalar The scalar to multiply with
 * @return The vector multiplied with the scalar
 */
static OF_INLINE OFVector4D
OFMultiplyVector4D(OFVector4D vector, float scalar)
{
	return OFMakeVector4D(vector.x * scalar, vector.y * scalar,
	    vector.z * scalar, vector.w * scalar);
}

/**
 * @brief Calculates the dot product of the two specified vectors.
 *
 * @param vector1 The first vector
 * @param vector2 The second vector
 * @return The dot product of the two vectors
 */
static OF_INLINE float
OFDotProductOfVectors4D(OFVector4D vector1, OFVector4D vector2)
{
	return vector1.x * vector2.x + vector1.y * vector2.y +
	    vector1.z * vector2.z + vector1.w * vector2.w;
}

/**
 * @brief Calculates the distance between two vectors
 *
 * @param vector1 The first vector
 * @param vector2 The second vector
 * @return The distance of the two vectors
 */
static OF_INLINE float
OFDistanceOfVectors4D(OFVector4D vector1, OFVector4D vector2)
{
	OFVector4D difference = OFSubtractVectors4D(vector1, vector2);

	return sqrtf(OFDotProductOfVectors4D(difference, difference));
}

/**
 * @brief Adds the specified byte to the hash.
 *
 * @param hash A pointer to a hash to add the byte to
 * @param byte The byte to add to the hash
 */
static OF_INLINE void
OFHashAddByte(unsigned long *_Nonnull hash, unsigned char byte)
{
	uint32_t tmp = (uint32_t)*hash;

	tmp += byte;
	tmp += tmp << 10;
	tmp ^= tmp >> 6;

	*hash = tmp;
}

/**
 * @brief Adds the specified hash to the hash.
 *
 * @param hash A pointer to a hash to add the hash to
 * @param otherHash The hash to add to the hash
 */
static OF_INLINE void
OFHashAddHash(unsigned long *_Nonnull hash, unsigned long otherHash)
{
	OFHashAddByte(hash, (otherHash >> 24) & 0xFF);
	OFHashAddByte(hash, (otherHash >> 16) & 0xFF);
	OFHashAddByte(hash, (otherHash >>  8) & 0xFF);
	OFHashAddByte(hash, otherHash & 0xFF);
}

/**
 * @brief Finalizes the specified hash.
 *
 * @param hash A pointer to the hash to finalize
 */
static OF_INLINE void
OFHashFinalize(unsigned long *_Nonnull hash)
{
	uint32_t tmp = (uint32_t)*hash;

	tmp += tmp << 3;
	tmp ^= tmp >> 11;
	tmp += tmp << 15;

	*hash = tmp;
}

static const size_t OFNotFound = SIZE_MAX;

@class OFMethodSignature;
@class OFString;
@class OFThread;

/**
 * @protocol OFObject OFObject.h ObjFW/ObjFW.h
 *
 * @brief The protocol which all root classes implement.
 */
@protocol OFObject
/**
 * @brief Returns the class of the object.
 *
 * @return The class of the object
 */
- (Class)class;

/**
 * @brief Returns the superclass of the object.
 *
 * @return The superclass of the object
 */
- (nullable Class)superclass;

/**
 * @brief Returns a hash for the object.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * @warning If you reimplement this, you also need to reimplement @ref isEqual:
 *	    to behave in a way compatible to your reimplementation of this
 *	    method!
 *
 * @return A hash for the object
 */
- (unsigned long)hash;

/**
 * @brief Returns the retain count.
 *
 * @return The retain count
 */
- (unsigned int)retainCount;

/**
 * @brief Returns whether the object is a proxy object.
 *
 * @return Whether the object is a proxy object
 */
- (bool)isProxy;

/**
 * @brief Returns a boolean whether the object is of the specified kind.
 *
 * @param class_ The class for which the receiver is checked
 * @return A boolean whether the object is of the specified kind
 */
- (bool)isKindOfClass: (Class)class_;

/**
 * @brief Returns a boolean whether the object is a member of the specified
 *	  class.
 *
 * @param class_ The class for which the receiver is checked
 * @return A boolean whether the object is a member of the specified class
 */
- (bool)isMemberOfClass: (Class)class_;

/**
 * @brief Returns a boolean whether the object responds to the specified
 *	  selector.
 *
 * @param selector The selector which should be checked for respondence
 * @return A boolean whether the objects responds to the specified selector
 */
- (bool)respondsToSelector: (SEL)selector;

/**
 * @brief Checks whether the object conforms to the specified protocol.
 *
 * @param protocol The protocol which should be checked for conformance
 * @return A boolean whether the object conforms to the specified protocol
 */
- (bool)conformsToProtocol: (Protocol *)protocol;

/**
 * @brief Returns the implementation for the specified selector.
 *
 * @param selector The selector for which the method should be returned
 * @return The implementation for the specified selector
 */
- (nullable IMP)methodForSelector: (SEL)selector;

/**
 * @brief Performs the specified selector.
 *
 * @param selector The selector to perform
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector;

/**
 * @brief Performs the specified selector with the specified object.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector withObject: (nullable id)object;

/**
 * @brief Performs the specified selector with the specified objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object1
		    withObject: (nullable id)object2;

/**
 * @brief Performs the specified selector with the specified objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object1
		    withObject: (nullable id)object2
		    withObject: (nullable id)object3;

/**
 * @brief Performs the specified selector with the specified objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @return The object returned by the method specified by the selector
 */
- (nullable id)performSelector: (SEL)selector
		    withObject: (nullable id)object1
		    withObject: (nullable id)object2
		    withObject: (nullable id)object3
		    withObject: (nullable id)object4;

/**
 * @brief Checks two objects for equality.
 *
 * Classes containing data (like strings, arrays, lists etc.) should reimplement
 * this!
 *
 * @warning If you reimplement this, you also need to reimplement @ref hash to
 *	    return the same hash for objects which are equal!
 *
 * @param object The object which should be tested for equality
 * @return A boolean whether the object is equal to the specified object
 */
- (bool)isEqual: (nullable id)object;

/**
 * @brief Increases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (instancetype)retain;

/**
 * @brief Decreases the retain count.
 *
 * Each time an object is released, the retain count gets decreased and the
 * object deallocated if it reaches 0.
 */
- (void)release;

/**
 * @brief Adds the object to the topmost autorelease pool of the thread's
 *	  autorelease pool stack.
 *
 * @return The object
 */
- (instancetype)autorelease;

/**
 * @brief Returns the receiver.
 *
 * @return The receiver
 */
- (instancetype)self;

/**
 * @brief Returns whether the object allows a weak reference.
 *
 * @return Whether the object allows a weak references
 */
- (bool)allowsWeakReference;

/**
 * @brief Retain a weak reference to this object.
 *
 * @return Whether a weak reference to this object has been retained
 */
- (bool)retainWeakReference;
@end

/**
 * @class OFObject OFObject.h ObjFW/ObjFW.h
 *
 * @brief The root class for all other classes inside ObjFW.
 */
OF_ROOT_CLASS
@interface OFObject <OFObject>
{
@private
#ifndef __clang_analyzer__
	Class _isa;
#else
	Class _isa __attribute__((__unused__));
#endif
}

#ifdef OF_HAVE_CLASS_PROPERTIES
# ifndef __cplusplus
@property (class, readonly, nonatomic) Class class;
# else
@property (class, readonly, nonatomic, getter=class) Class class_;
# endif
@property (class, readonly, nonatomic) OFString *className;
@property (class, readonly, nullable, nonatomic) Class superclass;
@property (class, readonly, nonatomic) OFString *description;
#endif

#ifndef __cplusplus
@property (readonly, nonatomic) Class class;
#else
@property (readonly, nonatomic, getter=class) Class class_;
#endif
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) Class superclass;
@property (readonly, nonatomic) unsigned long hash;
@property (readonly, nonatomic) unsigned int retainCount;
@property (readonly, nonatomic) bool isProxy;
@property (readonly, nonatomic) bool allowsWeakReference;

/**
 * @brief The name of the object's class.
 */
@property (readonly, nonatomic) OFString *className;

/**
 * @brief A description for the object.
 *
 * This is used when the object is used in a format string and for debugging
 * purposes.
 */
@property (readonly, nonatomic) OFString *description;

/**
 * @brief A method which is called once when the class is loaded into the
 *	  runtime.
 *
 * Derived classes can override this to execute their own code when the class
 * is loaded.
 *
 * @warning You cannot make use of other classes from inside this method! Only
 *	    the class itself, its superclasses and instances of the class or
 *	    its superclassses can be messaged!
 */
+ (void)load;

/**
 * @brief A method which is called when the class is unloaded from the runtime.
 *
 * Derived classes can override this to execute their own code when the class
 * is unloaded.
 *
 * @warning This is not supported by the Apple runtime and currently only
 *	    called by the ObjFW runtime when @ref objc_deinit has been called!
 *	    In the future, this might also be called by the ObjFW runtime when
 *	    the class is part of a plugin that is being unloaded.
 */
+ (void)unload;

/**
 * @brief A method which is called the moment before the first call to the class
 *	  is being made.
 *
 * Derived classes can override this to execute their own code on
 * initialization. They should make sure to not execute any code if self is not
 * the class itself, as it might happen that the method was called for a
 * subclass which did not override this method.
 */
+ (void)initialize;

/**
 * @brief Allocates memory for an instance of the class and sets up the memory
 *	  pool for the object.
 *
 * This method will never return `nil`.
 *
 * @return The allocated object
 * @throw OFAllocFailedException There was not enough memory to allocate the
 *				 object
 * @throw OFInitializationFailedException The instance could not be constructed
 */
+ (instancetype)alloc;

/**
 * @brief Returns the class.
 *
 * @return The class
 */
+ (Class)class;

/**
 * @brief Returns the name of the class as a string.
 *
 * @return The name of the class as a string
 */
+ (OFString *)className;

/**
 * @brief Returns a boolean whether the class is a subclass of the specified
 *	  class.
 *
 * @param class_ The class which is checked for being a superclass
 * @return A boolean whether the class is a subclass of the specified class
 */
+ (bool)isSubclassOfClass: (Class)class_;

/**
 * @brief Returns the superclass of the class.
 *
 * @return The superclass of the class
 */
+ (nullable Class)superclass;

/**
 * @brief Checks whether instances of the class respond to a given selector.
 *
 * @param selector The selector which should be checked for respondence
 * @return A boolean whether instances of the class respond to the specified
 *	   selector
 */
+ (bool)instancesRespondToSelector: (SEL)selector;

/**
 * @brief Checks whether the class conforms to a given protocol.
 *
 * @param protocol The protocol which should be checked for conformance
 * @return A boolean whether the class conforms to the specified protocol
 */
+ (bool)conformsToProtocol: (Protocol *)protocol;

/**
 * @brief Returns the implementation of the instance method for the specified
 *	  selector.
 *
 * @param selector The selector for which the method should be returned
 * @return The implementation of the instance method for the specified selector
 *	   or `nil` if it isn't implemented
 */
+ (nullable IMP)instanceMethodForSelector: (SEL)selector;

/**
 * @brief Returns the method signature of the instance method for the specified
 *	  selector.
 *
 * @param selector The selector for which the method signature should be
 *		   returned
 * @return The method signature of the instance method for the specified
 *	   selector
 */
+ (nullable OFMethodSignature *)
    instanceMethodSignatureForSelector: (SEL)selector;

/**
 * @brief Returns a description for the class, which is usually the class name.
 *
 * This is mostly for debugging purposes.
 *
 * @return A description for the class, which is usually the class name
 */
+ (OFString *)description;

/**
 * @brief Replaces a class method with a class method from another class.
 *
 * @param selector The selector of the class method to replace
 * @param class_ The class from which the new class method should be taken
 * @return The old implementation
 */
+ (nullable IMP)replaceClassMethod: (SEL)selector
	       withMethodFromClass: (Class)class_;

/**
 * @brief Replaces an instance method with an instance method from another
 *	  class.
 *
 * @param selector The selector of the instance method to replace
 * @param class_ The class from which the new instance method should be taken
 * @return The old implementation
 */
+ (nullable IMP)replaceInstanceMethod: (SEL)selector
		  withMethodFromClass: (Class)class_;

/**
 * @brief Adds all methods from the specified class to the class that is the
 *	  receiver.
 *
 * Methods implemented by the receiving class itself will not be overridden,
 * however methods implemented by its superclass will. Therefore it behaves
 * similar as if the specified class is the superclass of the receiver.
 *
 * All methods from the superclasses of the specified class will also be added.
 *
 * If the specified class is a superclass of the receiving class, nothing is
 * done.
 *
 * The methods which will be added from the specified class are not allowed to
 * use super or access instance variables, instead they have to use accessors.
 *
 * @param class_ The class from which the instance methods should be inherited
 */
+ (void)inheritMethodsFromClass: (Class)class_;

/**
 * @brief Try to resolve the specified class method.
 *
 * This method is called if a class method was not found, so that an
 * implementation can be provided at runtime.
 *
 * @return Whether the method has been added to the class
 */
+ (bool)resolveClassMethod: (SEL)selector;

/**
 * @brief Try to resolve the specified instance method.
 *
 * This method is called if an instance method was not found, so that an
 * implementation can be provided at runtime.
 *
 * @return Whether the method has been added to the class
 */
+ (bool)resolveInstanceMethod: (SEL)selector;

/**
 * @brief Returns the class.
 *
 * This method exists so that classes can be used in collections requiring
 * conformance to the OFCopying protocol.
 *
 * @return The class of the object
 */
+ (id)copy;

/**
 * @brief Initializes an already allocated object.
 *
 * Derived classes may override this, but need to use the following pattern:
 * @code
 * self = [super init];
 *
 * @try {
 *         // Custom initialization code goes here.
 * } @catch (id e) {
 *         objc_release(self);
 *         @throw e;
 * }
 *
 * return self;
 * @endcode
 *
 * With ARC enabled, the following pattern needs to be used instead:
 * @code
 * self = [super init];
 *
 * // Custom initialization code goes here.
 *
 * return self;
 * @endcode
 *
 * @ref init may never return `nil`, instead an exception (for example
 * @ref OFInitializationFailedException) should be thrown.
 *
 * @return An initialized object
 */
- (instancetype)init;

/**
 * @brief Returns the method signature for the specified selector.
 *
 * @param selector The selector for which the method signature should be
 *		   returned
 * @return The method signature for the specified selector
 */
- (nullable OFMethodSignature *)methodSignatureForSelector: (SEL)selector;

/**
 * @brief Deallocates the object.
 *
 * It is automatically called when the retain count reaches zero.
 *
 * This also frees all memory in its memory pool.
 */
- (void)dealloc;

/**
 * @brief Performs the specified selector after the specified delay.
 *
 * @param selector The selector to perform
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector with the specified object after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector with the specified objects after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector with the specified objects after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector with the specified objects after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     withObject: (nullable id)object4
	     afterDelay: (OFTimeInterval)delay;

#ifdef OF_HAVE_THREADS
/**
 * @brief Performs the specified selector on the specified thread.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	  waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified object.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object
	  waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	  waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	  waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     withObject: (nullable id)object4
	  waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the main thread.
 *
 * @param selector The selector to perform
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
		      waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the main thread with the specified
 *	  object.
 *
 * @param selector The selector to perform
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object
		      waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the main thread with the specified
 *	  objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object1
			 withObject: (nullable id)object2
		      waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the main thread with the specified
 *	  objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object1
			 withObject: (nullable id)object2
			 withObject: (nullable id)object3
		      waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the main thread with the specified
 *	  objects.
 *
 * @param selector The selector to perform
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param waitUntilDone Whether to wait until the perform finished
 */
- (void)performSelectorOnMainThread: (SEL)selector
			 withObject: (nullable id)object1
			 withObject: (nullable id)object2
			 withObject: (nullable id)object3
			 withObject: (nullable id)object4
		      waitUntilDone: (bool)waitUntilDone;

/**
 * @brief Performs the specified selector on the specified thread after the
 *	  specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified object after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object The object that is passed to the method specified by the
 *		 selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     afterDelay: (OFTimeInterval)delay;

/**
 * @brief Performs the specified selector on the specified thread with the
 *	  specified objects after the specified delay.
 *
 * @param selector The selector to perform
 * @param thread The thread on which to perform the selector
 * @param object1 The first object that is passed to the method specified by the
 *		  selector
 * @param object2 The second object that is passed to the method specified by
 *		  the selector
 * @param object3 The third object that is passed to the method specified by the
 *		  selector
 * @param object4 The fourth object that is passed to the method specified by
 *		  the selector
 * @param delay The delay after which the selector will be performed
 */
- (void)performSelector: (SEL)selector
	       onThread: (OFThread *)thread
	     withObject: (nullable id)object1
	     withObject: (nullable id)object2
	     withObject: (nullable id)object3
	     withObject: (nullable id)object4
	     afterDelay: (OFTimeInterval)delay;
#endif

/**
 * @brief This method is called when @ref resolveClassMethod: or
 *	  @ref resolveInstanceMethod: returned false. It should return a target
 *	  to which the message should be forwarded.
 *
 * @note When the message should not be forwarded, you should not return `nil`,
 *	 but instead return the result of `[super
 *	 forwardingTargetForSelector: selector]`.
 *
 * @return The target to forward the message to
 */
- (nullable id)forwardingTargetForSelector: (SEL)selector;

/**
 * @brief Handles messages which are not understood by the receiver.
 *
 * @warning If you override this method, you must make sure that it never
 *	    returns!
 *
 * @param selector The selector not understood by the receiver
 * @throw OFNotImplementedException The method is not implemented
 */
- (void)doesNotRecognizeSelector: (SEL)selector OF_NO_RETURN;
@end

/**
 * @protocol OFCopying OFObject.h ObjFW/ObjFW.h
 *
 * @brief A protocol for the creation of copies.
 */
@protocol OFCopying
/**
 * @brief Copies the object.
 *
 * For classes which can be immutable or mutable, this returns an immutable
 * copy. If only a mutable version of the class exists, it creates a mutable
 * copy.
 *
 * @return A copy of the object
 */
- (id)copy;
@end

/**
 * @protocol OFMutableCopying OFObject.h ObjFW/ObjFW.h
 *
 * @brief A protocol for the creation of mutable copies.
 *
 * This protocol is implemented by objects that can be mutable and immutable
 * and allows returning a mutable copy.
 */
@protocol OFMutableCopying
/**
 * @brief Creates a mutable copy of the object.
 *
 * @return A mutable copy of the object
 */
- (id)mutableCopy;
@end

/**
 * @protocol OFComparing OFObject.h ObjFW/ObjFW.h
 *
 * @brief A protocol for comparing objects.
 *
 * This protocol is implemented by objects that can be compared. Its only
 * method, @ref compare:, should be overridden with a stronger type.
 */
@protocol OFComparing
/**
 * @brief Compares the object to another object.
 *
 * @param object An object to compare the object to
 * @return The result of the comparison
 */
- (OFComparisonResult)compare: (id <OFComparing>)object;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief Allocates memory for the specified number of items of the specified
 *	  size.
 *
 * To free the allocated memory, use @ref OFFreeMemory.
 *
 * @param count The number of items to allocate
 * @param size The size of each item to allocate
 * @return A pointer to the allocated memory. May return NULL if the specified
 *	   size or count is 0.
 * @throw OFOutOfMemoryException The allocation failed due to not enough memory
 * @throw OFOutOfRangeException The requested `count * size` exceeds the
 *				address space
 */
extern void *_Nullable OFAllocMemory(size_t count, size_t size)
    OF_MALLOC_FUNC OF_WARN_UNUSED_RESULT;

/**
 * @brief Allocates memory for the specified number of items of the specified
 *	  size and initializes it with zeros.
 *
 * To free the allocated memory, use @ref OFFreeMemory.
 *
 * @param size The size of each item to allocate
 * @param count The number of items to allocate
 * @return A pointer to the allocated memory. May return NULL if the specified
 *	   size or count is 0.
 * @throw OFOutOfMemoryException The allocation failed due to not enough memory
 * @throw OFOutOfRangeException The requested `count * size` exceeds the
 *				address space
 */
extern void *_Nullable OFAllocZeroedMemory(size_t count, size_t size)
    OF_MALLOC_FUNC OF_WARN_UNUSED_RESULT;

/**
 * @brief Resizes memory to the specified number of items of the specified size.
 *
 * To free the allocated memory, use @ref OFFreeMemory.
 *
 * If the pointer is NULL, this is equivalent to allocating memory.
 * If the size or number of items is 0, this is equivalent to freeing memory.
 *
 * @param pointer A pointer to the already allocated memory
 * @param size The size of each item to resize to
 * @param count The number of items to resize to
 * @return A pointer to the resized memory chunk
 * @throw OFOutOfMemoryException The reallocation failed due to not enough
 *				 memory
 * @throw OFOutOfRangeException The requested `count * size` exceeds the
 *				address space
 */
extern void *_Nullable OFResizeMemory(void *_Nullable pointer, size_t count,
    size_t size) OF_WARN_UNUSED_RESULT;

/**
 * @brief Frees memory allocated by @ref OFAllocMemory, @ref OFAllocZeroedMemory
 *	  or @ref OFResizeMemory.
 *
 * @param pointer A pointer to the memory to free or nil (passing nil does
 *		  nothing)
 */
extern void OFFreeMemory(void *_Nullable pointer);

#ifdef OF_APPLE_RUNTIME
extern void *_Null_unspecified objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void *_Null_unspecified pool);
extern id _Nullable objc_retain(id _Nullable object);
extern id _Nullable objc_retainBlock(id _Nullable block);
extern id _Nullable objc_retainAutorelease(id _Nullable object);
extern void objc_release(id _Nullable object);
extern id _Nullable objc_autorelease(id _Nullable object);
extern id _Nullable objc_autoreleaseReturnValue(id _Nullable object);
extern id _Nullable objc_retainAutoreleaseReturnValue(id _Nullable object);
extern id _Nullable objc_retainAutoreleasedReturnValue(id _Nullable object);
extern id _Nullable objc_storeStrong(id _Nullable *_Nonnull object,
    id _Nullable value);
extern id _Nullable objc_storeWeak(id _Nullable *_Nonnull object,
    id _Nullable value);
extern id _Nullable objc_loadWeakRetained(id _Nullable *_Nonnull object);
extern _Nullable id objc_initWeak(id _Nullable *_Nonnull object,
    id _Nullable value);
extern void objc_destroyWeak(id _Nullable *_Nonnull object);
extern id _Nullable objc_loadWeak(id _Nullable *_Nonnull object);
extern void objc_copyWeak(id _Nullable *_Nonnull dest,
    id _Nullable *_Nonnull src);
extern void objc_moveWeak(id _Nullable *_Nonnull dest,
    id _Nullable *_Nonnull src);
# ifdef OF_DECLARE_CONSTRUCT_INSTANCE
extern id _Nullable objc_constructInstance(Class _Nullable class_,
    void *_Nullable bytes);
extern void *_Nullable objc_destructInstance(id _Nullable object);
# endif
# ifdef OF_DECLARE_SET_ASSOCIATED_OBJECT
typedef enum objc_associationPolicy {
	OBJC_ASSOCIATION_ASSIGN	= 0,
	OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
	OBJC_ASSOCIATION_RETAIN = OBJC_ASSOCIATION_RETAIN_NONATOMIC | 0x300,
	OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
	OBJC_ASSOCIATION_COPY = OBJC_ASSOCIATION_COPY_NONATOMIC | 0x300
} objc_associationPolicy;
extern void objc_setAssociatedObject(id _Nonnull object,
    const void *_Nonnull key, id _Nullable value,
    objc_associationPolicy policy);
extern id _Nullable objc_getAssociatedObject(id _Nonnull object,
    const void *_Nonnull key);
extern void objc_removeAssociatedObjects(id _Nonnull object);
# endif
#endif

/**
 * @brief Allocates a new object.
 *
 * This is useful to override @ref OFObject#alloc in a subclass that can then
 * allocate extra memory in the same memory allocation.
 *
 * @param class_ The class of which to allocate an object
 * @param extraSize Extra space after the ivars to allocate
 * @param extraAlignment Alignment of the extra space after the ivars
 * @param extra A pointer to set to a pointer to the extra space
 * @return The allocated object
 */
extern id OFAllocObject(Class class_, size_t extraSize, size_t extraAlignment,
    void *_Nullable *_Nullable extra);

/**
 * @brief This function is called when a method is not found.
 *
 * It can also be called intentionally to indicate that a method is not
 * implemetned, for example in an abstract method. However, instead of calling
 * OFMethodNotFound directly, it is preferred to do the following:
 *
 *     - (void)abstractMethod
 *     {
 *     	OF_UNRECOGNIZED_SELECTOR
 *     }
 *
 * However, do not use this for init methods. Instead, use the following:
 *
 *     - (instancetype)init
 *     {
 *     	OF_INVALID_INIT_METHOD
 *     }
 *
 * @param self The object which does not have the method
 * @param _cmd The selector of the method that does not exist
 */
extern void OF_NO_RETURN_FUNC OFMethodNotFound(id self, SEL _cmd);

/**
 * @brief Initializes the specified hash.
 *
 * @param hash A pointer to the hash to initialize
 */
extern void OFHashInit(unsigned long *_Nonnull hash);

/**
 * @brief Returns 16 bit or non-cryptographical randomness.
 *
 * @return 16 bit or non-cryptographical randomness
 */
extern uint16_t OFRandom16(void);

/**
 * @brief Returns 32 bit or non-cryptographical randomness.
 *
 * @return 32 bit or non-cryptographical randomness
 */
extern uint32_t OFRandom32(void);

/**
 * @brief Returns 64 bit or non-cryptographical randomness.
 *
 * @return 64 bit or non-cryptographical randomness
 */
extern uint64_t OFRandom64(void);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END

#import "OFBlock.h"
#import "OFObject+KeyValueCoding.h"
