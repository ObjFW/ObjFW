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

#define OBJC_NO_PERSONALITY_DECLARATION

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import "ObjFWRT.h"
#import "private.h"

#import "macros.h"
#ifdef OF_HAVE_THREADS
# include "mutex.h"
#endif

#ifdef HAVE_SEH_EXCEPTIONS
# include <windows.h>
#endif

#if defined(HAVE_DWARF_EXCEPTIONS)
# define PERSONALITY __gnu_objc_personality_v0
# define CXX_PERSONALITY_STR "__gxx_personality_v0"
#elif defined(HAVE_SJLJ_EXCEPTIONS)
# define PERSONALITY __gnu_objc_personality_sj0
# define CXX_PERSONALITY_STR "__gxx_personality_sj0"
# define _Unwind_RaiseException _Unwind_SjLj_RaiseException
# define __builtin_eh_return_data_regno(i) (i)
#elif defined(HAVE_SEH_EXCEPTIONS)
# define PERSONALITY	 gnu_objc_personality
#else
# error Unknown exception type!
#endif

#if defined(OF_ARM) && !defined(__ARM_DWARF_EH__)
# define HAVE_ARM_EHABI_EXCEPTIONS
#endif

#ifndef HAVE_ARM_EHABI_EXCEPTIONS
# define PERSONALITY_FUNC(func)						\
	_Unwind_Reason_Code						\
	func(int version, int actions, uint64_t exClass,		\
	    struct _Unwind_Exception *ex, struct _Unwind_Context *ctx)
# define CALL_PERSONALITY(func) func(version, actions, exClass, ex, ctx)
#else
# define PERSONALITY_FUNC(func)						\
	_Unwind_Reason_Code						\
	func(uint32_t state, struct _Unwind_Exception *ex,		\
	    struct _Unwind_Context *ctx)
# define CALL_PERSONALITY(func) func(state, ex, ctx)
#endif

#define GNUCOBJC_EXCEPTION_CLASS UINT64_C(0x474E55434F424A43) /* GNUCOBJC */
#define GNUCCXX0_EXCEPTION_CLASS UINT64_C(0x474E5543432B2B00) /* GNUCC++\0 */
#define CLNGCXX0_EXCEPTION_CLASS UINT64_C(0x434C4E47432B2B00) /* CLNGC++\0 */

#define NUM_EMERGENCY_EXCEPTIONS 4

#define _UA_SEARCH_PHASE  0x01
#define _UA_CLEANUP_PHASE 0x02
#define _UA_HANDLER_FRAME 0x04
#define _UA_FORCE_UNWIND  0x08

#define DW_EH_PE_absptr	  0x00

#define DW_EH_PE_uleb128  0x01
#define DW_EH_PE_udata2	  0x02
#define DW_EH_PE_udata4	  0x03
#define DW_EH_PE_udata8	  0x04

#define DW_EH_PE_signed	  0x08
#define DW_EH_PE_sleb128  (DW_EH_PE_signed | DW_EH_PE_uleb128)
#define DW_EH_PE_sdata2	  (DW_EH_PE_signed | DW_EH_PE_udata2)
#define DW_EH_PE_sdata4	  (DW_EH_PE_signed | DW_EH_PE_udata4)
#define DW_EH_PE_sdata8	  (DW_EH_PE_signed | DW_EH_PE_udata8)

#define DW_EH_PE_pcrel	  0x10
#define DW_EH_PE_textrel  0x20
#define DW_EH_PE_datarel  0x30
#define DW_EH_PE_funcrel  0x40
#define DW_EH_PE_aligned  0x50

#define DW_EH_PE_indirect 0x80

#define DW_EH_PE_omit	  0xFF

#define CLEANUP_FOUND	  0x01
#define HANDLER_FOUND	  0x02

struct _Unwind_Context;

