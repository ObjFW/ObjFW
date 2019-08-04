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

#include "config.h"

#import "macros.h"
#import "platform.h"

#if !defined(__has_feature) || !__has_feature(nullability)
# ifndef _Nonnull
#  define _Nonnull
# endif
# ifndef _Nullable
#  define _Nullable
# endif
#endif

struct objc_abi_class {
	struct objc_abi_class *_Nonnull metaclass;
	const char *_Nullable superclass;
	const char *_Nonnull name;
	unsigned long version;
	unsigned long info;
	long instanceSize;
	void *_Nullable iVars;
	struct objc_abi_method_list *_Nullable methodList;
	void *_Nullable DTable;
	void *_Nullable subclassList;
	void *_Nullable siblingClass;
	void *_Nullable protocols;
	void *_Nullable GCObjectType;
	long ABIVersion;
	int32_t *_Nonnull *_Nullable iVarOffsets;
	void *_Nullable properties;
};

struct objc_abi_selector {
	const char *_Nonnull name;
	const char *_Nullable typeEncoding;
};

struct objc_abi_method {
	struct objc_abi_selector selector;
	IMP _Nonnull implementation;
};

struct objc_abi_method_list {
	struct objc_abi_method_list *_Nullable next;
	unsigned int count;
	struct objc_abi_method methods[1];
};

struct objc_abi_category {
	const char *_Nonnull categoryName;
	const char *_Nonnull className;
	struct objc_abi_method_list *_Nullable instanceMethods;
	struct objc_abi_method_list *_Nullable classMethods;
	struct objc_protocol_list *_Nullable protocols;
};

struct objc_abi_static_instances {
	const char *_Nonnull className;
	id _Nullable instances[1];
};

struct objc_abi_symtab {
	unsigned long unknown;
	struct objc_abi_selector *_Nullable selectorRefs;
	uint16_t classDefsCount;
	uint16_t categoryDefsCount;
	void *_Nonnull defs[1];
};

struct objc_abi_module {
	unsigned long version;	/* 9 = non-fragile */
	unsigned long size;
	const char *_Nullable name;
	struct objc_abi_symtab *_Nonnull symtab;
};

struct objc_hashtable_bucket {
	const void *_Nonnull key, *_Nonnull object;
	uint32_t hash;
};

struct objc_hashtable {
	uint32_t (*_Nonnull hash)(const void *_Nonnull key);
	bool (*_Nonnull equal)(const void *_Nonnull key1,
	    const void *_Nonnull key2);
	uint32_t count, size;
	struct objc_hashtable_bucket *_Nonnull *_Nullable data;
};

struct objc_sparsearray {
	struct objc_sparsearray_data {
		void *_Nullable next[256];
	} *_Nonnull data;
	uint8_t indexSize;
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

#if defined(OBJC_COMPILING_AMIGA_LIBRARY) || \
    defined(OBJC_COMPILING_AMIGA_LINKLIB)
struct objc_libc {
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
	int (*_Nonnull vfprintf)(FILE *_Nonnull, const char *_Nonnull, va_list);
	int (*_Nonnull fflush)(FILE *_Nonnull);
	void (*_Nonnull abort)(void);
# ifdef HAVE_SJLJ_EXCEPTIONS
	int (*_Nonnull _Unwind_SjLj_RaiseException)(void *_Nonnull);
# else
	int (*_Nonnull _Unwind_RaiseException)(void *_Nonnull);
# endif
	void (*_Nonnull _Unwind_DeleteException)(void *_Nonnull);
	void *_Nullable (*_Nonnull _Unwind_GetLanguageSpecificData)(
	    void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetRegionStart)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetDataRelBase)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetTextRelBase)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetIP)(void *_Nonnull);
	uintptr_t (*_Nonnull _Unwind_GetGR)(void *_Nonnull, int);
	void (*_Nonnull _Unwind_SetIP)(void *_Nonnull, uintptr_t);
	void (*_Nonnull _Unwind_SetGR)(void *_Nonnull, int, uintptr_t);
# ifdef HAVE_SJLJ_EXCEPTIONS
	void (*_Nonnull _Unwind_SjLj_Resume)(void *_Nonnull);
# else
	void (*_Nonnull _Unwind_Resume)(void *_Nonnull);
