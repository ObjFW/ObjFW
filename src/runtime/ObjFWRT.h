/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#ifndef OBJFWRT_OBJFWRT_H
#define OBJFWRT_OBJFWRT_H

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/** @file */

#ifndef __has_feature
# define __has_feature(x) 0
#endif

#ifndef __has_attribute
# define __has_attribute(x) 0
#endif

#if !__has_feature(nullability)
# ifndef _Nonnull
#  define _Nonnull
# endif
# ifndef _Nullable
#  define _Nullable
# endif
# ifndef _Null_unspecified
#  define _Null_unspecified
# endif
#endif

#if !__has_feature(objc_arc) && !defined(__unsafe_unretained)
# define __unsafe_unretained
#endif

/**
 * @brief A value representing no class.
 */
#define Nil (Class _Null_unspecified)0

/**
 * @brief A value representing no object.
 */
#define nil (id _Null_unspecified)0

/**
 * @brief An Objective-C boolean representing true.
 *
 * @note This is a legacy from before C had a boolean type. Prefer the standard
 *	 C99 true instead!
 */
#define YES true

/**
 * @brief An Objective-C boolean representing false.
 *
 * @note This is a legacy from before C had a boolean type. Prefer the standard
 *	 C99 false instead!
 */
#define NO false

/**
 * @brief A pointer to a class.
 */
typedef struct objc_class *Class;

/**
 * @brief A pointer to any object.
 */
typedef struct objc_object *id;

/**
 * @brief A selector.
 *
 * A selector is the name of a method including the colons and an optional type
 * encoding.
 */
typedef const struct objc_selector *SEL;

/**
 * @brief A method.
 *
 * A method consists of a selector with a type encoding and an implementation.
 */
typedef const struct objc_method *Method;

/**
 * @brief A protocol.
 */
#if defined(__OBJC__) && !defined(DOXYGEN)
@class Protocol;
#else
typedef const struct objc_protocol *Protocol;
#endif

/**
 * @brief An instance variable.
 */
typedef const struct objc_ivar *Ivar;

/**
 * @brief A property.
 */
typedef const struct objc_property *objc_property_t;

#if !defined(__wii__) && !defined(__amigaos__)
/**
 * @brief An Objective-C boolean. Either @ref YES or @ref NO.
 *
 * @note This is a legacy from before C had a boolean type. Prefer the standard
 *	 C99 bool instead!
 */
typedef bool BOOL;
#endif

/**
 * @brief A method implemenation.
 *
 * @param object The messaged object
 * @param selector The selector sent
 */
typedef id _Nullable (*IMP)(id _Nonnull object, SEL _Nonnull selector, ...);

/**
 * @brief A handler for uncaught exceptions.
 *
 * @param exception The exception which was not caught.
 */
typedef void (*objc_uncaught_exception_handler)(id _Nullable exception);

/**
 * @brief A handler for mutation during enumeration.
 *
 * @param object The object that was mutated during enumeration
 */
typedef void (*objc_enumeration_mutation_handler)(id _Nonnull object);

/**
 * @brief A struct representing a call to super.
 */
struct objc_super {
	/**
	 * @brief The object on which to perform the super call.
	 */
	id __unsafe_unretained _Nullable self;
	/**
	 * @brief The class from which to take the method.
	 */
#ifdef __cplusplus
	Class _Nonnull class_;
#else
	Class _Nonnull class;
#endif
};

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Registers a selector with the specified name with the runtime.
 *
 * @param name The name for the selector to register
 * @return The registered selector
 */
extern SEL _Nonnull sel_registerName(const char *_Nonnull name);

/**
 * @brief Returns the name of the specified selector.
 *
 * @param selector The selector whose name should be returned
 * @return The name of the specified selector
 */
extern const char *_Nonnull sel_getName(SEL _Nonnull selector);

/**
 * @brief Checks two selectors for equality.
 *
 * Selectors are considered equal if they have the same name - any type
 * encoding is ignored.
 *
 * @param selector1 The first selector
 * @param selector2 The second selector
 * @return Whether the two selectors are equal
 */
extern bool sel_isEqual(SEL _Nonnull selector1, SEL _Nonnull selector2);