typedef enum {
	_URC_OK			= 0,
	_URC_FATAL_PHASE1_ERROR	= 3,
	_URC_END_OF_STACK	= 5,
	_URC_HANDLER_FOUND	= 6,
	_URC_INSTALL_CONTEXT	= 7,
	_URC_CONTINUE_UNWIND	= 8,
	_URC_FAILURE		= 9
} _Unwind_Reason_Code;

struct objc_exception {
	struct _Unwind_Exception {
		uint64_t class;
		void (*cleanup)(
		    _Unwind_Reason_Code, struct _Unwind_Exception *);
#ifndef HAVE_ARM_EHABI_EXCEPTIONS
# ifndef HAVE_SEH_EXCEPTIONS
		/*
		 * The Itanium Exception ABI says to have those and never touch
		 * them.
		 */
		uint64_t private1, private2;
# else
		uint64_t private[6];
# endif
#else
		/* From "Exception Handling ABI for the ARM(R) Architecture" */
		struct {
			uint32_t reserved1, reserved2, reserved3, reserved4;
			uint32_t reserved;
		} unwinderCache;
		struct {
			uint32_t sp;
			uint32_t bitPattern[5];
		} barrierCache;
		struct {
			uint32_t bitPattern[4];
		} cleanupCache;
		struct {
			uint32_t fnstart;
			uint32_t *ehtp;
			uint32_t additional;
			uint32_t reserved1;
		} PRCache;
		long long int : 0;
#endif
	} exception;
	id object;
#ifndef HAVE_ARM_EHABI_EXCEPTIONS
	uintptr_t landingpad;
	intptr_t filter;
#endif
};

struct lsda {
	uintptr_t regionStart, landingpadsStart;
	uint8_t typesTableEnc;
	const uint8_t *typesTable;
	uintptr_t typesTableBase;
	uint8_t callsitesEnc;
	const uint8_t *callsites, *actionTable;
};

extern _Unwind_Reason_Code _Unwind_RaiseException(struct _Unwind_Exception *);
extern void _Unwind_DeleteException(struct _Unwind_Exception *);
extern void *_Unwind_GetLanguageSpecificData(struct _Unwind_Context *);
extern uintptr_t _Unwind_GetRegionStart(struct _Unwind_Context *);
#ifdef HAVE__UNWIND_GETDATARELBASE
extern uintptr_t _Unwind_GetDataRelBase(struct _Unwind_Context *);
#endif
#ifdef HAVE__UNWIND_GETTEXTRELBASE
extern uintptr_t _Unwind_GetTextRelBase(struct _Unwind_Context *);
#endif

#ifndef HAVE_ARM_EHABI_EXCEPTIONS
# define CONTINUE_UNWIND return _URC_CONTINUE_UNWIND

extern uintptr_t _Unwind_GetIP(struct _Unwind_Context *);
extern uintptr_t _Unwind_GetGR(struct _Unwind_Context *, int);
extern void _Unwind_SetIP(struct _Unwind_Context *, uintptr_t);
extern void _Unwind_SetGR(struct _Unwind_Context *, int, uintptr_t);
#else
extern _Unwind_Reason_Code __gnu_unwind_frame(struct _Unwind_Exception *,
    struct _Unwind_Context *);
extern int _Unwind_VRS_Get(struct _Unwind_Context *, int, uint32_t, int,
    void *);
extern int _Unwind_VRS_Set(struct _Unwind_Context *, int, uint32_t, int,
    void *);

# define CONTINUE_UNWIND					\
	{							\
		if (__gnu_unwind_frame(ex, ctx) != _URC_OK)	\
			return _URC_FAILURE;			\
								\
		return _URC_CONTINUE_UNWIND;			\
	}

static inline uintptr_t
_Unwind_GetGR(struct _Unwind_Context *ctx, int regNo)
{
	uintptr_t value;
	_Unwind_VRS_Get(ctx, 0, regNo, 0, &value);
	return value;
}

