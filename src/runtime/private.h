/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
	long instance_size;
	void *_Nullable ivars;
	struct objc_abi_method_list *_Nullable methodlist;
	void *_Nullable dtable;
	void *_Nullable subclass_list;
	void *_Nullable sibling_class;
	void *_Nullable protocols;
	void *_Nullable gc_object_type;
	long abi_version;
	int32_t *_Nonnull *_Nullable ivar_offsets;
	void *_Nullable properties;
};

struct objc_abi_selector {
	const char *_Nonnull name;
	const char *_Nullable types;
};

struct objc_abi_method {
	struct objc_abi_selector sel;
	IMP _Nonnull imp;
};

struct objc_abi_method_list {
	struct objc_abi_method_list *_Nullable next;
	unsigned int count;
	struct objc_abi_method methods[1];
};

struct objc_abi_category {
	const char *_Nonnull category_name;
	const char *_Nonnull class_name;
	struct objc_abi_method_list *_Nullable instance_methods;
	struct objc_abi_method_list *_Nullable class_methods;
	struct objc_protocol_list *_Nullable protocols;
};

struct objc_abi_method_description {
	const char *_Nonnull name;
	const char *_Nonnull types;
};

struct objc_abi_method_description_list {
	int count;
	struct objc_abi_method_description list[1];
};

struct objc_abi_static_instances {
	const char *_Nonnull class_name;
	id _Nullable instances[1];
};

struct objc_abi_symtab {
	unsigned long unknown;
	struct objc_abi_selector *_Nullable sel_refs;
	uint16_t cls_def_cnt;
	uint16_t cat_def_cnt;
	void *_Nonnull defs[1];
};

struct objc_abi_module {
	unsigned long version;	/* 9 = non-fragile */
	unsigned long size;
	const char *_Nullable name;
	struct objc_abi_symtab *_Nonnull symtab;
};

struct objc_hashtable_bucket {
	const void *_Nonnull key, *_Nonnull obj;
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
	uint8_t index_size;
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
extern struct objc_libc {
	void *(*malloc)(size_t);
	void *(*calloc)(size_t, size_t);
	void *(*realloc)(void *, size_t);
	void (*free)(void *);
	int (*vfprintf)(FILE *, const char *, va_list);
	int (*fputs)(const char *, FILE *);
	void (*exit)(int);
	void (*abort)(void);
	FILE *stdout_;
	FILE *stderr_;
} *objc_libc;
#endif

#ifdef OBJC_COMPILING_AMIGA_LIBRARY
# undef stdout
# undef stderr
extern FILE *stdout, *stderr;

extern void glue___objc_exec_class(void *_Nonnull module OBJC_M68K_REG("a0"));
extern IMP _Nonnull glue_objc_msg_lookup(id _Nullable obj OBJC_M68K_REG("a0"),
    SEL _Nonnull sel OBJC_M68K_REG("a1"));
extern IMP _Nonnull glue_objc_msg_lookup_stret(
    id _Nullable obj OBJC_M68K_REG("a0"), SEL _Nonnull sel OBJC_M68K_REG("a1"));
extern IMP _Nonnull glue_objc_msg_lookup_super(
    struct objc_super *_Nonnull super OBJC_M68K_REG("a0"),
    SEL _Nonnull sel OBJC_M68K_REG("a1"));
extern IMP _Nonnull glue_objc_msg_lookup_super_stret(
    struct objc_super *_Nonnull super OBJC_M68K_REG("a0"),
    SEL _Nonnull sel OBJC_M68K_REG("a1"));
extern id _Nullable glue_objc_lookUpClass(
    const char *_Nonnull name OBJC_M68K_REG("a0"));
extern id _Nullable glue_objc_getClass(
    const char *_Nonnull name OBJC_M68K_REG("a0"));
extern id _Nonnull glue_objc_getRequiredClass(
    const char *_Nonnull name OBJC_M68K_REG("a0"));
extern Class _Nullable glue_objc_lookup_class(
    const char *_Nonnull name OBJC_M68K_REG("a0"));
extern Class _Nonnull glue_objc_get_class(
    const char *_Nonnull name OBJC_M68K_REG("a0"));
extern void glue_objc_exception_throw(id _Nullable object OBJC_M68K_REG("a0"));
extern int glue_objc_sync_enter(id _Nullable object OBJC_M68K_REG("a0"));
extern int glue_objc_sync_exit(id _Nullable object OBJC_M68K_REG("a0"));
extern id _Nullable glue_objc_getProperty(id _Nonnull self OBJC_M68K_REG("a0"),
    SEL _Nonnull _cmd OBJC_M68K_REG("a1"), ptrdiff_t offset OBJC_M68K_REG("d0"),
    bool atomic OBJC_M68K_REG("d1"));
extern void glue_objc_setProperty(id _Nonnull self OBJC_M68K_REG("a0"),
    SEL _Nonnull _cmd OBJC_M68K_REG("a1"), ptrdiff_t offset OBJC_M68K_REG("d0"),
    id _Nullable value OBJC_M68K_REG("a2"), bool atomic OBJC_M68K_REG("d1"),
    signed char copy OBJC_M68K_REG("d2"));
extern void glue_objc_getPropertyStruct(void *_Nonnull dest OBJC_M68K_REG("a0"),
    const void *_Nonnull src OBJC_M68K_REG("a1"),
    ptrdiff_t size OBJC_M68K_REG("d0"), bool atomic OBJC_M68K_REG("d1"),
    bool strong OBJC_M68K_REG("d2"));
extern void glue_objc_setPropertyStruct(void *_Nonnull dest OBJC_M68K_REG("a0"),
    const void *_Nonnull src OBJC_M68K_REG("a1"),
    ptrdiff_t size OBJC_M68K_REG("d0"), bool atomic OBJC_M68K_REG("d1"),
    bool strong OBJC_M68K_REG("d2"));
extern void glue_objc_enumerationMutation(id _Nonnull obj OBJC_M68K_REG("a0"));
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
		fputs("\n", stderr);					\
		abort();						\
		OF_UNREACHABLE						\
	}