/**
 * @brief Allocates a new class and its metaclass.
 *
 * @param superclass The superclass for the new class
 * @param name The name for the new class
 * @param extraBytes Extra bytes to add to the instance size
 * @return A new, unregistered class pair
 */
extern Class _Nonnull objc_allocateClassPair(Class _Nullable superclass,
    const char *_Nonnull name, size_t extraBytes);

/**
 * @brief Registers an already allocated class pair.
 *
 * @param class_ The class pair to register
 */
extern void objc_registerClassPair(Class _Nonnull class_);

/**
 * @brief Gets the list of all classes known to the runtime.
 *
 * @param buffer An array of Class to write to. If the buffer does not have
 *		 enough space, the result is truncated.
 * @param count The number of classes for which there is space in `buffer`
 * @return The number of classes written
 */
extern unsigned int objc_getClassList(Class _Nonnull *_Nullable buffer,
    unsigned int count);

/**
 * @brief Copies the list of all classes known to the runtime.
 *
 * This is like @ref objc_getClassList, but allocates a buffer large enough for
 * all classes.
 *
 * @param length An optional pointer to an `unsigned int` that will be set to
 *		 the number of classes returned
 * @return An array of classes, terminated by `Nil`. You need to call `free()`
 *	   on it when done.
 */
extern Class _Nonnull *_Nonnull objc_copyClassList(
    unsigned int *_Nullable length);

/**
 * @brief Returns whether the specified class is a metaclass.
 *
 * @param class_ The class which should be examined
 * @return Whether the specified class is a metaclass
 */
extern bool class_isMetaClass(Class _Nullable class_);

/**
 * @brief Returns the name of the specified class.
 *
 * @param class_ The class whose name should be returned
 * @return The name of the specified class
 */
extern const char *_Nullable class_getName(Class _Nullable class_);

/**
 * @brief Returns the superclass of the specified class.
 *
 * @param class_ The class whose superclass should be returned
 * @return The superclass of the specified class
 */
extern Class _Nullable class_getSuperclass(Class _Nullable class_);

/**
 * @brief Returns the instance size of the specified class.
 *
 * @param class_ The class whose instance size should be returned
 * @return The instance size of the specified class
 */
extern unsigned long class_getInstanceSize(Class _Nullable class_);

/**
 * @brief Returns whether the specified class responds to the specified
 *	  selector.
 *
 * @param class_ The class which should be examined
 * @param selector The selector which should be checked
 * @return Whether the specified class responds to the specified selector
 */
extern bool class_respondsToSelector(Class _Nullable class_,
    SEL _Nonnull selector);

/**
 * @brief Returns whether the specified class conforms to the specified
 *	  protocol.
 *
 * @param class_ The class which should be examined
 * @param protocol The protocol for which conformance should be checked
 * @return Whether the specified class conforms to the specified protocol
 */
extern bool class_conformsToProtocol(Class _Nullable class_,
    Protocol *_Nonnull protocol);

/**
 * @brief Returns the class's method implementation for the specified selector.
 *
 * @warning If the method uses the struct return ABI, you need to use
 *	    @ref class_getMethodImplementation_stret instead! Depending on the
 *	    ABI, small structs might not use the struct return ABI.
 *
 * @param class_ The class whose method implementation should be returned
 * @param selector The selector for the method whose implementation should be
 *		   returned
 * @return The class's metod implementation for the specified selector
 */
extern IMP _Nullable class_getMethodImplementation(Class _Nullable class_,
    SEL _Nonnull selector);

/**
 * @brief Returns the class's method implementation for the specified selector.
 *
 * @warning If the method does not use use the struct return ABI, you need to
 *	    use @ref class_getMethodImplementation instead! Depending on the
 *	    ABI, small structs might not use the struct return ABI.
 *
 * @param class_ The class whose method implementation should be returned
 * @param selector The selector for the method whose implementation should be
 *		   returned
 * @return The class's metod implementation for the specified selector
 */
extern IMP _Nullable class_getMethodImplementation_stret(Class _Nullable class_,
    SEL _Nonnull selector);

