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

#include "config.h"

#import "ObjFWRT.h"
#import "amiga-library.h"
#import "macros.h"
#import "private.h"

#include <proto/exec.h>

struct ObjFWRTBase;

#import "inline.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#if defined(OF_AMIGAOS_M68K)
# include <stabs.h>
# define SYM(name) __asm__("_" name)
#elif defined(OF_MORPHOS)
# include <constructor.h>
# define SYM(name) __asm__(name)
#endif

#ifdef HAVE_SJLJ_EXCEPTIONS
extern int _Unwind_SjLj_RaiseException(void *);
#else
extern int _Unwind_RaiseException(void *);
#endif
extern void _Unwind_DeleteException(void *);
extern void *_Unwind_GetLanguageSpecificData(void *);
extern uintptr_t _Unwind_GetRegionStart(void *);
extern uintptr_t _Unwind_GetDataRelBase(void *);
extern uintptr_t _Unwind_GetTextRelBase(void *);
extern uintptr_t _Unwind_GetIP(void *);
extern uintptr_t _Unwind_GetGR(void *, int);
extern void _Unwind_SetIP(void *, uintptr_t);
extern void _Unwind_SetGR(void *, int, uintptr_t);
#ifdef HAVE_SJLJ_EXCEPTIONS
extern void _Unwind_SjLj_Resume(void *);
#else
extern void _Unwind_Resume(void *);
#endif
#ifdef OF_AMIGAOS_M68K
extern void __register_frame_info(const void *, void *);
extern void *__deregister_frame_info(const void *);
#endif
#ifdef OF_MORPHOS
extern void __register_frame(void *);
extern void __deregister_frame(void *);
#endif

struct Library *ObjFWRTBase;
void *__objc_class_name_Protocol;

static int *
get_errno(void)
{
	return &errno;
}

static void __attribute__((__used__))
ctor(void)
{
	static bool initialized = false;
	struct objc_libc libc = {
		.malloc = malloc,
		.calloc = calloc,
		.realloc = realloc,
		.free = free,
		.vfprintf = vfprintf,
		.fflush = fflush,
		.abort = abort,
#ifdef HAVE_SJLJ_EXCEPTIONS
		._Unwind_SjLj_RaiseException = _Unwind_SjLj_RaiseException,
#else
		._Unwind_RaiseException = _Unwind_RaiseException,
#endif
		._Unwind_DeleteException = _Unwind_DeleteException,
		._Unwind_GetLanguageSpecificData =
		    _Unwind_GetLanguageSpecificData,
		._Unwind_GetRegionStart = _Unwind_GetRegionStart,
		._Unwind_GetDataRelBase = _Unwind_GetDataRelBase,
		._Unwind_GetTextRelBase = _Unwind_GetTextRelBase,
		._Unwind_GetIP = _Unwind_GetIP,
		._Unwind_GetGR = _Unwind_GetGR,
		._Unwind_SetIP = _Unwind_SetIP,
		._Unwind_SetGR = _Unwind_SetGR,
#ifdef HAVE_SJLJ_EXCEPTIONS
		._Unwind_SjLj_Resume = _Unwind_SjLj_Resume,
#else
		._Unwind_Resume = _Unwind_Resume,
#endif
#ifdef OF_AMIGAOS_M68K
		.__register_frame_info = __register_frame_info,
		.__deregister_frame_info = __deregister_frame_info,
#endif
#ifdef OF_MORPHOS
		.__register_frame = __register_frame,
		.__deregister_frame = __deregister_frame,
#endif
		.get_errno = get_errno,
	};

	if (initialized)
		return;

	if ((ObjFWRTBase = OpenLibrary(OBJFWRT_AMIGA_LIB,
	    OBJFWRT_LIB_MINOR)) == NULL) {
		/*
		 * The linklib is used by objfw(68k).library as well, so we
		 * can't have the compiler optimize this to another function,
		 * hence the use of an unnecessary format specifier.
		 */
		fprintf(stderr, "Failed to open %s!\n", OBJFWRT_AMIGA_LIB);
		abort();
	}

	if (!glue_objc_init(1, &libc, __sF)) {
		/*
		 * The linklib is used by objfw(68k).library as well, so we
		 * can't have the compiler optimize this to another function,
		 * hence the use of an unnecessary format specifier.
		 */
		fprintf(stderr, "Failed to initialize %s!\n",
		    OBJFWRT_AMIGA_LIB);
		abort();
	}

	initialized = true;
}

