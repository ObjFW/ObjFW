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

#ifdef OF_AMIGAOS_M68K
# define PPC_PARAMS(...) (void)
# define M68K_ARG OBJC_M68K_ARG
#else
# define PPC_PARAMS(...) (__VA_ARGS__)
# define M68K_ARG(...)
#endif

extern bool objc_init(unsigned int, struct objc_libc *, FILE *, FILE *);

#ifdef OF_MORPHOS
/* All __saveds functions in this file need to use the SysV ABI */
__asm__ (
    ".section .text\n"
    ".align 2\n"
    "__restore_r13:\n"
    "	lwz	%r13, 44(%r12)\n"
    "	blr\n"
);
#endif

bool __saveds
glue_objc_init PPC_PARAMS(unsigned int version, struct objc_libc *libc,
    FILE *stdout_, FILE *stderr_)
{
	M68K_ARG(unsigned int, version, d0)
	M68K_ARG(struct objc_libc *, libc, a0)
	M68K_ARG(FILE *, stdout_, a1)
	M68K_ARG(FILE *, stderr_, a2)

	return objc_init(version, libc, stdout_, stderr_);
}

void __saveds
glue___objc_exec_class PPC_PARAMS(void *module)
{
	M68K_ARG(void *, module, a0)

	__objc_exec_class(module);
}

IMP __saveds
glue_objc_msg_lookup PPC_PARAMS(id object, SEL selector)
{
	M68K_ARG(id, object, a0)
	M68K_ARG(SEL, selector, a1)

	return objc_msg_lookup(object, selector);
}

IMP __saveds
glue_objc_msg_lookup_stret PPC_PARAMS(id object, SEL selector)
{
	M68K_ARG(id, object, a0)
	M68K_ARG(SEL, selector, a1)

	return objc_msg_lookup_stret(object, selector);
}

IMP __saveds
glue_objc_msg_lookup_super PPC_PARAMS(struct objc_super *super, SEL selector)
{
	M68K_ARG(struct objc_super *, super, a0)
	M68K_ARG(SEL, selector, a1)

	return objc_msg_lookup_super(super, selector);
}

IMP __saveds
glue_objc_msg_lookup_super_stret PPC_PARAMS(struct objc_super *super,
    SEL selector)
{
	M68K_ARG(struct objc_super *, super, a0)
	M68K_ARG(SEL, selector, a1)

	return objc_msg_lookup_super_stret(super, selector);
}

Class __saveds
glue_objc_lookUpClass PPC_PARAMS(const char *name)
{
	M68K_ARG(const char *, name, a0)

	return objc_lookUpClass(name);
}

Class __saveds
glue_objc_getClass PPC_PARAMS(const char *name)
{
	M68K_ARG(const char *, name, a0)

	return objc_getClass(name);
}

Class __saveds
glue_objc_getRequiredClass PPC_PARAMS(const char *name)
{
	M68K_ARG(const char *, name, a0)

	return objc_getRequiredClass(name);
}

Class __saveds
glue_objc_lookup_class PPC_PARAMS(const char *name)
{
	M68K_ARG(const char *, name, a0)

	return objc_lookup_class(name);
}

Class __saveds
glue_objc_get_class PPC_PARAMS(const char *name)
{
	M68K_ARG(const char *, name, a0)

	return objc_get_class(name);
}

void __saveds
glue_objc_exception_throw PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	objc_exception_throw(object);

	OF_UNREACHABLE
}

int __saveds
glue_objc_sync_enter PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_sync_enter(object);
}

int __saveds
glue_objc_sync_exit PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_sync_exit(object);
}

id __saveds
glue_objc_getProperty PPC_PARAMS(id self, SEL _cmd, ptrdiff_t offset,
    bool atomic)
{
	M68K_ARG(id, self, a0)
	M68K_ARG(SEL, _cmd, a1)
	M68K_ARG(ptrdiff_t, offset, d0)
	M68K_ARG(bool, atomic, d1)

	return objc_getProperty(self, _cmd, offset, atomic);
}

void __saveds
glue_objc_setProperty PPC_PARAMS(id self, SEL _cmd, ptrdiff_t offset, id value,
    bool atomic, signed char copy)
{
	M68K_ARG(id, self, a0)
	M68K_ARG(SEL, _cmd, a1)
	M68K_ARG(ptrdiff_t, offset, d0)
	M68K_ARG(id, value, a2)
	M68K_ARG(bool, atomic, d1)
	M68K_ARG(signed char, copy, d2)

	objc_setProperty(self, _cmd, offset, value, atomic, copy);
}

void __saveds
glue_objc_getPropertyStruct PPC_PARAMS(void *dest, const void *src,
    ptrdiff_t size, bool atomic, bool strong)
{
	M68K_ARG(void *, dest, a0)
	M68K_ARG(const void *, src, a1)
	M68K_ARG(ptrdiff_t, size, d0)
	M68K_ARG(bool, atomic, d1)
	M68K_ARG(bool, strong, d2)

	objc_getPropertyStruct(dest, src, size, atomic, strong);
}

