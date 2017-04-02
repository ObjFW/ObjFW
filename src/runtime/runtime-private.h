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

#include "config.h"

#include "platform.h"

struct objc_abi_class {
	struct objc_abi_class *metaclass;
	const char *superclass;
	const char *name;
	unsigned long version;
	unsigned long info;
	long instance_size;
	void *ivars;
	struct objc_abi_method_list *methodlist;
	void *dtable;
	void *subclass_list;
	void *sibling_class;
	void *protocols;
	void *gc_object_type;
	long abi_version;
	int32_t **ivar_offsets;
	void *properties;
};

struct objc_abi_method {
	const char *name;
	const char *types;
	IMP imp;
};

struct objc_abi_method_list {
	struct objc_abi_method_list *next;
	unsigned int count;
	struct objc_abi_method methods[1];
};

struct objc_abi_selector {
	const char *name;
	const char *types;
};

struct objc_abi_category {
	const char *category_name;
	const char *class_name;
	struct objc_abi_method_list *instance_methods;
	struct objc_abi_method_list *class_methods;
	struct objc_protocol_list *protocols;
};

struct objc_abi_method_description {
	const char *name;
	const char *types;
};

struct objc_abi_method_description_list {
	int count;
	struct objc_abi_method_description list[1];
};

struct objc_abi_static_instances {
	const char *class_name;
	id instances[1];
};

struct objc_abi_symtab {
	unsigned long unknown;
	struct objc_abi_selector *sel_refs;
	uint16_t cls_def_cnt;
	uint16_t cat_def_cnt;
	void *defs[1];
};

struct objc_abi_module {
	unsigned long version;	/* 9 = non-fragile */
	unsigned long size;
	const char *name;
	struct objc_abi_symtab *symtab;
};

struct objc_hashtable_bucket {
	const void *key, *obj;
	uint32_t hash;
};

struct objc_hashtable {
	uint32_t (*hash)(const void *key);
	bool (*equal)(const void *key1, const void *key2);
	uint32_t count, size;
	struct objc_hashtable_bucket **data;
};

struct objc_sparsearray {
	struct objc_sparsearray_data {
		void *next[256];
	} *data;
	uint8_t index_size;
};

struct objc_dtable {
	struct objc_dtable_level2 {
#ifdef OF_SELUID24
		struct objc_dtable_level3 {
			IMP buckets[256];
		} *buckets[256];
#else
		IMP buckets[256];
#endif
	} *buckets[256];
};

extern void objc_register_all_categories(struct objc_abi_symtab*);
extern struct objc_category** objc_categories_for_class(Class);
extern void objc_unregister_all_categories(void);
extern void objc_initialize_class(Class);
extern void objc_update_dtable(Class);
extern void objc_register_all_classes(struct objc_abi_symtab*);
extern Class objc_classname_to_class(const char*, bool);
extern void objc_unregister_class(Class);
extern void objc_unregister_all_classes(void);
extern uint32_t objc_hash_string(const void*);
extern bool objc_equal_string(const void*, const void*);
extern struct objc_hashtable* objc_hashtable_new(uint32_t (*)(const void*),
    bool (*)(const void*, const void*), uint32_t);
extern struct objc_hashtable_bucket objc_deleted_bucket;
extern void objc_hashtable_set(struct objc_hashtable*, const void*,
    const void*);
extern void* objc_hashtable_get(struct objc_hashtable*, const void*);
extern void objc_hashtable_delete(struct objc_hashtable*, const void*);
extern void objc_hashtable_free(struct objc_hashtable*);
extern void objc_register_selector(struct objc_abi_selector*);
extern void objc_register_all_selectors(struct objc_abi_symtab*);
extern void objc_unregister_all_selectors(void);
extern struct objc_sparsearray* objc_sparsearray_new(uint8_t);
extern void* objc_sparsearray_get(struct objc_sparsearray*, uintptr_t);
extern void objc_sparsearray_set(struct objc_sparsearray*, uintptr_t, void*);
extern void objc_sparsearray_free(struct objc_sparsearray*);
extern struct objc_dtable* objc_dtable_new(void);
extern void objc_dtable_copy(struct objc_dtable*, struct objc_dtable*);
extern void objc_dtable_set(struct objc_dtable*, uint32_t, IMP);
extern void objc_dtable_free(struct objc_dtable*);
extern void objc_dtable_cleanup(void);
extern void objc_init_static_instances(struct objc_abi_symtab*);
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

static inline IMP
objc_dtable_get(const struct objc_dtable *dtable, uint32_t idx)
{
#ifdef OF_SELUID24
	uint8_t i = idx >> 16;
	uint8_t j = idx >>  8;
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
	}