static inline uintptr_t
_Unwind_GetIP(struct _Unwind_Context *ctx)
{
	return _Unwind_GetGR(ctx, 15) & ~1;
}

static inline void
_Unwind_SetGR(struct _Unwind_Context *ctx, int regNo, uintptr_t value)
{
	_Unwind_VRS_Set(ctx, 0, regNo, 0, &value);
}

static inline void
_Unwind_SetIP(struct _Unwind_Context *ctx, uintptr_t value)
{
	uintptr_t thumb = _Unwind_GetGR(ctx, 15) & 1;
	_Unwind_SetGR(ctx, 15, (value | thumb));
}
#endif

#ifdef CXX_PERSONALITY
static PERSONALITY_FUNC(cxx_personality) OF_WEAK_REF(CXX_PERSONALITY_STR);
#endif

#ifdef HAVE_SEH_EXCEPTIONS
extern EXCEPTION_DISPOSITION _GCC_specific_handler(PEXCEPTION_RECORD, void *,
    PCONTEXT, PDISPATCHER_CONTEXT, _Unwind_Reason_Code (*)(int, int, uint64_t,
    struct _Unwind_Exception *, struct _Unwind_Context *));
#endif

static objc_uncaught_exception_handler_t uncaughtExceptionHandler;
static struct objc_exception emergencyExceptions[NUM_EMERGENCY_EXCEPTIONS];
#ifdef OF_HAVE_THREADS
static of_spinlock_t emergencyExceptionsSpinlock;

OF_CONSTRUCTOR()
{
	if (!of_spinlock_new(&emergencyExceptionsSpinlock))
		OBJC_ERROR("Cannot create spinlock!")
}
#endif

static uint64_t
readULEB128(const uint8_t **ptr)
{
	uint64_t value = 0;
	uint8_t shift = 0;

	do {
		value |= (**ptr & 0x7F) << shift;
		(*ptr)++;
		shift += 7;
	} while (*(*ptr - 1) & 0x80);

	return value;
}

static int64_t
readSLEB128(const uint8_t **ptr)
{
	const uint8_t *oldPtr = *ptr;
	uint8_t bits;
	int64_t value;

	value = readULEB128(ptr);
	bits = (*ptr - oldPtr) * 7;

	if (bits < 64 && value & (1 << (bits - 1)))
		value |= -(1 << bits);

	return value;
}

static uintptr_t
getBase(struct _Unwind_Context *ctx, uint8_t enc)
{
	if (enc == DW_EH_PE_omit)
		return 0;

	switch (enc & 0x70) {
	case DW_EH_PE_absptr:
	case DW_EH_PE_pcrel:
	case DW_EH_PE_aligned:
		return 0;
	case DW_EH_PE_funcrel:
		return _Unwind_GetRegionStart(ctx);
#ifdef HAVE__UNWIND_GETDATARELBASE
	case DW_EH_PE_datarel:
		return _Unwind_GetDataRelBase(ctx);
#else
	case DW_EH_PE_datarel:
		return _Unwind_GetGR(ctx, 1);
#endif
#ifdef HAVE__UNWIND_GETTEXTRELBASE
	case DW_EH_PE_textrel:
		return _Unwind_GetTextRelBase(ctx);
#endif
	}

	OBJC_ERROR("Unknown encoding!")
}

static size_t
sizeForEncoding(uint8_t enc)
{
	if (enc == DW_EH_PE_omit)
		return 0;

	switch (enc & 0x07) {
	case DW_EH_PE_absptr:
		return sizeof(void *);
	case DW_EH_PE_udata2:
		return 2;
	case DW_EH_PE_udata4:
		return 4;
	case DW_EH_PE_udata8:
		return 8;
	}

	OBJC_ERROR("Unknown encoding!")
}

