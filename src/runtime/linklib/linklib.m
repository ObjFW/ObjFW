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

#import "ObjFWRT.h"
#import "private.h"
#import "macros.h"

#include <proto/exec.h>

struct ObjFWRTBase;

#import "inline.h"

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
extern void __register_frame_info(const void *, void *);
extern void __deregister_frame_info(const void *);

struct Library *ObjFWRTBase;
void *__objc_class_name_Protocol;

void linklib___objc_exec_class(void *module) SYM("__objc_exec_class");
IMP linklib_objc_msg_lookup(id object, SEL selector) SYM("objc_msg_lookup");
IMP linklib_objc_msg_lookup_stret(id object, SEL selector)
    SYM("objc_msg_lookup_stret");
IMP linklib_objc_msg_lookup_super(struct objc_super *super, SEL selector)
    SYM("objc_msg_lookup_super");
IMP linklib_objc_msg_lookup_super_stret(struct objc_super *super, SEL selector)
    SYM("objc_msg_lookup_super_stret");
Class linklib_objc_lookUpClass(const char *name) SYM("objc_lookUpClass");
Class linklib_objc_getClass(const char *name) SYM("objc_getClass");
Class linklib_objc_getRequiredClass(const char *name)
    SYM("objc_getRequiredClass");
Class linklib_objc_lookup_class(const char *name) SYM("objc_lookup_class");
Class linklib_objc_get_class(const char *name) SYM("objc_get_class");
void linklib_objc_exception_throw(id object) SYM("objc_exception_throw");
int linklib_objc_sync_enter(id object) SYM("objc_sync_enter");
int linklib_objc_sync_exit(id object) SYM("objc_sync_exit");
id linklib_objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, bool atomic)
    SYM("objc_getProperty");
void linklib_objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value,
    bool atomic, signed char copy) SYM("objc_setProperty");
void linklib_objc_getPropertyStruct(void *dest, const void *src, ptrdiff_t size,
    bool atomic, bool strong) SYM("objc_getPropertyStruct");
void linklib_objc_setPropertyStruct(void *dest, const void *src, ptrdiff_t size,
    bool atomic, bool strong) SYM("objc_setPropertyStruct");
void linklib_objc_enumerationMutation(id object)
    SYM("objc_enumerationMutation");
#ifdef HAVE_SJLJ_EXCEPTIONS
int linklib___gnu_objc_personality_sj0(int version, int actions,
    uint64_t exClass, void *ex, void *ctx) SYM("__gnu_objc_personality_sj0");
#else
int linklib___gnu_objc_personality_v0(int version, int actions,
    uint64_t exClass, void *ex, void *ctx) SYM("__gnu_objc_personality_v0");
#endif
id linklib_objc_retain(id object) SYM("objc_retain");
id linklib_objc_retainBlock(id block) SYM("objc_retainBlock");
id linklib_objc_retainAutorelease(id object) SYM("objc_retainAutorelease");
void linklib_objc_release(id object) SYM("objc_release");
id linklib_objc_autorelease(id object) SYM("objc_autorelease");
id linklib_objc_autoreleaseReturnValue(id object)
    SYM("objc_autoreleaseReturnValue");
id linklib_objc_retainAutoreleaseReturnValue(id object)
    SYM("objc_retainAutoreleaseReturnValue");
id linklib_objc_retainAutoreleasedReturnValue(id object)
    SYM("objc_retainAutoreleasedReturnValue");
id linklib_objc_storeStrong(id *object, id value) SYM("objc_storeStrong");
id linklib_objc_storeWeak(id *object, id value) SYM("objc_storeWeak");
id linklib_objc_loadWeakRetained(id *object) SYM("objc_loadWeakRetained");
id linklib_objc_initWeak(id *object, id value) SYM("objc_initWeak");
void linklib_objc_destroyWeak(id *object) SYM("objc_destroyWeak");
id linklib_objc_loadWeak(id *object) SYM("objc_loadWeak");
void linklib_objc_copyWeak(id *dest, id *src) SYM("objc_copyWeak");
void linklib_objc_moveWeak(id *dest, id *src) SYM("objc_moveWeak");
SEL linklib_sel_registerName(const char *name) SYM("sel_registerName");
const char *linklib_sel_getName(SEL selector) SYM("sel_getName");
bool linklib_sel_isEqual(SEL selector1, SEL selector2) SYM("sel_isEqual");
Class linklib_objc_allocateClassPair(Class superclass, const char *name,
    size_t extraBytes) SYM("objc_allocateClassPair");