static void __attribute__((__used__))
dtor(void)
{
	CloseLibrary(ObjFWRTBase);
}

#if defined(OF_AMIGAOS_M68K)
ADD2INIT(ctor, -2);
ADD2EXIT(dtor, -2);
#elif defined(OF_MORPHOS)
CONSTRUCTOR_P(ObjFWRT, 4000)
{
	ctor();

	return 0;
}

DESTRUCTOR_P(ObjFWRT, 4000)
{
	dtor();
}
#endif

void
__objc_exec_class(struct objc_module *module)
{
	/*
	 * The compiler generates constructors that call into this, so it is
	 * possible that we are not set up yet when we get called.
	 */
	ctor();

	glue___objc_exec_class(module);
}

IMP
objc_msg_lookup(id object, SEL selector)
{
	return glue_objc_msg_lookup(object, selector);
}

IMP
objc_msg_lookup_stret(id object, SEL selector)
{
	return glue_objc_msg_lookup_stret(object, selector);
}

IMP
objc_msg_lookup_super(struct objc_super *super, SEL selector)
{
	return glue_objc_msg_lookup_super(super, selector);
}

IMP
objc_msg_lookup_super_stret(struct objc_super *super, SEL selector)
{
	return glue_objc_msg_lookup_super_stret(super, selector);
}

Class
objc_lookUpClass(const char *name)
{
	return glue_objc_lookUpClass(name);
}

Class
objc_getClass(const char *name)
{
	return glue_objc_getClass(name);
}

Class
objc_getRequiredClass(const char *name)
{
	return glue_objc_getRequiredClass(name);
}

Class
objc_lookup_class(const char *name)
{
	return glue_objc_lookup_class(name);
}

Class
objc_get_class(const char *name)
{
	return glue_objc_get_class(name);
}

void
objc_exception_throw(id object)
{
#ifdef OF_AMIGAOS_M68K
	/*
	 * This does not use the glue code to hack around a compiler bug.
	 *
	 * When using the generated inline stubs, the compiler does not emit
	 * any frame information, making the unwind fail. As unwind always
	 * starts from objc_exception_throw(), this means exceptions would
	 * never work. If, however, we're using a function pointer instead of
	 * the inline stub, the compiler does generate a frame and everything
	 * works fine.
	 */
	register void *a6 __asm__("a6") = ObjFWRTBase;
	uintptr_t throw = (((uintptr_t)ObjFWRTBase) - 0x60);
	((void (*)(id __asm__("a0")))throw)(object);
	(void)a6;
#else
	glue_objc_exception_throw(object);
#endif

	OF_UNREACHABLE
}

int
objc_sync_enter(id object)
{
	return glue_objc_sync_enter(object);
}

int
objc_sync_exit(id object)
{
	return glue_objc_sync_exit(object);
}

id
objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, bool atomic)
{
	return glue_objc_getProperty(self, _cmd, offset, atomic);
}

void
objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value, bool atomic,
    signed char copy)
{
	glue_objc_setProperty(self, _cmd, offset, value, atomic, copy);
}

void
objc_getPropertyStruct(void *dest, const void *src, ptrdiff_t size, bool atomic,
    bool strong)
{
	glue_objc_getPropertyStruct(dest, src, size, atomic, strong);
}

void
objc_setPropertyStruct(void *dest, const void *src, ptrdiff_t size, bool atomic,
    bool strong)
{
	glue_objc_setPropertyStruct(dest, src, size, atomic, strong);
}

void
objc_enumerationMutation(id object)
{
#ifdef OF_AMIGAOS_M68K
	/*
	 * This does not use the glue code to hack around a compiler bug.
	 *
	 * When using the generated inline stubs, the compiler does not emit
	 * any frame information, making the unwind fail. As a result
	 * objc_enumerationMutation() might throw an exception that could never
	 * be caught. If, however, we're using a function pointer instead of
	 * the inline stub, the compiler does generate a frame and everything
	 * works fine.
	 */
	register void *a6 __asm__("a6") = ObjFWRTBase;
	uintptr_t enumerationMutation = (((uintptr_t)ObjFWRTBase) - 0x8A);
	((void (*)(id __asm__("a0")))enumerationMutation)(object);
	(void)a6;
#else
	glue_objc_enumerationMutation(object);
#endif

	OF_UNREACHABLE
}