static uint64_t
readValue(uint8_t enc, const uint8_t **ptr)
{
	uint64_t value;

	if (enc == DW_EH_PE_aligned)
		OBJC_ERROR("DW_EH_PE_aligned is not implemented!")

#define READ(type)					\
	{						\
		type tmp;				\
		memcpy(&tmp, *ptr, sizeof(type));	\
		value = tmp;				\
		*ptr += sizeForEncoding(enc);		\
		break;					\
	}
	switch (enc & 0x0F) {
	case DW_EH_PE_absptr:
		READ(uintptr_t)
	case DW_EH_PE_uleb128:
		value = readULEB128(ptr);
		break;
	case DW_EH_PE_udata2:
		READ(uint16_t)
	case DW_EH_PE_udata4:
		READ(uint32_t)
	case DW_EH_PE_udata8:
		READ(uint64_t)
	case DW_EH_PE_sleb128:
		value = readSLEB128(ptr);
		break;
	case DW_EH_PE_sdata2:
		READ(int16_t)
	case DW_EH_PE_sdata4:
		READ(int32_t)
	case DW_EH_PE_sdata8:
		READ(int64_t)
	default:
		OBJC_ERROR("Unknown encoding!")
	}
#undef READ

	return value;
}

#ifndef HAVE_ARM_EHABI_EXCEPTIONS
static uint64_t
resolveValue(uint64_t value, uint8_t enc, const uint8_t *start, uint64_t base)
{
	if (value == 0)
		return 0;

	value += ((enc & 0x70) == DW_EH_PE_pcrel ? (uintptr_t)start : base);

	if (enc & DW_EH_PE_indirect)
		value = *(uintptr_t *)(uintptr_t)value;

	return value;
}
#endif

static void
readLSDA(struct _Unwind_Context *ctx, const uint8_t *ptr, struct lsda *LSDA)
{
	uint8_t landingpadsStartEnc;
	uintptr_t callsitesSize;

	LSDA->regionStart = _Unwind_GetRegionStart(ctx);
	LSDA->landingpadsStart = LSDA->regionStart;
	LSDA->typesTable = NULL;

	if ((landingpadsStartEnc = *ptr++) != DW_EH_PE_omit)
		LSDA->landingpadsStart =
		    (uintptr_t)readValue(landingpadsStartEnc, &ptr);

	if ((LSDA->typesTableEnc = *ptr++) != DW_EH_PE_omit) {
		uintptr_t tmp = (uintptr_t)readULEB128(&ptr);
		LSDA->typesTable = ptr + tmp;
	}

	LSDA->typesTableBase = getBase(ctx, LSDA->typesTableEnc);

	LSDA->callsitesEnc = *ptr++;
	callsitesSize = (uintptr_t)readULEB128(&ptr);
	LSDA->callsites = ptr;

	LSDA->actionTable = LSDA->callsites + callsitesSize;
}

static bool
findCallsite(struct _Unwind_Context *ctx, struct lsda *LSDA,
    uintptr_t *landingpad, const uint8_t **actionRecords)
{
	uintptr_t IP = _Unwind_GetIP(ctx);
	const uint8_t *ptr = LSDA->callsites;

	*landingpad = 0;
	*actionRecords = NULL;

#ifndef HAVE_SJLJ_EXCEPTIONS
	while (ptr < LSDA->actionTable) {
		uintptr_t callsiteStart, callsiteLength, callsiteLandingpad;
		uintptr_t callsiteAction;

		callsiteStart = LSDA->regionStart +
		    (uintptr_t)readValue(LSDA->callsitesEnc, &ptr);
		callsiteLength = (uintptr_t)readValue(LSDA->callsitesEnc, &ptr);
		callsiteLandingpad =
		    (uintptr_t)readValue(LSDA->callsitesEnc, &ptr);
		callsiteAction = (uintptr_t)readULEB128(&ptr);

		/* We can stop if we passed IP, as the table is sorted */
		if (callsiteStart >= IP)
			break;

		if (callsiteStart + callsiteLength >= IP) {
			if (callsiteLandingpad != 0)
				*landingpad = LSDA->landingpadsStart +
				    callsiteLandingpad;
			if (callsiteAction != 0)
				*actionRecords = LSDA->actionTable +
				    callsiteAction - 1;

			return true;
		}
	}

	return false;
#else
	uintptr_t callsiteLandingpad, callsiteAction;

	if ((intptr_t)IP < 1)
		return false;

	do {
		callsiteLandingpad = (uintptr_t)readULEB128(&ptr);
		callsiteAction = (uintptr_t)readULEB128(&ptr);
	} while (--IP > 1);

	*landingpad = callsiteLandingpad + 1;
	if (callsiteAction != 0)
		*actionRecords = LSDA->actionTable + callsiteAction - 1;

	return true;
#endif
}

