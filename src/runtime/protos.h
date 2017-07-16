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

#error This file is only to generate ppcinline.h - do not use it!

SEL sel_registerName(const char *);
const char *sel_getName(SEL);
bool sel_isEqual(SEL, SEL);
Class objc_allocateClassPair(Class, const char *, size_t);
void objc_registerClassPair(Class);
id objc_lookUpClass(const char *);
id objc_getClass(const char *);
id objc_getRequiredClass(const char *);
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
void objc_zero_weak_references(id);

/*
 * Used by the compiler, but can also be called manually.
 */
void __objc_exec_class(void *);
IMP objc_msg_lookup(id, SEL);
IMP objc_msg_lookup_stret(id, SEL);
IMP objc_msg_lookup_super(struct objc_super *, SEL);
IMP objc_msg_lookup_super_stret(struct objc_super *, SEL);
void objc_exception_throw(id);
int objc_sync_enter(id);
int objc_sync_exit(id);
id objc_getProperty(id, SEL, ptrdiff_t, BOOL);
void objc_setProperty(id, SEL, ptrdiff_t, id, BOOL, signed char);
void objc_getPropertyStruct(void *, const void *, ptrdiff_t, BOOL, BOOL);
void objc_setPropertyStruct(void *, const void *, ptrdiff_t, BOOL, BOOL);
void objc_enumerationMutation(id);
void objc_setEnumerationMutationHandler(objc_enumeration_mutation_handler);