void __saveds
glue_objc_setPropertyStruct PPC_PARAMS(void *dest, const void *src,
    ptrdiff_t size, bool atomic, bool strong)
{
	M68K_ARG(void *, dest, a0)
	M68K_ARG(const void *, src, a1)
	M68K_ARG(ptrdiff_t, size, d0)
	M68K_ARG(bool, atomic, d1)
	M68K_ARG(bool, strong, d2)

	objc_setPropertyStruct(dest, src, size, atomic, strong);
}

void __saveds
glue_objc_enumerationMutation PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	objc_enumerationMutation(object);
}

int __saveds
glue___gnu_objc_personality PPC_PARAMS(int version, int actions,
    uint64_t exClass, void *ex, void *ctx)
{
	M68K_ARG(int, version, d0)
	M68K_ARG(int, actions, d1)
	M68K_ARG(uint64_t *, exClassPtr, d2)
	M68K_ARG(void *, ex, a0)
	M68K_ARG(void *, ctx, a1)
#ifdef OF_AMIGAOS_M68K
	uint64_t exClass = *exClassPtr;
#endif

#ifdef HAVE_SJLJ_EXCEPTIONS
	return __gnu_objc_personality_sj0(version, actions, exClass, ex, ctx);
#else
	return __gnu_objc_personality_v0(version, actions, exClass, ex, ctx);
#endif
}

id __saveds
glue_objc_retain PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_retain(object);
}

id __saveds
glue_objc_retainBlock PPC_PARAMS(id block)
{
	M68K_ARG(id, block, a0)

	return objc_retainBlock(block);
}

id __saveds
glue_objc_retainAutorelease PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_retainAutorelease(object);
}

void __saveds
glue_objc_release PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	objc_release(object);
}

id __saveds
glue_objc_autorelease PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_autorelease(object);
}

id __saveds
glue_objc_autoreleaseReturnValue PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_autoreleaseReturnValue(object);
}

id __saveds
glue_objc_retainAutoreleaseReturnValue PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_retainAutoreleaseReturnValue(object);
}

id __saveds
glue_objc_retainAutoreleasedReturnValue PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return objc_retainAutoreleasedReturnValue(object);
}

id __saveds
glue_objc_storeStrong PPC_PARAMS(id *object, id value)
{
	M68K_ARG(id *, object, a0)
	M68K_ARG(id, value, a1)

	return objc_storeStrong(object, value);
}

id __saveds
glue_objc_storeWeak PPC_PARAMS(id *object, id value)
{
	M68K_ARG(id *, object, a0)
	M68K_ARG(id, value, a1)

	return objc_storeWeak(object, value);
}

id __saveds
glue_objc_loadWeakRetained PPC_PARAMS(id *object)
{
	M68K_ARG(id *, object, a0)

	return objc_loadWeakRetained(object);
}

id __saveds
glue_objc_initWeak PPC_PARAMS(id *object, id value)
{
	M68K_ARG(id *, object, a0)
	M68K_ARG(id, value, a1)

	return objc_initWeak(object, value);
}

void __saveds
glue_objc_destroyWeak PPC_PARAMS(id *object)
{
	M68K_ARG(id *, object, a0)

	objc_destroyWeak(object);
}

id __saveds
glue_objc_loadWeak PPC_PARAMS(id *object)
{
	M68K_ARG(id *, object, a0)

	return objc_loadWeak(object);
}

void __saveds
glue_objc_copyWeak PPC_PARAMS(id *dest, id *src)
{
	M68K_ARG(id *, dest, a0)
	M68K_ARG(id *, src, a1)

	objc_copyWeak(dest, src);
}

void __saveds
glue_objc_moveWeak PPC_PARAMS(id *dest, id *src)
{
	M68K_ARG(id *, dest, a0)
	M68K_ARG(id *, src, a1)

	objc_moveWeak(dest, src);
}

SEL __saveds
glue_sel_registerName PPC_PARAMS(const char *name)
{
	M68K_ARG(const char *, name, a0)

	return sel_registerName(name);
}

const char *__saveds
glue_sel_getName PPC_PARAMS(SEL selector)
{
	M68K_ARG(SEL, selector, a0)

	return sel_getName(selector);
}

bool __saveds
glue_sel_isEqual PPC_PARAMS(SEL selector1, SEL selector2)
{
	M68K_ARG(SEL, selector1, a0)
	M68K_ARG(SEL, selector2, a1)

	return sel_isEqual(selector1, selector2);
}

Class __saveds
glue_objc_allocateClassPair PPC_PARAMS(Class superclass, const char *name,
    size_t extraBytes)
{
	M68K_ARG(Class, superclass, a0)
	M68K_ARG(const char *, name, a1)
	M68K_ARG(size_t, extraBytes, d0)

	return objc_allocateClassPair(superclass, name, extraBytes);
}

void __saveds
glue_objc_registerClassPair PPC_PARAMS(Class class)
{
	M68K_ARG(Class, class, a0)

	objc_registerClassPair(class);
}

unsigned int __saveds
glue_objc_getClassList PPC_PARAMS(Class *buffer, unsigned int count)
{
	M68K_ARG(Class *, buffer, a0)
	M68K_ARG(unsigned int, count, d0)

	return objc_getClassList(buffer, count);
}