void linklib_objc_registerClassPair(Class class) SYM("objc_registerClassPair");
unsigned int linklib_objc_getClassList(Class *buffer, unsigned int count)
    SYM("objc_getClassList");
Class *linklib_objc_copyClassList(unsigned int *length)
    SYM("objc_copyClassList");
bool linklib_class_isMetaClass(Class class) SYM("class_isMetaClass");
const char *linklib_class_getName(Class class) SYM("class_getName");
Class linklib_class_getSuperclass(Class class) SYM("class_getSuperclass");
unsigned long linklib_class_getInstanceSize(Class class)
    SYM("class_getInstanceSize");
bool linklib_class_respondsToSelector(Class class, SEL selector)
    SYM("class_respondsToSelector");
bool linklib_class_conformsToProtocol(Class class, Protocol *protocol)
    SYM("class_conformsToProtocol");
IMP linklib_class_getMethodImplementation(Class class, SEL selector)
    SYM("class_getMethodImplementation");
IMP linklib_class_getMethodImplementation_stret(Class class, SEL selector)
    SYM("class_getMethodImplementation_stret");
const char *linklib_class_getMethodTypeEncoding(Class class, SEL selector)
    SYM("class_getMethodTypeEncoding");
bool linklib_class_addMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding) SYM("class_addMethod");
IMP linklib_class_replaceMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding) SYM("class_replaceMethod");
Class linklib_object_getClass(id object) SYM("object_getClass");
Class linklib_object_setClass(id object, Class class) SYM("object_setClass");
const char *linklib_object_getClassName(id object)
    SYM("object_getClassName");
const char *linklib_protocol_getName(Protocol *protocol)
    SYM("protocol_getName");
bool linklib_protocol_isEqual(Protocol *protocol1, Protocol *protocol2)
    SYM("protocol_isEqual");
bool linklib_protocol_conformsToProtocol(Protocol *protocol1,
    Protocol *protocol2) SYM("protocol_conformsToProtocol");
void linklib_objc_exit(void) SYM("objc_exit");
objc_uncaught_exception_handler_t linklib_objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler_t handler)
    SYM("objc_setUncaughtExceptionHandler");
void linklib_objc_setForwardHandler(IMP forward, IMP stretForward)
    SYM("objc_setForwardHandler");
void linklib_objc_setEnumerationMutationHandler(
    objc_enumeration_mutation_handler_t handler)
    SYM("objc_setEnumerationMutationHandler");
void linklib_objc_zero_weak_references(id value)
    SYM("objc_zero_weak_references");

static void
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
		.__register_frame_info = __register_frame_info,
		.__deregister_frame_info = __deregister_frame_info,
	};

	if (initialized)
		return;

	if ((ObjFWRTBase = OpenLibrary(OBJFWRT_AMIGA_LIB,
	    OBJFWRT_LIB_MINOR)) == NULL) {
		fputs("Failed to open " OBJFWRT_AMIGA_LIB "!\n", stderr);
		abort();
	}

	if (!objc_init(1, &libc, stdout, stderr)) {
		fputs("Failed to initialize " OBJFWRT_AMIGA_LIB "!\n", stderr);
		abort();
	}

	initialized = true;
}

static void __attribute__((__unused__))
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
linklib___objc_exec_class(void *module)
{
	/*
	 * The compiler generates constructors that call into this, so it is
	 * possible that we are not set up yet when we get called.
	 */
	ctor();

	__objc_exec_class(module);
}

