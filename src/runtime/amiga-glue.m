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

#import "ObjFW_RT.h"
#import "private.h"
#import "macros.h"

void __saveds
__objc_exec_class_m68k(void)
{
	OBJC_M68K_ARG(void *, module, a0)

	__objc_exec_class(module);
}

IMP __saveds
objc_msg_lookup_m68k(void)
{
	OBJC_M68K_ARG(id, obj, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return objc_msg_lookup(obj, sel);
}

IMP __saveds
objc_msg_lookup_stret_m68k(void)
{
	OBJC_M68K_ARG(id, obj, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return objc_msg_lookup_stret(obj, sel);
}

IMP __saveds
objc_msg_lookup_super_m68k(void)
{
	OBJC_M68K_ARG(struct objc_super *, super, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return objc_msg_lookup_super(super, sel);
}

IMP __saveds
objc_msg_lookup_super_stret_m68k(void)
{
	OBJC_M68K_ARG(struct objc_super *, super, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return objc_msg_lookup_super_stret(super, sel);
}

Class __saveds
objc_lookUpClass_m68k(void)
{
	OBJC_M68K_ARG(const char *, name, a0)

	return objc_lookUpClass(name);
}

Class __saveds
objc_getClass_m68k(void)
{
	OBJC_M68K_ARG(const char *, name, a0)

	return objc_getClass(name);
}

Class __saveds
objc_getRequiredClass_m68k(void)
{
	OBJC_M68K_ARG(const char *, name, a0)

	return objc_getRequiredClass(name);
}

Class __saveds
objc_lookup_class_m68k(void)
{
	OBJC_M68K_ARG(const char *, name, a0)

	return objc_lookup_class(name);
}

Class __saveds
objc_get_class_m68k(void)
{
	OBJC_M68K_ARG(const char *, name, a0)

	return objc_get_class(name);
}

void __saveds
objc_exception_throw_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	objc_exception_throw(object);

	OF_UNREACHABLE
}

int __saveds
objc_sync_enter_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_sync_enter(object);
}

int __saveds
objc_sync_exit_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_sync_exit(object);
}

id __saveds
objc_getProperty_m68k(void)
{
	OBJC_M68K_ARG(id, self, a0)
	OBJC_M68K_ARG(SEL, _cmd, a1)
	OBJC_M68K_ARG(ptrdiff_t, offset, d0)
	OBJC_M68K_ARG(bool, atomic, d1)

	return objc_getProperty(self, _cmd, offset, atomic);
}

void __saveds
objc_setProperty_m68k(void)
{
	OBJC_M68K_ARG(id, self, a0)
	OBJC_M68K_ARG(SEL, _cmd, a1)
	OBJC_M68K_ARG(ptrdiff_t, offset, d0)
	OBJC_M68K_ARG(id, value, a2)
	OBJC_M68K_ARG(bool, atomic, d1)
	OBJC_M68K_ARG(signed char, copy, d2)

	objc_setProperty(self, _cmd, offset, value, atomic, copy);
}

void __saveds
objc_getPropertyStruct_m68k(void)
{
	OBJC_M68K_ARG(void *, dest, a0)
	OBJC_M68K_ARG(const void *, src, a1)
	OBJC_M68K_ARG(ptrdiff_t, size, d0)
	OBJC_M68K_ARG(bool, atomic, d1)
	OBJC_M68K_ARG(bool, strong, d2)

	objc_getPropertyStruct(dest, src, size, atomic, strong);
}

void __saveds
objc_setPropertyStruct_m68k(void)
{
	OBJC_M68K_ARG(void *, dest, a0)
	OBJC_M68K_ARG(const void *, src, a1)
	OBJC_M68K_ARG(ptrdiff_t, size, d0)
	OBJC_M68K_ARG(bool, atomic, d1)
	OBJC_M68K_ARG(bool, strong, d2)

	objc_setPropertyStruct(dest, src, size, atomic, strong);
}

void __saveds
objc_enumerationMutation_m68k(void)
{
	OBJC_M68K_ARG(id, obj, a0)

	objc_enumerationMutation(obj);
}

int __saveds
__gnu_objc_personality_v0_m68k(void)
{
#ifndef HAVE_SJLJ_EXCEPTIONS
	OBJC_M68K_ARG(int, version, d0)
	OBJC_M68K_ARG(int, actions, d1)
	OBJC_M68K_ARG(uint64_t *, ex_class, d2)
	OBJC_M68K_ARG(void *, ex, a0)
	OBJC_M68K_ARG(void *, ctx, a1)

	return __gnu_objc_personality_v0(version, actions, *ex_class, ex, ctx);
#else
	abort();

	OF_UNREACHABLE
#endif
}

int __saveds
__gnu_objc_personality_sj0_m68k(void)
{
#ifdef HAVE_SJLJ_EXCEPTIONS
	OBJC_M68K_ARG(int, version, d0)
	OBJC_M68K_ARG(int, actions, d1)
	OBJC_M68K_ARG(uint64_t *, ex_class, d2)
	OBJC_M68K_ARG(void *, ex, a0)
	OBJC_M68K_ARG(void *, ctx, a1)

	return __gnu_objc_personality_sj0(version, actions, *ex_class, ex, ctx);
#else
	abort();

	OF_UNREACHABLE
#endif
}

id __saveds
objc_retain_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_retain(object);
}