Class *__saveds
glue_objc_copyClassList PPC_PARAMS(unsigned int *length)
{
	M68K_ARG(unsigned int *, length, a0)

	return objc_copyClassList(length);
}

bool __saveds
glue_class_isMetaClass PPC_PARAMS(Class class)
{
	M68K_ARG(Class, class, a0)

	return class_isMetaClass(class);
}

const char *__saveds
glue_class_getName PPC_PARAMS(Class class)
{
	M68K_ARG(Class, class, a0)

	return class_getName(class);
}

Class __saveds
glue_class_getSuperclass PPC_PARAMS(Class class)
{
	M68K_ARG(Class, class, a0)

	return class_getSuperclass(class);
}

unsigned long __saveds
glue_class_getInstanceSize PPC_PARAMS(Class class)
{
	M68K_ARG(Class, class, a0)

	return class_getInstanceSize(class);
}

bool __saveds
glue_class_respondsToSelector PPC_PARAMS(Class class, SEL selector)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(SEL, selector, a1)

	return class_respondsToSelector(class, selector);
}

bool __saveds
glue_class_conformsToProtocol PPC_PARAMS(Class class, Protocol *protocol)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(Protocol *, protocol, a1)

	return class_conformsToProtocol(class, protocol);
}

IMP __saveds
glue_class_getMethodImplementation PPC_PARAMS(Class class, SEL selector)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(SEL, selector, a1)

	return class_getMethodImplementation(class, selector);
}

IMP __saveds
glue_class_getMethodImplementation_stret PPC_PARAMS(Class class, SEL selector)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(SEL, selector, a1)

	return class_getMethodImplementation_stret(class, selector);
}

const char *__saveds
glue_class_getMethodTypeEncoding PPC_PARAMS(Class class, SEL selector)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(SEL, selector, a1)

	return class_getMethodTypeEncoding(class, selector);
}

bool __saveds
glue_class_addMethod PPC_PARAMS(Class class, SEL selector, IMP implementation,
    const char *typeEncoding)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(SEL, selector, a1)
	M68K_ARG(IMP, implementation, a2)
	M68K_ARG(const char *, typeEncoding, a3)

	return class_addMethod(class, selector, implementation, typeEncoding);
}

IMP __saveds
glue_class_replaceMethod PPC_PARAMS(Class class, SEL selector,
    IMP implementation, const char *typeEncoding)
{
	M68K_ARG(Class, class, a0)
	M68K_ARG(SEL, selector, a1)
	M68K_ARG(IMP, implementation, a2)
	M68K_ARG(const char *, typeEncoding, a3)

	return class_replaceMethod(class, selector, implementation,
	    typeEncoding);
}

Class __saveds
glue_object_getClass PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return object_getClass(object);
}

Class __saveds
glue_object_setClass PPC_PARAMS(id object, Class class)
{
	M68K_ARG(id, object, a0)
	M68K_ARG(Class, class, a1)

	return object_setClass(object, class);
}

const char *__saveds
glue_object_getClassName PPC_PARAMS(id object)
{
	M68K_ARG(id, object, a0)

	return object_getClassName(object);
}

const char *__saveds
glue_protocol_getName PPC_PARAMS(Protocol *protocol)
{
	M68K_ARG(Protocol *, protocol, a0)

	return protocol_getName(protocol);
}

bool __saveds
glue_protocol_isEqual PPC_PARAMS(Protocol *protocol1, Protocol *protocol2)
{
	M68K_ARG(Protocol *, protocol1, a0)
	M68K_ARG(Protocol *, protocol2, a1)

	return protocol_isEqual(protocol1, protocol2);
}

bool __saveds
glue_protocol_conformsToProtocol PPC_PARAMS(Protocol *protocol1,
    Protocol *protocol2)
{
	M68K_ARG(Protocol *, protocol1, a0)
	M68K_ARG(Protocol *, protocol2, a1)

	return protocol_conformsToProtocol(protocol1, protocol2);
}

objc_uncaught_exception_handler_t __saveds
glue_objc_setUncaughtExceptionHandler PPC_PARAMS(
    objc_uncaught_exception_handler_t handler)
{
	M68K_ARG(objc_uncaught_exception_handler_t, handler, a0)

	return objc_setUncaughtExceptionHandler(handler);
}

void __saveds
glue_objc_setForwardHandler PPC_PARAMS(IMP forward, IMP stretForward)
{
	M68K_ARG(IMP, forward, a0)
	M68K_ARG(IMP, stretForward, a1)

	objc_setForwardHandler(forward, stretForward);
}

void __saveds
glue_objc_setEnumerationMutationHandler PPC_PARAMS(
    objc_enumeration_mutation_handler_t handler)
{
	M68K_ARG(objc_enumeration_mutation_handler_t, handler, a0)

	objc_setEnumerationMutationHandler(handler);
}

void __saveds
glue_objc_zero_weak_references PPC_PARAMS(id value)
{
	M68K_ARG(id, value, a0)

	objc_zero_weak_references(value);
}

void __saveds
glue_objc_exit(void)
{
	objc_exit();
}
