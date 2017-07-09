/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#ifndef __OBJFW_RUNTIME_H__
#define __OBJFW_RUNTIME_H__

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

#if __has_feature(objc_arc)
# define OBJC_UNSAFE_UNRETAINED __unsafe_unretained
#else
# define OBJC_UNSAFE_UNRETAINED
#endif

#if __has_feature(nullability)
# define OBJC_NONNULL _Nonnull
# define OBJC_NULLABLE _Nullable
#else
# define OBJC_NONNULL
# define OBJC_NULLABLE
#endif

#if __has_attribute(__objc_root_class__)
# define OBJC_ROOT_CLASS __attribute__((__objc_root_class__))
#else
# define OBJC_ROOT_CLASS
#endif

#define Nil (Class)0
#define nil (id)0
#define YES (BOOL)1
#define NO  (BOOL)0

typedef struct objc_class *Class;
typedef struct objc_object *id;
typedef const struct objc_selector *SEL;
typedef signed char BOOL;
typedef id OBJC_NULLABLE (*IMP)(id OBJC_NONNULL, SEL OBJC_NONNULL, ...);
typedef void (*objc_uncaught_exception_handler)(id OBJC_NULLABLE);
typedef void (*objc_enumeration_mutation_handler)(id OBJC_NONNULL);

struct objc_class {
	Class OBJC_NONNULL isa;
	Class OBJC_NULLABLE superclass;
	const char *OBJC_NONNULL name;
	unsigned long version;
	unsigned long info;
	long instance_size;
	struct objc_ivar_list *OBJC_NULLABLE ivars;
	struct objc_method_list *OBJC_NULLABLE methodlist;
	struct objc_dtable *OBJC_NULLABLE dtable;
	Class OBJC_NONNULL *OBJC_NULLABLE subclass_list;
	void *OBJC_NULLABLE sibling_class;
	struct objc_protocol_list *OBJC_NULLABLE protocols;
	void *OBJC_NULLABLE gc_object_type;
	unsigned long abi_version;
	int32_t *OBJC_NONNULL *OBJC_NULLABLE ivar_offsets;
	struct objc_property_list *OBJC_NULLABLE properties;
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
	Class OBJC_NONNULL isa;
};

struct objc_selector {
	uintptr_t uid;
	const char *OBJC_NULLABLE types;
};

struct objc_super {
	id OBJC_UNSAFE_UNRETAINED OBJC_NULLABLE self;
	Class OBJC_NONNULL cls;
};

struct objc_method {
	struct objc_selector sel;
	IMP OBJC_NONNULL imp;
};

struct objc_method_list {
	struct objc_method_list *OBJC_NULLABLE next;
	unsigned int count;
	struct objc_method methods[1];
};

struct objc_category {
	const char *OBJC_NONNULL category_name;
	const char *OBJC_NONNULL class_name;
	struct objc_method_list *OBJC_NULLABLE instance_methods;
	struct objc_method_list *OBJC_NULLABLE class_methods;
	struct objc_protocol_list *OBJC_NULLABLE protocols;
};

struct objc_ivar {
	const char *OBJC_NONNULL name;
	const char *OBJC_NONNULL type;
	unsigned int offset;
};

struct objc_ivar_list {
	unsigned int count;
	struct objc_ivar ivars[1];
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
	const char *OBJC_NONNULL name;
	unsigned char attributes, extended_attributes;
	struct {
		const char *OBJC_NULLABLE name;
		const char *OBJC_NULLABLE type;
	} getter, setter;
};

struct objc_property_list {
	unsigned int count;
	struct objc_property_list *OBJC_NULLABLE next;
	struct objc_property properties[1];
};

#ifdef __OBJC__
OBJC_ROOT_CLASS
@interface Protocol
{
@public
#else
typedef struct {
#endif
	Class OBJC_NONNULL isa;
	const char *OBJC_NONNULL name;
	struct objc_protocol_list *OBJC_NULLABLE protocol_list;
	struct objc_abi_method_description_list *OBJC_NULLABLE instance_methods;
	struct objc_abi_method_description_list *OBJC_NULLABLE class_methods;
#ifdef __OBJC__
}
@end
#else
} Protocol;
#endif

struct objc_protocol_list {
	struct objc_protocol_list *OBJC_NULLABLE next;
	long count;
	Protocol *OBJC_UNSAFE_UNRETAINED OBJC_NONNULL list[1];
};