static bool
classMatches(Class class, id object)
{
	Class iter;

	if (class == Nil)
		return true;

	if (object == nil)
		return false;

	for (iter = object_getClass(object); iter != Nil;
	    iter = class_getSuperclass(iter))
		if (iter == class)
			return true;

	return false;
}

static uint8_t
findActionRecord(const uint8_t *actionRecords, struct lsda *LSDA, int actions,
    bool foreign, struct objc_exception *e, intptr_t *filterPtr)
{
	const uint8_t *ptr;
	intptr_t filter, displacement;

	do {
		ptr = actionRecords;
		filter = (intptr_t)readSLEB128(&ptr);

		/*
		 * Get the next action record. Since readSLEB128() modifies ptr,
		 * we first set the actionrecord to the current ptr and then
		 * add the displacement.
		 */
		actionRecords = ptr;
		displacement = (intptr_t)readSLEB128(&ptr);
		actionRecords += displacement;

		if (filter > 0 && !(actions & _UA_FORCE_UNWIND) && !foreign) {
			Class class;
			const char *className;
			uintptr_t c;
			const uint8_t *tmp;

#ifndef HAVE_ARM_EHABI_EXCEPTIONS
			uintptr_t i;

			i = filter * sizeForEncoding(LSDA->typesTableEnc);
			tmp = LSDA->typesTable - i;
			c = (uintptr_t)readValue(LSDA->typesTableEnc, &tmp);
			c = (uintptr_t)resolveValue(c, LSDA->typesTableEnc,
			    LSDA->typesTable - i, LSDA->typesTableBase);
#else
			tmp = LSDA->typesTable - (filter * 4);
			c = *(uintptr_t *)(void *)tmp;

			if (c != 0) {
				c += (uintptr_t)tmp;
# if defined(OF_LINUX) || defined(OF_NETBSD)
				c = *(uintptr_t *)c;
# endif
			}
#endif

			className = (const char *)c;

			if (className != NULL && *className != '\0' &&
			    strcmp(className, "@id") != 0)
				class = objc_getRequiredClass(className);
			else
				class = Nil;

			if (classMatches(class, e->object)) {
				*filterPtr = filter;
				return HANDLER_FOUND;
			}
		} else if (filter == 0)
			return CLEANUP_FOUND;
		else if (filter < 0)
			OBJC_ERROR("Invalid filter!")
	} while (displacement != 0);

	return 0;
}