id __saveds
objc_retainBlock_m68k(void)
{
	OBJC_M68K_ARG(id, block, a0)

	return objc_retainBlock(block);
}

id __saveds
objc_retainAutorelease_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_retainAutorelease(object);
}

void __saveds
objc_release_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	objc_release(object);
}

id __saveds
objc_autorelease_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_autorelease(object);
}

id __saveds
objc_autoreleaseReturnValue_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_autoreleaseReturnValue(object);
}

id __saveds
objc_retainAutoreleaseReturnValue_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_retainAutoreleaseReturnValue(object);
}

id __saveds
objc_retainAutoreleasedReturnValue_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return objc_retainAutoreleasedReturnValue(object);
}

id __saveds
objc_storeStrong_m68k(void)
{
	OBJC_M68K_ARG(id *, object, a0)
	OBJC_M68K_ARG(id, value, a1)

	return objc_storeStrong(object, value);
}

id __saveds
objc_storeWeak_m68k(void)
{
	OBJC_M68K_ARG(id *, object, a0)
	OBJC_M68K_ARG(id, value, a1)

	return objc_storeWeak(object, value);
}

id __saveds
objc_loadWeakRetained_m68k(void)
{
	OBJC_M68K_ARG(id *, object, a0)

	return objc_loadWeakRetained(object);
}

id __saveds
objc_initWeak_m68k(void)
{
	OBJC_M68K_ARG(id *, object, a0)
	OBJC_M68K_ARG(id, value, a1)

	return objc_initWeak(object, value);
}

void __saveds
objc_destroyWeak_m68k(void)
{
	OBJC_M68K_ARG(id *, object, a0)

	objc_destroyWeak(object);
}

id __saveds
objc_loadWeak_m68k(void)
{
	OBJC_M68K_ARG(id *, object, a0)

	return objc_loadWeak(object);
}

void __saveds
objc_copyWeak_m68k(void)
{
	OBJC_M68K_ARG(id *, dest, a0)
	OBJC_M68K_ARG(id *, src, a1)

	objc_copyWeak(dest, src);
}

void __saveds
objc_moveWeak_m68k(void)
{
	OBJC_M68K_ARG(id *, dest, a0)
	OBJC_M68K_ARG(id *, src, a1)

	objc_moveWeak(dest, src);
}

SEL __saveds
sel_registerName_m68k(void)
{
	OBJC_M68K_ARG(const char *, name, a0)

	return sel_registerName(name);
}

const char *__saveds
sel_getName_m68k(void)
{
	OBJC_M68K_ARG(SEL, sel, a0)

	return sel_getName(sel);
}

bool __saveds
sel_isEqual_m68k(void)
{
	OBJC_M68K_ARG(SEL, sel1, a0)
	OBJC_M68K_ARG(SEL, sel2, a1)

	return sel_isEqual(sel1, sel2);
}

Class __saveds
objc_allocateClassPair_m68k(void)
{
	OBJC_M68K_ARG(Class, superclass, a0)
	OBJC_M68K_ARG(const char *, name, a1)
	OBJC_M68K_ARG(size_t, extra_bytes, d0)

	return objc_allocateClassPair(superclass, name, extra_bytes);
}

