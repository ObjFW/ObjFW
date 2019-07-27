/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#define Nil (Class _Null_unspecified)0
#define nil (id _Null_unspecified)0
#define YES true
#define NO  false

typedef struct objc_class *Class;
typedef struct objc_object *id;
typedef const struct objc_selector *SEL;
#if !defined(__wii__) && !defined(__amigaos__)
typedef bool BOOL;
#endif
typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...);
typedef void (*objc_uncaught_exception_handler_t)(id _Nullable);
typedef void (*objc_enumeration_mutation_handler_t)(id _Nonnull);

struct objc_class {
	Class _Nonnull isa;
	Class _Nullable superclass;
	const char *_Nonnull name;
	unsigned long version;
	unsigned long info;
	long instanceSize;
	struct objc_ivar_list *_Nullable iVars;
	struct objc_method_list *_Nullable methodList;
	struct objc_dtable *_Nonnull DTable;
	Class _Nullable *_Nullable subclassList;
	void *_Nullable siblingClass;
	struct objc_protocol_list *_Nullable protocols;
	void *_Nullable GCObjectType;
	unsigned long ABIVersion;
	int32_t *_Nonnull *_Nullable iVarOffsets;
	struct objc_property_list *_Nullable properties;
};

enum objc_class_info {
	OBJC_CLASS_INFO_CLASS	    = 0x001,
	OBJC_CLASS_INFO_METACLASS   = 0x002,
	OBJC_CLASS_INFO_NEW_ABI	    = 0x010,
	OBJC_CLASS_INFO_SETUP	    = 0x100,
	OBJC_CLASS_INFO_LOADED	    = 0x200,
	OBJC_CLASS_INFO_DTABLE	    = 0x400,
	OBJC_CLASS_INFO_INITIALIZED = 0x800
};

struct objc_object {
	Class _Nonnull isa;
};

struct objc_selector {
	uintptr_t UID;
	const char *_Nullable typeEncoding;
};

struct objc_super {
	id __unsafe_unretained _Nullable self;
#ifdef __cplusplus
	Class _Nonnull class_;
#else
	Class _Nonnull class;
#endif
};

struct objc_method {
	struct objc_selector selector;
	IMP _Nonnull implementation;
};

struct objc_method_list {
	struct objc_method_list *_Nullable next;
	unsigned int count;
	struct objc_method methods[1];
};

struct objc_category {
	const char *_Nonnull categoryName;
	const char *_Nonnull className;
	struct objc_method_list *_Nullable instanceMethods;
	struct objc_method_list *_Nullable classMethods;
	struct objc_protocol_list *_Nullable protocols;
};

struct objc_ivar {
	const char *_Nonnull name;
	const char *_Nonnull typeEncoding;
	unsigned int offset;
};

struct objc_ivar_list {
	unsigned int count;
	struct objc_ivar iVars[1];
};

enum objc_property_attributes {
	OBJC_PROPERTY_READONLY	= 0x01,
	OBJC_PROPERTY_GETTER	= 0x02,
	OBJC_PROPERTY_ASSIGN	= 0x04,
	OBJC_PROPERTY_READWRITE	= 0x08,
	OBJC_PROPERTY_RETAIN	= 0x10,
	OBJC_PROPERTY_COPY	= 0x20,
	OBJC_PROPERTY_NONATOMIC	= 0x40,
	OBJC_PROPERTY_SETTER	= 0x80
};

enum objc_property_extended_attributes {
	OBJC_PROPERTY_SYNTHESIZE	=  0x1,
	OBJC_PROPERTY_DYNAMIC		=  0x2,
	OBJC_PROPERTY_PROTOCOL		=  0x3,
	OBJC_PROPERTY_ATOMIC		=  0x4,
	OBJC_PROPERTY_WEAK		=  0x8,
	OBJC_PROPERTY_STRONG		= 0x10,
	OBJC_PROPERTY_UNSAFE_UNRETAINED = 0x20
};

struct objc_property {
	const char *_Nonnull name;
	unsigned char attributes, extendedAttributes;
	struct {
		const char *_Nullable name;
		const char *_Nullable typeEncoding;
	} getter, setter;
};

struct objc_property_list {
	unsigned int count;
	struct objc_property_list *_Nullable next;
	struct objc_property properties[1];
};

struct objc_method_description {
	const char *_Nonnull name;
	const char *_Nonnull typeEncoding;
};

struct objc_method_description_list {
	int count;
	struct objc_method_description list[1];
};

#ifdef __OBJC__
# if __has_attribute(__objc_root_class__)
__attribute__((__objc_root_class__))
# endif
@interface Protocol
{
@public
#else
typedef struct {
#endif
	Class _Nonnull isa;
	const char *_Nonnull name;
	struct objc_protocol_list *_Nullable protocolList;
	struct objc_method_description_list *_Nullable instanceMethods;
	struct objc_method_description_list *_Nullable classMethods;
#ifdef __OBJC__
}
@end
#else
} Protocol;
#endif

struct objc_protocol_list {
	struct objc_protocol_list *_Nullable next;
	long count;
	Protocol *__unsafe_unretained _Nonnull list[1];
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
extern const char *_Nullable class_getMethodTypeEncoding(Class _Nullable class_,
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
extern void objc_exit(void);
extern _Nullable objc_uncaught_exception_handler_t
    objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler_t _Nullable handler);
extern void objc_setForwardHandler(IMP _Nullable forward,
    IMP _Nullable stretForward);
extern void objc_setEnumerationMutationHandler(
    objc_enumeration_mutation_handler_t _Nullable handler);
extern void objc_zero_weak_references(id _Nonnull value);

/*
 * Used by the compiler, but can also be called manually.
 *
 * These declarations are also required to prevent Clang's implicit
 * declarations which include __declspec(dllimport) on Windows.
 */
extern void __objc_exec_class(void *_Nonnull module);
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
