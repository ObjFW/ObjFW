/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

/*!
 * @brief A value representing no class.
 */
#define Nil (Class _Null_unspecified)0

/*!
 * @brief A value representing no object.
 */
#define nil (id _Null_unspecified)0

/*!
 * @brief An Objective-C boolean representing true.
 *
 * @note This is a legacy from before C had a boolean type. Prefer the standard
 *	 C99 true instead!
 */
#define YES true

/*!
 * @brief An Objective-C boolean representing false.
 *
 * @note This is a legacy from before C had a boolean type. Prefer the standard
 *	 C99 false instead!
 */
#define NO false

/*! @file */

/*!
 * @brief A pointer to a class.
 */
typedef struct objc_class *Class;

/*!
 * @brief A pointer to any object.
 */
typedef struct objc_object *id;

/*!
 * @brief A selector.
 *
 * A selector is the name of a method including the colons and an optional type
 * encoding.
 */
typedef const struct objc_selector *SEL;

/*!
 * @brief A method.
 *
 * A method consists of a selector with a type encoding and an implementation.
 */
typedef const struct objc_method *Method;

/*!
 * @brief A protocol.
 */
#if defined(__OBJC__) && !defined(DOXYGEN)
@class Protocol;
#else
typedef const struct objc_protocol *Protocol;
#endif

/*!
 * @brief An instance variable.
 */
typedef const struct objc_ivar *Ivar;

/*!
 * @brief A property.
 */
typedef const struct objc_property *objc_property_t;

#if !defined(__wii__) && !defined(__amigaos__)
/*!
 * @brief An Objective-C boolean. Either @ref YES or @ref NO.
 *
 * @note This is a legacy from before C had a boolean type. Prefer the standard
 *	 C99 bool instead!
 */
typedef bool BOOL;
#endif

/*!
 * @brief A method implemenation.
 *
 * @param object The messaged object
 * @param selector The selector sent
 */
typedef id _Nullable (*IMP)(id _Nonnull object, SEL _Nonnull selector, ...);

/*!
 * @brief A handler for uncaught exceptions.
 *
 * @param exception The exception which was not caught.
 */
typedef void (*objc_uncaught_exception_handler_t)(id _Nullable exception);

/*!
 * @brief A handler for mutation during enumeration.
 *
 * @param object The object that was mutated during enumeration
 */
typedef void (*objc_enumeration_mutation_handler_t)(id _Nonnull object);

/*!
 * @brief A struct representing a call to super.
 */
struct objc_super {
	/*!
	 * @brief The object on which to perform the super call.
	 */
	id __unsafe_unretained _Nullable self;
	/*!
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
extern SEL _Nonnull sel_registerName(const char *_Nonnull name);
extern const char *_Nonnull sel_getName(SEL _Nonnull selector);
extern bool sel_isEqual(SEL _Nonnull selector1, SEL _Nonnull selector2);
extern Class _Nonnull objc_allocateClassPair(Class _Nullable superclass,
    const char *_Nonnull name, size_t extraBytes);
extern void objc_registerClassPair(Class _Nonnull class_);
extern unsigned int objc_getClassList(Class _Nonnull *_Nullable buffer,
    unsigned int count);
extern Class _Nonnull *_Nonnull objc_copyClassList(
    unsigned int *_Nullable length);
extern bool class_isMetaClass(Class _Nullable class_);
extern const char *_Nullable class_getName(Class _Nullable class_);
extern Class _Nullable class_getSuperclass(Class _Nullable class_);
extern unsigned long class_getInstanceSize(Class _Nullable class_);
extern bool class_respondsToSelector(Class _Nullable class_,
    SEL _Nonnull selector);
extern bool class_conformsToProtocol(Class _Nullable class_,
    Protocol *_Nonnull protocol);
extern IMP _Nullable class_getMethodImplementation(Class _Nullable class_,
    SEL _Nonnull selector);
extern IMP _Nullable class_getMethodImplementation_stret(Class _Nullable class_,
    SEL _Nonnull selector);
extern Method _Nullable class_getInstanceMethod(Class _Nullable class_,
    SEL _Nonnull selector);
extern bool class_addMethod(Class _Nonnull class_, SEL _Nonnull selector,
    IMP _Nonnull implementation, const char *_Nullable typeEncoding);
extern IMP _Nullable class_replaceMethod(Class _Nonnull class_,
    SEL _Nonnull selector, IMP _Nonnull implementation,
    const char *_Nullable typeEncoding);
extern Class _Nullable object_getClass(id _Nullable object);
extern Class _Nullable object_setClass(id _Nullable object,
    Class _Nonnull class_);
extern const char *_Nullable object_getClassName(id _Nullable object);
extern const char *_Nonnull protocol_getName(Protocol *_Nonnull protocol);
extern bool protocol_isEqual(Protocol *_Nonnull protocol1,
    Protocol *_Nonnull protocol2);
extern bool protocol_conformsToProtocol(Protocol *_Nonnull protocol1,
    Protocol *_Nonnull protocol2);
extern Method _Nullable *_Nullable class_copyMethodList(Class _Nullable class_,
    unsigned int *_Nullable outCount);
extern SEL _Nonnull method_getName(Method _Nonnull method);
extern const char *_Nullable method_getTypeEncoding(Method _Nonnull method);
extern Ivar _Nullable *_Nullable class_copyIvarList(Class _Nullable class_,
    unsigned int *_Nullable outCount);
extern const char *_Nonnull ivar_getName(Ivar _Nonnull ivar);
extern const char *_Nonnull ivar_getTypeEncoding(Ivar _Nonnull ivar);
extern ptrdiff_t ivar_getOffset(Ivar _Nonnull ivar);
extern objc_property_t _Nullable *_Nullable class_copyPropertyList(
    Class _Nullable class_, unsigned int *_Nullable outCount);
extern const char *_Nonnull property_getName(objc_property_t _Nonnull property);
extern char *_Nullable property_copyAttributeValue(
    objc_property_t _Nonnull property, const char *_Nonnull name);
extern void objc_exit(void);
extern _Nullable objc_uncaught_exception_handler_t
    objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler_t _Nullable handler);
extern void objc_setForwardHandler(IMP _Nullable forward,
    IMP _Nullable stretForward);
extern void objc_setEnumerationMutationHandler(
    objc_enumeration_mutation_handler_t _Nullable handler);
extern id _Nullable objc_constructInstance(Class _Nullable class_,
    void *_Nullable bytes);
extern void *_Nullable objc_destructInstance(id _Nullable object);
extern void *_Null_unspecified objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void *_Null_unspecified pool);
extern id _Nullable _objc_rootAutorelease(id _Nullable object);
extern int_fast8_t objc_registerTaggedPointerClass(Class _Nonnull class);
extern Class _Nullable object_getTaggedPointerClass(id _Nonnull object);
extern uintptr_t object_getTaggedPointerValue(id _Nonnull object);
extern id _Nullable objc_createTaggedPointer(uint_fast8_t class,
    uintptr_t value);

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