#ifdef HAVE_SEH_EXCEPTIONS
static
#endif
PERSONALITY_FUNC(PERSONALITY)
{
#ifdef HAVE_ARM_EHABI_EXCEPTIONS
	int version = 1;
	uint64_t exClass = ex->class;
	int actions;

	switch (state) {
	case 0:	/* _US_VIRTUAL_UNWIND_FRAME */
		actions = _UA_SEARCH_PHASE;
		break;
	case 1:	/* _US_UNWIND_FRAME_STARTING */
		actions = _UA_CLEANUP_PHASE;
		if ((ex->barrierCache.sp == _Unwind_GetGR(ctx, 13)) != 0)
			actions |= _UA_HANDLER_FRAME;
		break;
	case 2:	/* _US_UNWIND_FRAME_RESUME */
		CONTINUE_UNWIND;
	default:
		return _URC_FAILURE;
	}

	_Unwind_SetGR(ctx, 12, (uintptr_t)ex);
#endif
	struct objc_exception *e = (struct objc_exception *)ex;
	bool foreign = (exClass != GNUCOBJC_EXCEPTION_CLASS);
	const uint8_t *LSDAAddr, *actionRecords;
	struct lsda LSDA;
	uintptr_t landingpad = 0;
	uint8_t found = 0;
	intptr_t filter = 0;

	if (foreign) {
		switch (exClass) {
#ifdef CXX_PERSONALITY
		case GNUCCXX0_EXCEPTION_CLASS:
		case CLNGCXX0_EXCEPTION_CLASS:
			if (cxx_personality != NULL)
				return CALL_PERSONALITY(cxx_personality);
			break;
#endif
		}

		/*
		 * None matched or none available - we'll try to handle it
		 * anyway, but will most likely fail.
		 */
	}

	if (version != 1 || ctx == NULL)
		return _URC_FATAL_PHASE1_ERROR;

	/*
	 * We already cached everything we found in phase 1, so we only need
	 * to install the context in phase 2.
	 */
	if (actions & _UA_HANDLER_FRAME && !foreign) {
		/*
		 * For handlers, reg #0 must be the exception's object and reg
		 * #1 the filter.
		 */
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(0),
		    (uintptr_t)e->object);
#ifndef HAVE_ARM_EHABI_EXCEPTIONS
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(1),
		    e->filter);
		_Unwind_SetIP(ctx, e->landingpad);
#else
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(1),
		    ex->barrierCache.bitPattern[1]);
		_Unwind_SetIP(ctx, ex->barrierCache.bitPattern[3]);
#endif

		_Unwind_DeleteException(ex);

		return _URC_INSTALL_CONTEXT;
	}

	/* No LSDA -> nothing to handle */
	if ((LSDAAddr = _Unwind_GetLanguageSpecificData(ctx)) == NULL)
		CONTINUE_UNWIND;

	readLSDA(ctx, LSDAAddr, &LSDA);

	if (!findCallsite(ctx, &LSDA, &landingpad, &actionRecords))
		CONTINUE_UNWIND;

	if (landingpad != 0 && actionRecords != NULL)
		found = findActionRecord(actionRecords, &LSDA, actions,
		    foreign, e, &filter);
	else if (landingpad != 0)
		found = CLEANUP_FOUND;

	if (found == 0)
		CONTINUE_UNWIND;

	if (actions & _UA_SEARCH_PHASE) {
		if (!(found & HANDLER_FOUND) || foreign)
			CONTINUE_UNWIND;

		/* Cache it so we don't have to search it again in phase 2 */
#ifndef HAVE_ARM_EHABI_EXCEPTIONS
		e->landingpad = landingpad;
		e->filter = filter;
#else
		ex->barrierCache.sp = _Unwind_GetGR(ctx, 13);
		ex->barrierCache.bitPattern[1] = filter;
		ex->barrierCache.bitPattern[3] = landingpad;
#endif

		return _URC_HANDLER_FOUND;
	} else if (actions & _UA_CLEANUP_PHASE) {
		if (!(found & CLEANUP_FOUND))
			CONTINUE_UNWIND;

		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(0),
		    (uintptr_t)ex);
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(1), filter);
		_Unwind_SetIP(ctx, landingpad);

		return _URC_INSTALL_CONTEXT;
	}

	OBJC_ERROR("Neither _UA_SEARCH_PHASE nor _UA_CLEANUP_PHASE in actions!")
}

static void
cleanup(_Unwind_Reason_Code reason, struct _Unwind_Exception *ex)
{
	free(ex);
}

