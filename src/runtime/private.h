/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "macros.h"

#if !defined(__has_feature) || !__has_feature(nullability)
# ifndef _Nonnull
#  define _Nonnull
# endif
# ifndef _Nullable
#  define _Nullable
# endif
#endif

typedef uint32_t (*_Nonnull objc_hashtable_hash_func)(const void *_Nonnull key);
typedef bool (*_Nonnull objc_hashtable_equal_func)(const void *_Nonnull key1,
    const void *_Nonnull key2);

struct objc_class {
	Class _Nonnull isa;
	Class _Nullable superclass;
	const char *_Nonnull name;
	unsigned long version;
	unsigned long info;
	long instanceSize;
	struct objc_ivar_list *_Nullable ivars;
	struct objc_method_list *_Nullable methodList;
	struct objc_dtable *_Nullable dTable;
	Class _Nullable *_Nullable subclassList;
	void *_Nullable siblingClass;
	struct objc_protocol_list *_Nullable protocols;
	void *_Nullable GCObjectType;
	unsigned long ABIVersion;
	int32_t *_Nonnull *_Nullable ivarOffsets;
	struct objc_property_list *_Nullable propertyList;
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
	struct objc_ivar ivars[1];
};

struct objc_method_description {
	const char *_Nonnull name;
	const char *_Nonnull typeEncoding;
};

struct objc_method_description_list {
	int count;
	struct objc_method_description list[1];
};

struct objc_protocol_list {
	struct objc_protocol_list *_Nullable next;
	long count;
	Protocol *__unsafe_unretained _Nonnull list[1];
};

#if __has_attribute(__objc_root_class__)
__attribute__((__objc_root_class__))
#endif
@interface Protocol
{
@public
	Class _Nonnull isa;
	const char *_Nonnull name;
	struct objc_protocol_list *_Nullable protocolList;
	struct objc_method_description_list *_Nullable instanceMethods;
	struct objc_method_description_list *_Nullable classMethods;
}
@end

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
	OBJC_PROPERTY_SYNTHESIZED	=  0x1,
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

struct objc_static_instances {
	const char *_Nonnull className;
	id _Nullable instances[1];
};

struct objc_symtab {
	unsigned long unknown;
	struct objc_selector *_Nullable selectorRefs;
	uint16_t classDefsCount;
	uint16_t categoryDefsCount;
	void *_Nonnull defs[1];
};

struct objc_module {
	unsigned long version;	/* 9 = non-fragile */
	unsigned long size;
	const char *_Nullable name;
	struct objc_symtab *_Nonnull symtab;
};

struct objc_hashtable_bucket {
	const void *_Nonnull key, *_Nonnull object;
	uint32_t hash;
};

struct objc_hashtable {
	objc_hashtable_hash_func hash;
	objc_hashtable_equal_func equal;
	uint32_t count, size;
	struct objc_hashtable_bucket *_Nonnull *_Nullable data;
};

struct objc_sparsearray {
	struct objc_sparsearray_data {
		void *_Nullable next[256];
	} *_Nonnull data;
	uint8_t levels;
};

struct objc_dtable {
	struct objc_dtable_level2 {
#ifdef OF_SELUID24
		struct objc_dtable_level3 {
			IMP _Nullable buckets[256];
		} *_Nonnull buckets[256];
#else
		IMP _Nullable buckets[256];
#endif
	} *_Nonnull buckets[256];
};

extern void objc_registerAllCategories(struct objc_symtab *_Nonnull);
extern struct objc_category *_Nullable *_Nullable
    objc_categoriesForClass(Class _Nonnull);
extern void objc_unregisterAllCategories(void);
extern void objc_initializeClass(Class _Nonnull);
extern void objc_updateDTable(Class _Nonnull);
extern void objc_registerAllClasses(struct objc_symtab *_Nonnull);
extern Class _Nullable objc_classnameToClass(const char *_Nonnull, bool);
extern void objc_unregisterClass(Class _Nonnull);
extern void objc_unregisterAllClasses(void);
extern uint32_t objc_string_hash(const void *_Nonnull);
extern bool objc_string_equal(const void *_Nonnull, const void *_Nonnull);
extern struct objc_hashtable *_Nonnull objc_hashtable_new(
    objc_hashtable_hash_func, objc_hashtable_equal_func, uint32_t);