#ifdef HAVE_SJLJ_EXCEPTIONS
int
__gnu_objc_personality_sj0(int version, int actions, uint64_t exClass,
    void *ex, void *ctx)
{
# ifdef OF_AMIGAOS_M68K
	return glue___gnu_objc_personality(version, actions, &exClass, ex, ctx);
# else
	return glue___gnu_objc_personality(version, actions, exClass, ex, ctx);
# endif
}
#else
int
__gnu_objc_personality_v0(int version, int actions, uint64_t exClass,
    void *ex, void *ctx)
{
# ifdef OF_AMIGAOS_M68K
	return glue___gnu_objc_personality(version, actions, &exClass, ex, ctx);
# else
	return glue___gnu_objc_personality(version, actions, exClass, ex, ctx);
# endif
}
#endif

id
objc_retain(id object)
{
	return glue_objc_retain(object);
}

id
objc_retainBlock(id block)
{
	return glue_objc_retainBlock(block);
}

id
objc_retainAutorelease(id object)
{
	return glue_objc_retainAutorelease(object);
}

void
objc_release(id object)
{
	glue_objc_release(object);
}

id
objc_autorelease(id object)
{
	return glue_objc_autorelease(object);
}

id
objc_autoreleaseReturnValue(id object)
{
	return glue_objc_autoreleaseReturnValue(object);
}

id
objc_retainAutoreleaseReturnValue(id object)
{
	return glue_objc_retainAutoreleaseReturnValue(object);
}

id
objc_retainAutoreleasedReturnValue(id object)
{
	return glue_objc_retainAutoreleasedReturnValue(object);
}

id
objc_storeStrong(id *object, id value)
{
	return glue_objc_storeStrong(object, value);
}

id
objc_storeWeak(id *object, id value)
{
	return glue_objc_storeWeak(object, value);
}

id
objc_loadWeakRetained(id *object)
{
	return glue_objc_loadWeakRetained(object);
}

id
objc_initWeak(id *object, id value)
{
	return glue_objc_initWeak(object, value);
}

void
objc_destroyWeak(id *object)
{
	glue_objc_destroyWeak(object);
}

id
objc_loadWeak(id *object)
{
	return glue_objc_loadWeak(object);
}

void
objc_copyWeak(id *dest, id *src)
{
	glue_objc_copyWeak(dest, src);
}

void
objc_moveWeak(id *dest, id *src)
{
	glue_objc_moveWeak(dest, src);
}

SEL
sel_registerName(const char *name)
{
	return glue_sel_registerName(name);
}

const char *
sel_getName(SEL selector)
{
	return glue_sel_getName(selector);
}

bool
sel_isEqual(SEL selector1, SEL selector2)
{
	return glue_sel_isEqual(selector1, selector2);
}

Class
objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
{
	return glue_objc_allocateClassPair(superclass, name, extraBytes);
}

void
objc_registerClassPair(Class class)
{
	glue_objc_registerClassPair(class);
}

unsigned int
objc_getClassList(Class *buffer, unsigned int count)
{
	return glue_objc_getClassList(buffer, count);
}

Class *
objc_copyClassList(unsigned int *length)
{
	return glue_objc_copyClassList(length);
}

bool
class_isMetaClass(Class class)
{
	return glue_class_isMetaClass(class);
}

const char *
class_getName(Class class)
{
	return glue_class_getName(class);
}

Class
class_getSuperclass(Class class)
{
	return glue_class_getSuperclass(class);
}

unsigned long
class_getInstanceSize(Class class)
{
	return glue_class_getInstanceSize(class);
}

bool
class_respondsToSelector(Class class, SEL selector)
{
	return glue_class_respondsToSelector(class, selector);
}

bool
class_conformsToProtocol(Class class, Protocol *protocol)
{
	return glue_class_conformsToProtocol(class, protocol);
}

IMP
class_getMethodImplementation(Class class, SEL selector)
{
	return glue_class_getMethodImplementation(class, selector);
}

IMP
class_getMethodImplementation_stret(Class class, SEL selector)
{
	return glue_class_getMethodImplementation_stret(class, selector);
}

Method
class_getInstanceMethod(Class class, SEL selector)
{
	return glue_class_getInstanceMethod(class, selector);
}

bool
class_addMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	return glue_class_addMethod(class, selector, implementation,
	    typeEncoding);
}

IMP
class_replaceMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	return glue_class_replaceMethod(class, selector, implementation,
	    typeEncoding);
}