/**
 * @brief Returns the class's instance method for the specified selector
 *
 * @param class_ The class whose instance method should be returned
 * @param selector The selector of the instance method to return
 * @return The class's instance method for the specified selector
 */
extern Method _Nullable class_getInstanceMethod(Class _Nullable class_,
    SEL _Nonnull selector);

/**
 * @brief Adds the specified method to the class.
 *
 * @param class_ The class to which to add the method
 * @param selector The selector for the method to add
 * @param implementation The implementation of the method to add
 * @param typeEncoding The type encoding of the method to add
 * @return Whether the specified method was added
 */
extern bool class_addMethod(Class _Nonnull class_, SEL _Nonnull selector,
    IMP _Nonnull implementation, const char *_Nullable typeEncoding);

/**
 * @brief Replaces or adds the specified method of the class.
 *
 * @param class_ The class to which to replace the method
 * @param selector The selector for the method to replace
 * @param implementation The implementation of the method to replace
 * @param typeEncoding The type encoding of the method to replace. Only used if
 *		       the method does not exist yet.
 * @return The old implementation of the method
 */
extern IMP _Nullable class_replaceMethod(Class _Nonnull class_,
    SEL _Nonnull selector, IMP _Nonnull implementation,
    const char *_Nullable typeEncoding);

/**
 * @brief Returns the object's class.
 *
 * @param object The object whose class should be returned
 * @return The object's class
 */
extern Class _Nullable object_getClass(id _Nullable object);

/**
 * @brief Sets the object's class.
 *
 * This can be used to swizzle an object's class.
 *
 * @param object The object whose class should be set
 * @param class_ The new class for the object
 * @return The old class of the object
 */
extern Class _Nullable object_setClass(id _Nullable object,
    Class _Nonnull class_);

/**
 * @brief Returns the object's class name.
 *
 * @param object The object whose class name should be returned
 * @return The object's class name
 */
extern const char *_Nullable object_getClassName(id _Nullable object);

/**
 * @brief Returns the name of the specified protocol.
 *
 * @param protocol The protocol whose name should be returned
 * @return The name of the specified protocol
 */
extern const char *_Nonnull protocol_getName(Protocol *_Nonnull protocol);

/**
 * @brief Returns whether two protocols are equal.
 *
 * @param protocol1 The first protocol
 * @param protocol2 The second protocol
 * @return Whether the two protocols are equal
 */
extern bool protocol_isEqual(Protocol *_Nonnull protocol1,
    Protocol *_Nonnull protocol2);

/**
 * @brief Returns whether the first protocol conforms to the second protocol.
 *
 * @param protocol1 The first protocol
 * @param protocol2 The second protocol
 * @return Whether the first protocol conforms to the second protocol
 */
extern bool protocol_conformsToProtocol(Protocol *_Nonnull protocol1,
    Protocol *_Nonnull protocol2);

/**
 * @brief Copies the method list of the specified class.
 *
 * @param class_ The class whose method list should be copied
 * @param outCount An optional pointer to an `unsigned int` that should be set
 *		   to the number of methods returned
 * @return An array of methods, terminated by `NULL`. You need to call `free()`
 *	   on it when done.
 */
extern Method _Nullable *_Nullable class_copyMethodList(Class _Nullable class_,
    unsigned int *_Nullable outCount);

/**
 * @brief Returns the name of the specified method.
 *
 * @param method The method whose name should be returned
 * @return The name of the specified method
 */
extern SEL _Nonnull method_getName(Method _Nonnull method);

/**
 * @brief Returns the type encoding of the specified method.
 *
 * @param method The method whose type encoding should be returned
 * @return The type encoding of the specified method
 */
extern const char *_Nullable method_getTypeEncoding(Method _Nonnull method);

/**
 * @brief Copies the instance variable list of the specified class.
 *
 * @param class_ The class whose instance variable list should be copied
 * @param outCount An optional pointer to an `unsigned int` that should be set
 *		   to the number of instance variables returned
 * @return An array of instance variables, terminated by `NULL`. You need to
 *	   call `free()` on it when done.
 */
