/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "macros.h"

#if !defined(__has_feature) || !__has_feature(nullability)
# ifndef _Nonnull
#  define _Nonnull
# endif
# ifndef _Nullable
#  define _Nullable
# endif
#endif

typedef uint32_t (*_Nonnull objc_hashtable_hash_func)(
    const void *_Nonnull key);
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

enum _objc_class_info {
	_OBJC_CLASS_INFO_CLASS       = 0x0001,
	_OBJC_CLASS_INFO_METACLASS   = 0x0002,
	_OBJC_CLASS_INFO_NEW_ABI     = 0x0010,
	_OBJC_CLASS_INFO_SETUP       = 0x0100,
	_OBJC_CLASS_INFO_LOADED      = 0x0200,
	_OBJC_CLASS_INFO_DTABLE      = 0x0400,
	_OBJC_CLASS_INFO_INITIALIZED = 0x0800,
	_OBJC_CLASS_INFO_RUNTIME_RR  = 0x1000
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

enum _objc_property_attributes {
	_OBJC_PROPERTY_READONLY  = 0x01,
	_OBJC_PROPERTY_GETTER    = 0x02,
	_OBJC_PROPERTY_ASSIGN    = 0x04,
	_OBJC_PROPERTY_READWRITE = 0x08,
	_OBJC_PROPERTY_RETAIN    = 0x10,
	_OBJC_PROPERTY_COPY      = 0x20,
	_OBJC_PROPERTY_NONATOMIC = 0x40,
	_OBJC_PROPERTY_SETTER    = 0x80
};

enum _objc_property_extended_attributes {
	_OBJC_PROPERTY_SYNTHESIZED       =  0x1,
	_OBJC_PROPERTY_DYNAMIC           =  0x2,
	_OBJC_PROPERTY_PROTOCOL          =  0x3,
	_OBJC_PROPERTY_ATOMIC            =  0x4,
	_OBJC_PROPERTY_WEAK              =  0x8,
	_OBJC_PROPERTY_STRONG            = 0x10,
	_OBJC_PROPERTY_UNSAFE_UNRETAINED = 0x20
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

#if defined(OBJC_COMPILING_AMIGA_LIBRARY) || \
    defined(OBJC_COMPILING_AMIGA_LINKLIB)
struct objc_linklib_context {
	unsigned int version;
	void *_Nullable (*_Nonnull malloc)(size_t);
	void *_Nullable (*_Nonnull calloc)(size_t, size_t);
	void *_Nullable (*_Nonnull realloc)(void *_Nullable, size_t);
	void (*_Nonnull free)(void *_Nullable);
# ifdef OF_MORPHOS
	int (*_Nonnull _Unwind_RaiseException)(void *_Nonnull);
# else
	int (*_Nonnull _Unwind_SjLj_RaiseException)(void *_Nonnull);
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
# ifdef OF_MORPHOS
	void (*_Nonnull _Unwind_Resume)(void *_Nonnull);
	void (*_Nonnull __register_frame)(void *_Nonnull);
	void (*_Nonnull __deregister_frame)(void *_Nonnull);
# else
	void (*_Nonnull _Unwind_SjLj_Resume)(void *_Nonnull);
	void (*_Nonnull __register_frame_info)(const void *_Nonnull,
	    void *_Nonnull);
	void *(*_Nonnull __deregister_frame_info)(const void *_Nonnull);
# endif
	int (*_Nonnull atexit)(void (*_Nonnull)(void));
	void (*_Nonnull exit)(int);
# ifdef OF_AMIGAOS_M68K
	int (*_Nonnull vsnprintf)(char *restrict _Nonnull str, size_t size,
	    const char *_Nonnull restrict fmt, va_list args);
# endif
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
#endif

extern void _objc_registerAllCategories(struct objc_symtab *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern struct objc_category *_Nullable *_Nullable
    _objc_categoriesForClass(Class _Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_processCategoriesLoadQueue(void) OF_VISIBILITY_INTERNAL;
extern void _objc_unregisterAllCategories(void) OF_VISIBILITY_INTERNAL;
extern void _objc_initializeClass(Class _Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_updateDTable(Class _Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_registerAllClasses(struct objc_symtab *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern Class _Nullable _objc_classnameToClass(const char *_Nonnull, bool)
    OF_VISIBILITY_INTERNAL;
extern void _objc_unregisterClass(Class _Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_unregisterAllClasses(void) OF_VISIBILITY_INTERNAL;
extern uint32_t _objc_string_hash(const void *_Nonnull) OF_VISIBILITY_INTERNAL;
extern bool _objc_string_equal(const void *_Nonnull, const void *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern struct objc_hashtable *_Nonnull _objc_hashtable_new(
    objc_hashtable_hash_func, objc_hashtable_equal_func, uint32_t)
    OF_VISIBILITY_INTERNAL;
extern struct objc_hashtable_bucket _objc_deletedBucket OF_VISIBILITY_INTERNAL;
extern void _objc_hashtable_set(struct objc_hashtable *_Nonnull,
    const void *_Nonnull, const void *_Nonnull) OF_VISIBILITY_INTERNAL;
extern void *_Nullable _objc_hashtable_get(struct objc_hashtable *_Nonnull,
    const void *_Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_hashtable_delete(struct objc_hashtable *_Nonnull,
    const void *_Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_hashtable_free(struct objc_hashtable *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern void _objc_registerSelector(struct objc_selector *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern void _objc_registerAllSelectors(struct objc_symtab *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern void _objc_unregisterAllSelectors(void) OF_VISIBILITY_INTERNAL;
extern struct objc_sparsearray *_Nonnull _objc_sparsearray_new(uint8_t)
    OF_VISIBILITY_INTERNAL;
extern void *_Nullable _objc_sparsearray_get(struct objc_sparsearray *_Nonnull,
    uintptr_t) OF_VISIBILITY_INTERNAL;
extern void _objc_sparsearray_set(struct objc_sparsearray *_Nonnull, uintptr_t,
    void *_Nullable) OF_VISIBILITY_INTERNAL;
extern void _objc_sparsearray_free(struct objc_sparsearray *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern struct objc_dtable *_Nonnull _objc_dtable_new(void)
    OF_VISIBILITY_INTERNAL;
extern void _objc_dtable_copy(struct objc_dtable *_Nonnull,
    struct objc_dtable *_Nonnull) OF_VISIBILITY_INTERNAL;
extern void _objc_dtable_set(struct objc_dtable *_Nonnull, uint32_t,
    IMP _Nullable) OF_VISIBILITY_INTERNAL;
extern void _objc_dtable_free(struct objc_dtable *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern void _objc_dtable_cleanup(void) OF_VISIBILITY_INTERNAL;
extern void _objc_initStaticInstances(struct objc_symtab *_Nonnull)
    OF_VISIBILITY_INTERNAL;
extern void _objc_forgetPendingStaticInstances(void) OF_VISIBILITY_INTERNAL;
extern void _objc_zeroWeakReferences(id _Nonnull) OF_VISIBILITY_INTERNAL;
extern Class _Nullable _object_getTaggedPointerClass(id _Nonnull)
    OF_VISIBILITY_INTERNAL;
#ifdef OF_HAVE_THREADS
extern void _objc_globalMutex_lock(void) OF_VISIBILITY_INTERNAL;
extern void _objc_globalMutex_unlock(void) OF_VISIBILITY_INTERNAL;
extern void _objc_globalMutex_free(void) OF_VISIBILITY_INTERNAL;
#else
# define _objc_globalMutex_lock()
# define _objc_globalMutex_unlock()
# define _objc_globalMutex_free()
#endif
extern char *_Nullable _objc_strdup(const char *_Nonnull string)
    OF_VISIBILITY_INTERNAL;

static OF_INLINE IMP _Nullable
_objc_dtable_get(const struct objc_dtable *_Nonnull dtable, uint32_t idx)
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

extern void OF_NO_RETURN_FUNC _objc_error(const char *_Nonnull title,
    const char *_Nonnull format, ...) OF_VISIBILITY_INTERNAL;
#define _OBJC_ERROR(...)						\
	_objc_error("ObjFWRT @ " __FILE__ ":" OF_STRINGIFY(__LINE__),	\
	    __VA_ARGS__)

#if defined(OF_ELF)
# if defined(OF_AMD64) || defined(OF_X86) || \
    defined(OF_POWERPC64) || defined(OF_POWERPC) || \
    defined(OF_ARM64) || defined(OF_ARM) || \
    defined(OF_MIPS64_N64) || defined(OF_MIPS) || \
    defined(OF_SPARC64) || defined(OF_SPARC) || \
    defined(OF_RISCV64) || defined(OF_LOONGARCH64)
#  define OF_ASM_LOOKUP
# endif
#elif defined(OF_MACH_O)
# if defined(OF_AMD64)
#  define OF_ASM_LOOKUP
# endif
#elif defined(OF_WINDOWS)
# if defined(OF_AMD64) || defined(OF_X86) || defined(OF_ARM64)
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
- (void)dealloc;
- (nonnull id)autorelease;
- (nonnull id)copy;
- (nonnull id)mutableCopy;
- (bool)retainWeakReference;
- (void)_usesRuntimeRR;
@end