static void
emergencyExceptionCleanup(_Unwind_Reason_Code reason,
    struct _Unwind_Exception *ex)
{
#ifdef OF_HAVE_THREADS
	if (!of_spinlock_lock(&emergencyExceptionsSpinlock))
		OBJC_ERROR("Cannot lock spinlock!");
#endif

	ex->class = 0;

#ifdef OF_HAVE_THREADS
	if (!of_spinlock_unlock(&emergencyExceptionsSpinlock))
		OBJC_ERROR("Cannot unlock spinlock!");
#endif
}

void
objc_exception_throw(id object)
{
	struct objc_exception *e = calloc(1, sizeof(*e));
	bool emergency = false;

	if (e == NULL) {
#ifdef OF_HAVE_THREADS
		if (!of_spinlock_lock(&emergencyExceptionsSpinlock))
			OBJC_ERROR("Cannot lock spinlock!");
#endif

		for (uint_fast8_t i = 0; i < NUM_EMERGENCY_EXCEPTIONS; i++) {
			if (emergencyExceptions[i].exception.class == 0) {
				e = &emergencyExceptions[i];
				e->exception.class = GNUCOBJC_EXCEPTION_CLASS;
				emergency = true;

				break;
			}
		}

#ifdef OF_HAVE_THREADS
		if (!of_spinlock_unlock(&emergencyExceptionsSpinlock))
			OBJC_ERROR("Cannot lock spinlock!");
#endif
	}

	if (e == NULL)
		OBJC_ERROR("Not enough memory to allocate exception!")

	e->exception.class = GNUCOBJC_EXCEPTION_CLASS;
	e->exception.cleanup = (emergency
	    ? emergencyExceptionCleanup : cleanup);
	e->object = object;

	if (_Unwind_RaiseException(&e->exception) == _URC_END_OF_STACK &&
	    uncaughtExceptionHandler != NULL)
		uncaughtExceptionHandler(object);

	OBJC_ERROR("_Unwind_RaiseException() returned!")
}

objc_uncaught_exception_handler_t
objc_setUncaughtExceptionHandler(objc_uncaught_exception_handler_t handler)
{
	objc_uncaught_exception_handler_t old = uncaughtExceptionHandler;
	uncaughtExceptionHandler = handler;

	return old;
}

#ifdef HAVE_SEH_EXCEPTIONS
typedef EXCEPTION_DISPOSITION (*seh_personality_fn)(PEXCEPTION_RECORD, void *,
    PCONTEXT, PDISPATCHER_CONTEXT);
static seh_personality_fn __gxx_personality_seh0;

OF_CONSTRUCTOR()
{
	/*
	 * This only works if the application uses libstdc++-6.dll.
	 * There is unfortunately no other way, as Windows does not support
	 * proper weak linking.
	 */

	HMODULE module;
	if ((module = GetModuleHandle("libstdc++-6")) == NULL)
		return;

	__gxx_personality_seh0 = (seh_personality_fn)
	    GetProcAddress(module, "__gxx_personality_seh0");
}

EXCEPTION_DISPOSITION
__gnu_objc_personality_seh0(PEXCEPTION_RECORD ms_exc, void *this_frame,
    PCONTEXT ms_orig_context, PDISPATCHER_CONTEXT ms_disp)
{
	struct _Unwind_Exception *ex =
	    (struct _Unwind_Exception *)ms_exc->ExceptionInformation[0];

	switch (ex->class) {
	case GNUCCXX0_EXCEPTION_CLASS:
	case CLNGCXX0_EXCEPTION_CLASS:
		if (__gxx_personality_seh0 != NULL)
			return __gxx_personality_seh0(ms_exc, this_frame,
			    ms_orig_context, ms_disp);
	}

	return _GCC_specific_handler(ms_exc, this_frame, ms_orig_context,
	    ms_disp, PERSONALITY);
}
#endif
