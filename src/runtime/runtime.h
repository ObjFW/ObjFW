/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

typedef struct objc_class *Class;
typedef struct objc_object *id;
typedef const struct objc_selector *SEL;
typedef signed char BOOL;
typedef id (*IMP)(id, SEL, ...);

#ifdef __OBJC__
@interface Protocol
{
@private
	Class isa;
	const char *name;
	struct objc_protocol_list *protocol_list;
	struct objc_abi_method_description_list *instance_methods;
	struct objc_abi_method_description_list *class_methods;
}
@end
#else
typedef const void Protocol;
#endif

struct objc_class {
	Class isa;
	Class superclass;
	const char *name;
	unsigned long version;
	unsigned long info;
	unsigned long instance_size;
	void *ivars;
	struct objc_method_list *methodlist;
	struct objc_sparsearray *dtable;
	Class *subclass_list;
	void *sibling_class;
	struct objc_protocol_list *protocols;
	void *gc_object_type;
	unsigned long abi_version;
	void *ivar_offsets;
	void *properties;
};

struct objc_object {
	Class isa;
};

struct objc_selector {
	uintptr_t uid;
	const char *types;
};

struct objc_super {
	id self;
	Class class;
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

struct objc_protocol_list {
	struct objc_protocol_list *next;
	long count;
	Protocol *list[1];
};

#define Nil (Class)0
#define nil (id)0
#define YES (BOOL)1
#define NO  (BOOL)0

extern SEL sel_registerName(const char*);
extern const char* sel_getName(SEL);
extern BOOL sel_isEqual(SEL, SEL);
extern Class objc_get_class(const char*);
extern Class objc_lookup_class(const char*);
extern const char* class_getName(Class);
extern Class class_getSuperclass(Class);
extern BOOL class_isKindOfClass(Class, Class);
extern unsigned long class_getInstanceSize(Class);
extern BOOL class_respondsToSelector(Class, SEL);
extern BOOL class_conformsToProtocol(Class, Protocol*);
extern IMP class_getMethodImplementation(Class, SEL);
extern IMP class_replaceMethod(Class, SEL, IMP, const char*);
extern const char* objc_get_type_encoding(Class, SEL);
extern IMP objc_msg_lookup(id, SEL);
extern IMP objc_msg_lookup_super(struct objc_super*, SEL);
extern void objc_thread_add(void);
extern void objc_thread_remove(void);
extern void objc_exit(void);
#endif