extern struct objc_hashtable_bucket objc_deletedBucket;
extern void objc_hashtable_set(struct objc_hashtable *_Nonnull,
    const void *_Nonnull, const void *_Nonnull);
extern void *_Nullable objc_hashtable_get(struct objc_hashtable *_Nonnull,
    const void *_Nonnull);
extern void objc_hashtable_delete(struct objc_hashtable *_Nonnull,
    const void *_Nonnull);
extern void objc_hashtable_free(struct objc_hashtable *_Nonnull);
extern void objc_registerSelector(struct objc_selector *_Nonnull);
extern void objc_registerAllSelectors(struct objc_symtab *_Nonnull);
extern void objc_unregisterAllSelectors(void);
extern struct objc_sparsearray *_Nonnull objc_sparsearray_new(uint8_t);
extern void *_Nullable objc_sparsearray_get(struct objc_sparsearray *_Nonnull,
    uintptr_t);
extern void objc_sparsearray_set(struct objc_sparsearray *_Nonnull, uintptr_t,
    void *_Nullable);
extern void objc_sparsearray_free(struct objc_sparsearray *_Nonnull);
extern struct objc_dtable *_Nonnull objc_dtable_new(void);
extern void objc_dtable_copy(struct objc_dtable *_Nonnull,
    struct objc_dtable *_Nonnull);
extern void objc_dtable_set(struct objc_dtable *_Nonnull, uint32_t,
    IMP _Nullable);
extern void objc_dtable_free(struct objc_dtable *_Nonnull);
extern void objc_dtable_cleanup(void);
extern void objc_initStaticInstances(struct objc_symtab *_Nonnull);
extern void objc_forgetPendingStaticInstances(void);
extern void objc_zeroWeakReferences(id _Nonnull);
extern Class _Nullable object_getTaggedPointerClass(id _Nonnull);
#ifdef OF_HAVE_THREADS
extern void objc_globalMutex_lock(void);
extern void objc_globalMutex_unlock(void);
extern void objc_globalMutex_free(void);
#else
# define objc_globalMutex_lock()
# define objc_globalMutex_unlock()
# define objc_globalMutex_free()
#endif
extern char *_Nullable objc_strdup(const char *_Nonnull string);

static inline IMP _Nullable
objc_dtable_get(const struct objc_dtable *_Nonnull dtable, uint32_t idx)
{
#ifdef OF_SELUID24
	uint8_t i = idx >> 16;
	uint8_t j = idx >> 8;
	uint8_t k = idx;

	return dtable->buckets[i]->buckets[j]->buckets[k];
#else
	uint8_t i = idx >> 8;
	uint8_t j = idx;

	return dtable->buckets[i]->buckets[j];
#endif
}

extern void OF_NO_RETURN_FUNC objc_error(const char *_Nonnull title,
    const char *_Nonnull format, ...);
#define OBJC_ERROR(...)							\
	objc_error("ObjFWRT @ " __FILE__ ":" OF_STRINGIFY(__LINE__),	\
	    __VA_ARGS__)

#if defined(OF_ELF)
# if defined(OF_AMD64) || defined(OF_X86) || \
    defined(OF_POWERPC64) || defined(OF_POWERPC) || \
    defined(OF_ARM64) || defined(OF_ARM) || \
    defined(OF_MIPS64_N64) || defined(OF_MIPS) || \
    defined(OF_SPARC64) || defined(OF_SPARC)
#  define OF_ASM_LOOKUP
# endif
#elif defined(OF_WINDOWS)
# if defined(OF_AMD64) || defined(OF_X86)
#  define OF_ASM_LOOKUP
# endif
#endif

@interface DummyObject
{
	Class _Nonnull isa;
}

@property (readonly, nonatomic) bool allowsWeakReference;

+ (void)initialize;
+ (bool)resolveClassMethod: (nonnull SEL)selector;
+ (bool)resolveInstanceMethod: (nonnull SEL)selector;
- (nonnull id)retain;
- (void)release;
- (nonnull id)autorelease;
- (nonnull id)copy;
- (nonnull id)mutableCopy;
- (bool)retainWeakReference;
@end
