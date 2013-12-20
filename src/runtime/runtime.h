/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdint.h>
#include <stdbool.h>

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

#if __has_attribute(objc_root_class)
# define OBJC_ROOT_CLASS __attribute__((objc_root_class))
#else
# define OBJC_ROOT_CLASS
#endif

#define Nil (Class)0
#define nil (id)0
#define YES (BOOL)1
#define NO  (BOOL)0

typedef struct objc_class* Class;
typedef struct objc_object* id;
typedef const struct objc_selector* SEL;
typedef signed char BOOL;
typedef id (*IMP)(id, SEL, ...);
typedef void (*objc_uncaught_exception_handler)(id);

struct objc_class {
	Class isa;
	Class superclass;
	const char *name;
	unsigned long version;
	unsigned long info;
	long instance_size;
	struct objc_ivar_list *ivars;
	struct objc_method_list *methodlist;
	struct objc_sparsearray *dtable;
	Class *subclass_list;
	void *sibling_class;
	struct objc_protocol_list *protocols;
	void *gc_object_type;
	unsigned long abi_version;
	int32_t **ivar_offsets;
	struct objc_property_list *properties;
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
	Class isa;
};

struct objc_selector {
	uintptr_t uid;
	const char *types;
};

struct objc_super {
	OBJC_UNSAFE_UNRETAINED id self;
	Class cls;
};

struct objc_method {
	struct objc_selector sel;
	IMP imp;
};

struct objc_method_list {
	struct objc_method_list *next;
	unsigned int count;
	struct objc_method methods[1];
};

struct objc_category {
	const char *category_name;
	const char *class_name;
	struct objc_method_list *instance_methods;
	struct objc_method_list *class_methods;
	struct objc_protocol_list *protocols;
};

struct objc_ivar {
	const char *name;
	const char *type;
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

struct objc_property {
	const char *name;
	unsigned char attributes;
	BOOL synthesized;
	struct {
		const char *name;
		const char *type;
	} getter, setter;
};

struct objc_property_list {
	unsigned int count;
	struct objc_property_list *next;
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
	Class isa;
	const char *name;
	struct objc_protocol_list *protocol_list;
	struct objc_abi_method_description_list *instance_methods;
	struct objc_abi_method_description_list *class_methods;
#ifdef __OBJC__
}
@end
#else
} Protocol;
#endif

struct objc_protocol_list {
	struct objc_protocol_list *next;
	long count;
	OBJC_UNSAFE_UNRETAINED Protocol *list[1];
};

#ifdef __cplusplus
extern "C" {
#endif
extern SEL sel_registerName(const char*);
extern const char* sel_getName(SEL);
extern bool sel_isEqual(SEL, SEL);
extern id objc_lookUpClass(const char*);
extern id objc_getClass(const char*);
extern id objc_getRequiredClass(const char*);
extern unsigned int objc_getClassList(Class*, unsigned int);
extern Class* objc_copyClassList(unsigned int*);
extern bool class_isMetaClass(Class);
extern const char* class_getName(Class);
extern Class class_getSuperclass(Class);
extern bool class_isKindOfClass(Class, Class);
extern unsigned long class_getInstanceSize(Class);
extern bool class_respondsToSelector(Class, SEL);
extern bool class_conformsToProtocol(Class, Protocol*);
extern IMP class_getMethodImplementation(Class, SEL);
extern const char* class_getMethodTypeEncoding(Class, SEL);
extern IMP class_replaceMethod(Class, SEL, IMP, const char*);
extern Class object_getClass(id);
extern Class object_setClass(id, Class);
extern const char* object_getClassName(id);
extern const char* protocol_getName(Protocol*);
extern bool protocol_isEqual(Protocol*, Protocol*);
extern bool protocol_conformsToProtocol(Protocol*, Protocol*);
extern void objc_exit(void);
extern objc_uncaught_exception_handler objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler);
extern IMP (*objc_forward_handler)(id, SEL);
extern IMP (*objc_forward_handler_stret)(id, SEL);
extern id objc_autorelease(id);
extern void* objc_autoreleasePoolPush(void);
extern void objc_autoreleasePoolPop(void*);
extern id _objc_rootAutorelease(id);
/* Used by the compiler, but can be called manually. */
extern IMP objc_msg_lookup(id, SEL);
extern IMP objc_msg_lookup_stret(id, SEL);
extern IMP objc_msg_lookup_super(struct objc_super*, SEL);
extern IMP objc_msg_lookup_super_stret(struct objc_super*, SEL);
#ifdef __cplusplus
}
#endif

#undef OBJC_UNSAFE_UNRETAINED
#undef OBJC_ROOT_CLASS

#endif