Class
object_getClass(id object)
{
	return glue_object_getClass(object);
}

Class
object_setClass(id object, Class class)
{
	return glue_object_setClass(object, class);
}

const char *
object_getClassName(id object)
{
	return glue_object_getClassName(object);
}

const char *
protocol_getName(Protocol *protocol)
{
	return glue_protocol_getName(protocol);
}

bool
protocol_isEqual(Protocol *protocol1, Protocol *protocol2)
{
	return glue_protocol_isEqual(protocol1, protocol2);
}

bool
protocol_conformsToProtocol(Protocol *protocol1, Protocol *protocol2)
{
	return glue_protocol_conformsToProtocol(protocol1, protocol2);
}

objc_uncaught_exception_handler_t
objc_setUncaughtExceptionHandler(objc_uncaught_exception_handler_t handler)
{
	return glue_objc_setUncaughtExceptionHandler(handler);
}

void
objc_setForwardHandler(IMP forward, IMP stretForward)
{
	glue_objc_setForwardHandler(forward, stretForward);
}

void
objc_setEnumerationMutationHandler(objc_enumeration_mutation_handler_t handler)
{
	glue_objc_setEnumerationMutationHandler(handler);
}

id
objc_constructInstance(Class class, void *_Nullable bytes)
{
	return glue_objc_constructInstance(class, bytes);
}

void
objc_exit(void)
{
	glue_objc_exit();
}

Ivar *
class_copyIvarList(Class class, unsigned int *outCount)
{
	return glue_class_copyIvarList(class, outCount);
}

const char *
ivar_getName(Ivar ivar)
{
	return glue_ivar_getName(ivar);
}

const char *
ivar_getTypeEncoding(Ivar ivar)
{
	return glue_ivar_getTypeEncoding(ivar);
}

ptrdiff_t
ivar_getOffset(Ivar ivar)
{
	return glue_ivar_getOffset(ivar);
}

Method *
class_copyMethodList(Class class, unsigned int *outCount)
{
	return glue_class_copyMethodList(class, outCount);
}

SEL
method_getName(Method method)
{
	return glue_method_getName(method);
}

const char *
method_getTypeEncoding(Method method)
{
	return glue_method_getTypeEncoding(method);
}

objc_property_t *
class_copyPropertyList(Class class, unsigned int *outCount)
{
	return glue_class_copyPropertyList(class, outCount);
}

const char *
property_getName(objc_property_t property)
{
	return glue_property_getName(property);
}

char *
property_copyAttributeValue(objc_property_t property, const char *name)
{
	return glue_property_copyAttributeValue(property, name);
}

void *
objc_destructInstance(id object)
{
	return glue_objc_destructInstance(object);
}

void *
objc_autoreleasePoolPush(void)
{
	return glue_objc_autoreleasePoolPush();
}

void
objc_autoreleasePoolPop(void *pool)
{
	glue_objc_autoreleasePoolPop(pool);
}

id
_objc_rootAutorelease(id object)
{
	return glue__objc_rootAutorelease(object);
}

struct objc_hashtable *
objc_hashtable_new(objc_hashtable_hash_func hash,
    objc_hashtable_equal_func equal, uint32_t size)
{
	return glue_objc_hashtable_new(hash, equal, size);
}

void
objc_hashtable_set(struct objc_hashtable *table, const void *key,
    const void *object)
{
	glue_objc_hashtable_set(table, key, object);
}

void *
objc_hashtable_get(struct objc_hashtable *table, const void *key)
{
	return glue_objc_hashtable_get(table, key);
}

void
objc_hashtable_delete(struct objc_hashtable *table, const void *key)
{
	glue_objc_hashtable_delete(table, key);
}

void
objc_hashtable_free(struct objc_hashtable *table)
{
	glue_objc_hashtable_free(table);
}

void
objc_setTaggedPointerSecret(uintptr_t secret)
{
	glue_objc_setTaggedPointerSecret(secret);
}

int
objc_registerTaggedPointerClass(Class class)
{
	return glue_objc_registerTaggedPointerClass(class);
}

bool
object_isTaggedPointer(id object)
{
	return glue_object_isTaggedPointer(object);
}

uintptr_t
object_getTaggedPointerValue(id object)
{
	return glue_object_getTaggedPointerValue(object);
}

id
objc_createTaggedPointer(int class, uintptr_t value)
{
	return glue_objc_createTaggedPointer(class, value);
}