#ifdef __cplusplus
extern "C" {
#endif
extern SEL OBJC_NONNULL sel_registerName(const char *OBJC_NONNULL);
extern const char *OBJC_NONNULL sel_getName(SEL OBJC_NONNULL);
extern bool sel_isEqual(SEL OBJC_NONNULL, SEL OBJC_NONNULL);
extern Class OBJC_NONNULL objc_allocateClassPair(Class OBJC_NULLABLE,
    const char *OBJC_NONNULL, size_t);
extern void objc_registerClassPair(Class OBJC_NONNULL);
extern id OBJC_NULLABLE objc_lookUpClass(const char *OBJC_NONNULL);
extern id OBJC_NULLABLE objc_getClass(const char *OBJC_NONNULL);
extern id OBJC_NONNULL objc_getRequiredClass(const char *OBJC_NONNULL);
extern unsigned int objc_getClassList(Class OBJC_NONNULL *OBJC_NULLABLE,
    unsigned int);
extern Class OBJC_NONNULL *OBJC_NONNULL objc_copyClassList(
    unsigned int *OBJC_NULLABLE);
extern bool class_isMetaClass(Class OBJC_NULLABLE);
extern const char *OBJC_NONNULL class_getName(Class OBJC_NULLABLE);
extern Class OBJC_NULLABLE class_getSuperclass(Class OBJC_NULLABLE);
extern unsigned long class_getInstanceSize(Class OBJC_NULLABLE);
extern bool class_respondsToSelector(Class OBJC_NULLABLE, SEL OBJC_NONNULL);
extern bool class_conformsToProtocol(Class OBJC_NULLABLE,
    Protocol *OBJC_NONNULL);
extern IMP OBJC_NULLABLE class_getMethodImplementation(Class OBJC_NULLABLE,
    SEL OBJC_NONNULL);
extern IMP OBJC_NULLABLE class_getMethodImplementation_stret(
    Class OBJC_NULLABLE, SEL OBJC_NONNULL);
extern const char *OBJC_NULLABLE class_getMethodTypeEncoding(
    Class OBJC_NULLABLE, SEL OBJC_NONNULL);
extern bool class_addMethod(Class OBJC_NONNULL, SEL OBJC_NONNULL,
    IMP OBJC_NONNULL, const char *OBJC_NULLABLE);
extern IMP OBJC_NULLABLE class_replaceMethod(Class OBJC_NONNULL,
    SEL OBJC_NONNULL, IMP OBJC_NONNULL, const char *OBJC_NULLABLE);
extern Class OBJC_NULLABLE object_getClass(id OBJC_NULLABLE);
extern Class OBJC_NULLABLE object_setClass(id OBJC_NULLABLE,
    Class OBJC_NONNULL);
extern const char *OBJC_NONNULL object_getClassName(id OBJC_NULLABLE);
extern const char *OBJC_NONNULL protocol_getName(Protocol *OBJC_NONNULL);
extern bool protocol_isEqual(Protocol *OBJC_NONNULL, Protocol *OBJC_NONNULL);
extern bool protocol_conformsToProtocol(Protocol *OBJC_NONNULL,
    Protocol *OBJC_NONNULL);
extern void objc_exit(void);
extern OBJC_NULLABLE objc_uncaught_exception_handler
    objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler OBJC_NULLABLE);
extern void objc_setForwardHandler(IMP OBJC_NULLABLE, IMP OBJC_NULLABLE);
extern void objc_zero_weak_references(id OBJC_NONNULL);

/*
 * Used by the compiler, but can also be called manually.
 *
 * These declarations are also required to prevent Clang's implicit
 * declarations which include __declspec(dllimport) on Windows.
 */
struct objc_abi_module;
extern void __objc_exec_class(void *OBJC_NONNULL);
extern IMP OBJC_NONNULL objc_msg_lookup(id OBJC_NULLABLE, SEL OBJC_NONNULL);
extern IMP OBJC_NONNULL objc_msg_lookup_stret(id OBJC_NULLABLE,
    SEL OBJC_NONNULL);
extern IMP OBJC_NONNULL objc_msg_lookup_super(struct objc_super *OBJC_NONNULL,
    SEL OBJC_NONNULL);
extern IMP OBJC_NONNULL objc_msg_lookup_super_stret(
    struct objc_super *OBJC_NONNULL, SEL OBJC_NONNULL);
extern void objc_exception_throw(id OBJC_NULLABLE);
extern int objc_sync_enter(id OBJC_NULLABLE);
extern int objc_sync_exit(id OBJC_NULLABLE);
extern id OBJC_NULLABLE objc_getProperty(id OBJC_NONNULL, SEL OBJC_NONNULL,
    ptrdiff_t, BOOL);
extern void objc_setProperty(id OBJC_NONNULL, SEL OBJC_NONNULL, ptrdiff_t,
    id OBJC_NULLABLE, BOOL, signed char);
extern void objc_getPropertyStruct(void *OBJC_NONNULL, const void *OBJC_NONNULL,
    ptrdiff_t, BOOL, BOOL);
extern void objc_setPropertyStruct(void *OBJC_NONNULL, const void *OBJC_NONNULL,
    ptrdiff_t, BOOL, BOOL);
extern void objc_enumerationMutation(id OBJC_NONNULL);
extern void objc_setEnumerationMutationHandler(
    objc_enumeration_mutation_handler OBJC_NULLABLE);
#ifdef __cplusplus
}
#endif

#undef OBJC_NONNULL
#undef OBJC_NULLABLE
#undef OBJC_UNSAFE_UNRETAINED
#undef OBJC_ROOT_CLASS

#endif