IMP
linklib_objc_msg_lookup(id object, SEL selector)
{
	return objc_msg_lookup(object, selector);
}

IMP
linklib_objc_msg_lookup_stret(id object, SEL selector)
{
	return objc_msg_lookup_stret(object, selector);
}

IMP
linklib_objc_msg_lookup_super(struct objc_super *super, SEL selector)
{
	return objc_msg_lookup_super(super, selector);
}

IMP
linklib_objc_msg_lookup_super_stret(struct objc_super *super, SEL selector)
{
	return objc_msg_lookup_super_stret(super, selector);
}

Class
linklib_objc_lookUpClass(const char *name)
{
	return objc_lookUpClass(name);
}

Class
linklib_objc_getClass(const char *name)
{
	return objc_getClass(name);
}

Class
linklib_objc_getRequiredClass(const char *name)
{
	return objc_getRequiredClass(name);
}

Class
linklib_objc_lookup_class(const char *name)
{
	return objc_lookup_class(name);
}

Class
linklib_objc_get_class(const char *name)
{
	return objc_get_class(name);
}

void
linklib_objc_exception_throw(id object)
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
	objc_exception_throw(object);
#endif

	OF_UNREACHABLE
}

int
linklib_objc_sync_enter(id object)
{
	return objc_sync_enter(object);
}

int
linklib_objc_sync_exit(id object)
{
	return objc_sync_exit(object);
}

id
linklib_objc_getProperty(id self, SEL _cmd, ptrdiff_t offset, bool atomic)
{
	return objc_getProperty(self, _cmd, offset, atomic);
}

void
linklib_objc_setProperty(id self, SEL _cmd, ptrdiff_t offset, id value,
    bool atomic, signed char copy)
{
	objc_setProperty(self, _cmd, offset, value, atomic, copy);
}

void
linklib_objc_getPropertyStruct(void *dest, const void *src, ptrdiff_t size,
    bool atomic, bool strong)
{
	objc_getPropertyStruct(dest, src, size, atomic, strong);
}

void
linklib_objc_setPropertyStruct(void *dest, const void *src, ptrdiff_t size,
    bool atomic, bool strong)
{
	objc_setPropertyStruct(dest, src, size, atomic, strong);
}

void
linklib_objc_enumerationMutation(id object)
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
	objc_enumerationMutation(object);
#endif

	OF_UNREACHABLE
}

#ifdef HAVE_SJLJ_EXCEPTIONS
int
linklib___gnu_objc_personality_sj0(int version, int actions, uint64_t exClass,
    void *ex, void *ctx)
{
	return __gnu_objc_personality_sj0(version, actions, &exClass, ex, ctx);
}
#else
int
linklib___gnu_objc_personality_v0(int version, int actions, uint64_t exClass,
    void *ex, void *ctx)
{
	return __gnu_objc_personality_v0(version, actions, &exClass, ex, ctx);
}
#endif

id
linklib_objc_retain(id object)
{
	return objc_retain(object);
}

id
linklib_objc_retainBlock(id block)
{
	return objc_retainBlock(block);
}

id
linklib_objc_retainAutorelease(id object)
{
	return objc_retainAutorelease(object);
}

void
linklib_objc_release(id object)
{
	objc_release(object);
}

id
linklib_objc_autorelease(id object)
{
	return objc_autorelease(object);
}

id
linklib_objc_autoreleaseReturnValue(id object)
{
	return objc_autoreleaseReturnValue(object);
}

id
linklib_objc_retainAutoreleaseReturnValue(id object)
{
	return objc_retainAutoreleaseReturnValue(object);
}

id
linklib_objc_retainAutoreleasedReturnValue(id object)
{
	return objc_retainAutoreleasedReturnValue(object);
}

id
linklib_objc_storeStrong(id *object, id value)
{
	return objc_storeStrong(object, value);
}

id
linklib_objc_storeWeak(id *object, id value)
{
	return objc_storeWeak(object, value);
}

id
linklib_objc_loadWeakRetained(id *object)
{
	return objc_loadWeakRetained(object);
}