extern Ivar _Nullable *_Nullable class_copyIvarList(Class _Nullable class_,
    unsigned int *_Nullable outCount);

/**
 * @brief Returns the name of the specified instance variable.
 *
 * @param ivar The instance variable whose name should be returned
 * @return The name of the specified instance variable
 */
extern const char *_Nonnull ivar_getName(Ivar _Nonnull ivar);

/**
 * @brief Returns the type encoding of the specified instance variable.
 *
 * @param ivar The instance variable whose type encoding should be returned
 * @return The type encoding of the specified instance variable
 */
extern const char *_Nonnull ivar_getTypeEncoding(Ivar _Nonnull ivar);

/**
 * @brief Returns the offset of the specified instance variable.
 *
 * @param ivar The instance variable whose offset should be returned
 * @return The offset of the specified instance variable
 */
extern ptrdiff_t ivar_getOffset(Ivar _Nonnull ivar);

/**
 * @brief Copies the property list of the specified class.
 *
 * @param class_ The class whose property list should be copied
 * @param outCount An optional pointer to an `unsigned int` that should be set
 *		   to the number of properties returned
 * @return An array of properties, terminated by `NULL`. You need to call
 *	   `free()` on it when done.
 */
extern objc_property_t _Nullable *_Nullable class_copyPropertyList(
    Class _Nullable class_, unsigned int *_Nullable outCount);

/**
 * @brief Returns the name of the specified property.
 *
 * @param property The property whose name should be returned
 * @return The name of the specified property
 */
extern const char *_Nonnull property_getName(objc_property_t _Nonnull property);

/**
 * @brief Copies the specified attribute value.
 *
 * @param property The property whose attribute value should be copied
 * @param name The name of the attribute value to copy
 * @return A copy of the attribute value. You need to call `free()` on it when
 *	   done.
 */
extern char *_Nullable property_copyAttributeValue(
    objc_property_t _Nonnull property, const char *_Nonnull name);

/**
 * @brief Deinitializes the Objective-C runtime.
 *
 * This frees all data structures used by the runtime, after which Objective-C
 * can no longer be used inside the current process. This is only useful for
 * debugging and tests.
 */
extern void objc_deinit(void);

/**
 * @brief Sets the handler for uncaught exceptions.
 *
 * @param handler The new handler for uncaught exceptions
 * @return The old handler for uncaught exceptions
 */
extern _Nullable objc_uncaught_exception_handler
    objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler _Nullable handler);

/**
 * @brief Sets the forwarding handler for unimplemented methods.
 *
 * @param forward The forwarding handler for regular methods
 * @param stretForward The forwarding handler for methods using the struct
 *		       return ABI
 */
extern void objc_setForwardHandler(IMP _Nullable forward,
    IMP _Nullable stretForward);

/**
 * @brief Sets the handler for mutations during enumeration.
 *
 * @param handler The handler for mutations during enumeration
 */
extern void objc_setEnumerationMutationHandler(
    objc_enumeration_mutation_handler _Nullable handler);

/**
 * @brief Constructs an instance of the specified class in the specified array
 *	  of bytes.
 *
 * @param class_ The class of which to construct an instance
 * @param bytes An array of bytes of at least the length of the instance size.
 *		Must be properly aligned for the class.
 * @return The constructed instance
 */
extern id _Nullable objc_constructInstance(Class _Nullable class_,
    void *_Nullable bytes);

/**
 * @brief Destructs the specified object.
 *
 * @param object The object to destruct
 * @return The array of bytes that was used to back the instance
 */
extern void *_Nullable objc_destructInstance(id _Nullable object);

/**
 * @brief Creates a new autorelease pool and puts it on top of the stack of
 *	  autorelease pools.
 *
 * @return A new autorelease pool, which is now on the top of the stack of
 *	   autorelease pools
 */
extern void *_Null_unspecified objc_autoreleasePoolPush(void);

/**
 * @brief Drains the specified autorelease pool and all pools on top of it and
 *	  removes it from the stack of autorelease pools.
 *
 * @param pool The pool which should be drained together with all pools on top
 *	       of it
 */
extern void objc_autoreleasePoolPop(void *_Null_unspecified pool);