void __saveds
objc_registerClassPair_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)

	objc_registerClassPair(cls);
}

unsigned int __saveds
objc_getClassList_m68k(void)
{
	OBJC_M68K_ARG(Class *, buf, a0)
	OBJC_M68K_ARG(unsigned int, count, d0)

	return objc_getClassList(buf, count);
}

Class *__saveds
objc_copyClassList_m68k(void)
{
	OBJC_M68K_ARG(unsigned int *, len, a0)

	return objc_copyClassList(len);
}

bool __saveds
class_isMetaClass_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)

	return class_isMetaClass(cls);
}

const char *__saveds
class_getName_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)

	return class_getName(cls);
}

Class __saveds
class_getSuperclass_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)

	return class_getSuperclass(cls);
}

unsigned long __saveds
class_getInstanceSize_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)

	return class_getInstanceSize(cls);
}

bool __saveds
class_respondsToSelector_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return class_respondsToSelector(cls, sel);
}

bool __saveds
class_conformsToProtocol_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(Protocol *, p, a1)

	return class_conformsToProtocol(cls, p);
}

IMP __saveds
class_getMethodImplementation_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return class_getMethodImplementation(cls, sel);
}

IMP __saveds
class_getMethodImplementation_stret_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return class_getMethodImplementation_stret(cls, sel);
}

const char *__saveds
class_getMethodTypeEncoding_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(SEL, sel, a1)

	return class_getMethodTypeEncoding(cls, sel);
}

bool __saveds
class_addMethod_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(SEL, sel, a1)
	OBJC_M68K_ARG(IMP, imp, a2)
	OBJC_M68K_ARG(const char *, types, a3)

	return class_addMethod(cls, sel, imp, types);
}

IMP __saveds
class_replaceMethod_m68k(void)
{
	OBJC_M68K_ARG(Class, cls, a0)
	OBJC_M68K_ARG(SEL, sel, a1)
	OBJC_M68K_ARG(IMP, imp, a2)
	OBJC_M68K_ARG(const char *, types, a3)

	return class_replaceMethod(cls, sel, imp, types);
}

Class __saveds
object_getClass_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return object_getClass(object);
}

Class __saveds
object_setClass_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)
	OBJC_M68K_ARG(Class, cls, a1)

	return object_setClass(object, cls);
}

const char *__saveds
object_getClassName_m68k(void)
{
	OBJC_M68K_ARG(id, object, a0)

	return object_getClassName(object);
}

const char *__saveds
protocol_getName_m68k(void)
{
	OBJC_M68K_ARG(Protocol *, p, a0)

	return protocol_getName(p);
}

bool __saveds
protocol_isEqual_m68k(void)
{
	OBJC_M68K_ARG(Protocol *, a, a0)
	OBJC_M68K_ARG(Protocol *, b, a1)

	return protocol_isEqual(a, b);
}

bool __saveds
protocol_conformsToProtocol_m68k(void)
{
	OBJC_M68K_ARG(Protocol *, a, a0)
	OBJC_M68K_ARG(Protocol *, b, a1)

	return protocol_conformsToProtocol(a, b);
}

void __saveds
objc_exit_m68k(void)
{
	objc_exit();
}

objc_uncaught_exception_handler __saveds
objc_setUncaughtExceptionHandler_m68k(void)
{
	OBJC_M68K_ARG(objc_uncaught_exception_handler, handler, a0)

	return objc_setUncaughtExceptionHandler(handler);
}

void __saveds
objc_setForwardHandler_m68k(void)
{
	OBJC_M68K_ARG(IMP, forward, a0)
	OBJC_M68K_ARG(IMP, forward_stret, a1)

	objc_setForwardHandler(forward, forward_stret);
}

void __saveds
objc_setEnumerationMutationHandler_m68k(void)
{
	OBJC_M68K_ARG(objc_enumeration_mutation_handler, handler, a0)

	objc_setEnumerationMutationHandler(handler);
}

void __saveds
objc_zero_weak_references_m68k(void)
{
	OBJC_M68K_ARG(id, value, a0)

	objc_zero_weak_references(value);
}
