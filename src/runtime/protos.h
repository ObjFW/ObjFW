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

#error This file is only to generate ppcinline.h - do not use it!

/*
 * Used by the glue code.
 */
void __objc_exec_class_inline(void *);
IMP objc_msg_lookup_inline(id, SEL);
IMP objc_msg_lookup_stret_inline(id, SEL);
IMP objc_msg_lookup_super_inline(struct objc_super *, SEL);
IMP objc_msg_lookup_super_stret_inline(struct objc_super *, SEL);
id objc_lookUpClass_inline(const char *);
id objc_getClass_inline(const char *);
id objc_getRequiredClass_inline(const char *);
void objc_exception_throw_inline(id);
int objc_sync_enter_inline(id);
int objc_sync_exit_inline(id);
id objc_getProperty_inline(id, SEL, ptrdiff_t, bool);
void objc_setProperty_inline(id, SEL, ptrdiff_t, id, bool, signed char);
void objc_getPropertyStruct_inline(void *, const void *, ptrdiff_t, bool, bool);
void objc_setPropertyStruct_inline(void *, const void *, ptrdiff_t, bool, bool);
void objc_enumerationMutation_inline(id);

SEL sel_registerName(const char *);
const char *sel_getName(SEL);
bool sel_isEqual(SEL, SEL);
Class objc_allocateClassPair(Class, const char *, size_t);
void objc_registerClassPair(Class);
unsigned int objc_getClassList(Class *, unsigned int);
Class *objc_copyClassList(unsigned int *);
bool class_isMetaClass(Class);
const char *class_getName(Class);
Class class_getSuperclass(Class);
unsigned long class_getInstanceSize(Class);
bool class_respondsToSelector(Class, SEL);
bool class_conformsToProtocol(Class, Protocol *);
IMP class_getMethodImplementation(Class, SEL);
IMP class_getMethodImplementation_stret(Class, SEL);
const char *class_getMethodTypeEncoding(Class, SEL);
bool class_addMethod(Class, SEL, IMP, const char *);
IMP class_replaceMethod(Class, SEL, IMP, const char *);
Class object_getClass(id);
Class object_setClass(id, Class);
const char *object_getClassName(id);
const char *protocol_getName(Protocol *);
bool protocol_isEqual(Protocol *, Protocol *);
bool protocol_conformsToProtocol(Protocol *, Protocol *);
void objc_exit(void);
objc_uncaught_exception_handler objc_setUncaughtExceptionHandler(
    objc_uncaught_exception_handler);
void objc_setForwardHandler(IMP, IMP);
void objc_setEnumerationMutationHandler(objc_enumeration_mutation_handler);
void objc_zero_weak_references(id);