/**
 * @brief Adds the specified object to the topmost autorelease pool.
 *
 * This is only to be used to implement the `autorelease` method in a root
 * class.
 *
 * @param object The object to add to the topmost autorelease pool
 * @return The autoreleased object
 */
extern id _Nullable _objc_rootAutorelease(id _Nullable object);

/**
 * @brief Sets the tagged pointer secret.
 *
 * @param secret A secret, random value that will be used to XOR all tagged
 *		 pointers with
 */
extern void objc_setTaggedPointerSecret(uintptr_t secret);

/**
 * @brief Registers a class for tagged pointers.
 *
 * @param class The class to register for tagged pointers
 * @return The tagged pointer ID for the registered class
 */
extern int objc_registerTaggedPointerClass(Class _Nonnull class);

/**
 * @brief Returns whether the specified object is a tagged pointer.
 *
 * @param object The object to inspect
 * @return Whether the specified object is a tagged pointer
 */
extern bool object_isTaggedPointer(id _Nullable object);

/**
 * @brief Returns the value of the specified tagged pointer.
 *
 * @param object The object whose tagged pointer value should be returned
 * @return The tagged pointer value of the object
 */
extern uintptr_t object_getTaggedPointerValue(id _Nonnull object);

/**
 * @brief Creates a new tagged pointer.
 *
 * @param class The tag ID for the tagged pointer class to use
 * @param value The value the tagged pointer should have
 * @return A tagged pointer, or `nil` if it could not be created
 */
extern id _Nullable objc_createTaggedPointer(int class, uintptr_t value);

/*
 * Used by the compiler, but can also be called manually.
 *
 * These declarations are also required to prevent Clang's implicit
 * declarations which include __declspec(dllimport) on Windows.
 */
struct objc_module;
extern void __objc_exec_class(struct objc_module *_Nonnull module);
extern IMP _Nonnull objc_msg_lookup(id _Nullable object, SEL _Nonnull selector);
extern IMP _Nonnull objc_msg_lookup_stret(id _Nullable object,
    SEL _Nonnull selector);
extern IMP _Nonnull objc_msg_lookup_super(struct objc_super *_Nonnull super,
    SEL _Nonnull selector);
extern IMP _Nonnull objc_msg_lookup_super_stret(
    struct objc_super *_Nonnull super, SEL _Nonnull selector);
extern Class _Nullable objc_lookUpClass(const char *_Nonnull name);
extern Class _Nullable objc_getClass(const char *_Nonnull name);
extern Class _Nonnull objc_getRequiredClass(const char *_Nonnull name);
extern Class _Nullable objc_lookup_class(const char *_Nonnull name);
extern Class _Nonnull objc_get_class(const char *_Nonnull name);
extern void objc_exception_throw(id _Nullable object);
extern int objc_sync_enter(id _Nullable object);
extern int objc_sync_exit(id _Nullable object);
extern id _Nullable objc_getProperty(id _Nonnull self, SEL _Nonnull _cmd,
    ptrdiff_t offset, bool atomic);
extern void objc_setProperty(id _Nonnull self, SEL _Nonnull _cmd,
    ptrdiff_t offset, id _Nullable value, bool atomic, signed char copy);
extern void objc_getPropertyStruct(void *_Nonnull dest,
    const void *_Nonnull src, ptrdiff_t size, bool atomic, bool strong);
extern void objc_setPropertyStruct(void *_Nonnull dest,
    const void *_Nonnull src, ptrdiff_t size, bool atomic, bool strong);
extern void objc_enumerationMutation(id _Nonnull object);
#ifndef OBJC_NO_PERSONALITY_DECLARATION
/*
 * No objfw-defs.h or config.h is available for the installed runtime headers,
 * so we don't know which exceptions we have.
 */
extern int __gnu_objc_personality_v0(int version, int actions,
    uint64_t exClass, void *_Nonnull ex, void *_Nonnull ctx);
extern int __gnu_objc_personality_sj0(int version, int actions,
    uint64_t exClass, void *_Nonnull ex, void *_Nonnull ctx);
#endif
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
#ifdef __cplusplus
}
#endif

#endif