# endif
	void (*_Nonnull __register_frame_info)(const void *_Nonnull,
	    void *_Nonnull);
	void *(*_Nonnull __deregister_frame_info)(const void *_Nonnull);
};
#endif

#ifdef OBJC_COMPILING_AMIGA_LIBRARY
# if defined(__MORPHOS__)
#  include <ppcinline/macros.h>
#  define OBJC_M68K_ARG(type, name, reg) type name = (type)REG_##reg;
# else
#  define OBJC_M68K_ARG(type, name, reg)	\
	register type reg_##name __asm__(#reg);	\
	type name = reg_##name;
# endif
# undef stdout
# undef stderr
extern FILE *stdout, *stderr;
#endif

extern void objc_register_all_categories(struct objc_abi_symtab *_Nonnull);
extern struct objc_category *_Nullable *_Nullable
    objc_categories_for_class(Class _Nonnull);
extern void objc_unregister_all_categories(void);
extern void objc_initialize_class(Class _Nonnull);
extern void objc_update_dtable(Class _Nonnull);
extern void objc_register_all_classes(struct objc_abi_symtab *_Nonnull);
extern Class _Nullable objc_classname_to_class(const char *_Nonnull, bool);
extern void objc_unregister_class(Class _Nonnull);
extern void objc_unregister_all_classes(void);
extern uint32_t objc_hash_string(const void *_Nonnull);
extern bool objc_equal_string(const void *_Nonnull, const void *_Nonnull);
extern struct objc_hashtable *_Nonnull objc_hashtable_new(
    uint32_t (*_Nonnull)(const void *_Nonnull),
    bool (*_Nonnull)(const void *_Nonnull, const void *_Nonnull), uint32_t);
extern struct objc_hashtable_bucket objc_deleted_bucket;
extern void objc_hashtable_set(struct objc_hashtable *_Nonnull,
    const void *_Nonnull, const void *_Nonnull);
extern void *_Nullable objc_hashtable_get(struct objc_hashtable *_Nonnull,
    const void *_Nonnull);
extern void objc_hashtable_delete(struct objc_hashtable *_Nonnull,
    const void *_Nonnull);
extern void objc_hashtable_free(struct objc_hashtable *_Nonnull);
extern void objc_register_selector(struct objc_abi_selector *_Nonnull);
extern void objc_register_all_selectors(struct objc_abi_symtab *_Nonnull);
extern void objc_unregister_all_selectors(void);
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
extern void objc_init_static_instances(struct objc_abi_symtab *_Nonnull);
extern void objc_forget_pending_static_instances(void);
#ifdef OF_HAVE_THREADS
extern void objc_global_mutex_lock(void);
extern void objc_global_mutex_unlock(void);
extern void objc_global_mutex_free(void);
#else
# define objc_global_mutex_lock()
# define objc_global_mutex_unlock()
# define objc_global_mutex_free()
#endif

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

#if defined(OF_ELF)
# if defined(OF_X86_64) || defined(OF_X86) || defined(OF_POWERPC) || \
    defined(OF_ARM64) || defined(OF_ARM) || \
    defined(OF_MIPS64_N64) || defined(OF_MIPS) || \
    defined(OF_SPARC64) || defined(OF_SPARC)
#  define OF_ASM_LOOKUP
# endif
#elif defined(OF_MACH_O)
# if defined(OF_X86_64) || defined(OF_POWERPC)
#  define OF_ASM_LOOKUP
# endif
#elif defined(OF_WINDOWS)
# if defined(OF_X86_64) || defined(OF_X86)
#  define OF_ASM_LOOKUP
# endif
#endif

#define OBJC_ERROR(...)							\
	{								\
		fprintf(stderr, "[objc @ " __FILE__ ":%d] ", __LINE__);	\
		fprintf(stderr, __VA_ARGS__);				\
		fprintf(stderr, "\n");					\
		fflush(stderr);						\
		abort();						\
		OF_UNREACHABLE						\
	}

@interface DummyObject
{
	Class _Nonnull isa;
}

+ (void)initialize;
+ (bool)resolveClassMethod: (nonnull SEL)selector;
+ (bool)resolveInstanceMethod: (nonnull SEL)selector;
@end