id
linklib_objc_initWeak(id *object, id value)
{
	return objc_initWeak(object, value);
}

void
linklib_objc_destroyWeak(id *object)
{
	objc_destroyWeak(object);
}

id
linklib_objc_loadWeak(id *object)
{
	return objc_loadWeak(object);
}

void
linklib_objc_copyWeak(id *dest, id *src)
{
	objc_copyWeak(dest, src);
}

void
linklib_objc_moveWeak(id *dest, id *src)
{
	objc_moveWeak(dest, src);
}

SEL
linklib_sel_registerName(const char *name)
{
	return sel_registerName(name);
}

const char *
linklib_sel_getName(SEL selector)
{
	return sel_getName(selector);
}

bool
linklib_sel_isEqual(SEL selector1, SEL selector2)
{
	return sel_isEqual(selector1, selector2);
}

Class
linklib_objc_allocateClassPair(Class superclass, const char *name,
    size_t extraBytes)
{
	return objc_allocateClassPair(superclass, name, extraBytes);
}

void
linklib_objc_registerClassPair(Class class)
{
	objc_registerClassPair(class);
}

unsigned int
linklib_objc_getClassList(Class *buffer, unsigned int count)
{
	return objc_getClassList(buffer, count);
}

Class *
linklib_objc_copyClassList(unsigned int *length)
{
	return objc_copyClassList(length);
}

bool
linklib_class_isMetaClass(Class class)
{
	return class_isMetaClass(class);
}

const char *
linklib_class_getName(Class class)
{
	return class_getName(class);
}

Class
linklib_class_getSuperclass(Class class)
{
	return class_getSuperclass(class);
}

unsigned long
linklib_class_getInstanceSize(Class class)
{
	return class_getInstanceSize(class);
}

bool
linklib_class_respondsToSelector(Class class, SEL selector)
{
	return class_respondsToSelector(class, selector);
}

bool
linklib_class_conformsToProtocol(Class class, Protocol *protocol)
{
	return class_conformsToProtocol(class, protocol);
}

IMP
linklib_class_getMethodImplementation(Class class, SEL selector)
{
	return class_getMethodImplementation(class, selector);
}

IMP
linklib_class_getMethodImplementation_stret(Class class, SEL selector)
{
	return class_getMethodImplementation_stret(class, selector);
}

const char *
linklib_class_getMethodTypeEncoding(Class class, SEL selector)
{
	return class_getMethodTypeEncoding(class, selector);
}

bool
linklib_class_addMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	return class_addMethod(class, selector, implementation, typeEncoding);
}

IMP
linklib_class_replaceMethod(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	return class_replaceMethod(class, selector, implementation,
	    typeEncoding);
}

Class
linklib_object_getClass(id object)
{
	return object_getClass(object);
}

Class
linklib_object_setClass(id object, Class class)
{
	return object_setClass(object, class);
}

const char *
linklib_object_getClassName(id object)
{
	return object_getClassName(object);
}

const char *
linklib_protocol_getName(Protocol *protocol)
{
	return protocol_getName(protocol);
}

bool
linklib_protocol_isEqual(Protocol *protocol1, Protocol *protocol2)
{
	return protocol_isEqual(protocol1, protocol2);
}

bool
linklib_protocol_conformsToProtocol(Protocol *protocol1, Protocol *protocol2)
{
	return protocol_conformsToProtocol(protocol1, protocol2);
}

void
linklib_objc_exit(void)
{
	objc_exit();
}

objc_uncaught_exception_handler_t
linklib_objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler_t handler)
{
	return objc_setUncaughtExceptionHandler(handler);
}

void
linklib_objc_setForwardHandler(IMP forward, IMP stretForward)
{
	objc_setForwardHandler(forward, stretForward);
}

void
linklib_objc_setEnumerationMutationHandler(
    objc_enumeration_mutation_handler_t handler)
{
	objc_setEnumerationMutationHandler(handler);
}

void
linklib_objc_zero_weak_references(id value)
{
	objc_zero_weak_references(value);
}
