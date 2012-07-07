/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdlib.h>

#import "runtime.h"

static const uint64_t objc_exception_class = 0x474E55434F424A43; /* GNUCOBJC */

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

typedef enum
{
	_URC_FATAL_PHASE1_ERROR	= 3,
	_URC_END_OF_STACK	= 5,
	_URC_HANDLER_FOUND	= 6,
	_URC_INSTALL_CONTEXT	= 7,
	_URC_CONTINUE_UNWIND	= 8
} _Unwind_Reason_Code;

struct objc_exception {
	struct _Unwind_Exception {
		uint64_t class;
		void (*cleanup)(_Unwind_Reason_Code, struct _Unwind_Exception*);
		/*
		 * The Itanium Exception ABI says to have those and never touch
		 * them.
		 */
		uintptr_t private1, private2;
	} exception;
	id object;
	uintptr_t landingpad;
	intptr_t filter;
};

struct lsda {
	uintptr_t region_start, landingpads_start;
	uint8_t typestable_enc;
	const uint8_t *typestable;
	uintptr_t typestable_base;
	uint8_t callsites_enc;
	const uint8_t *callsites, *actiontable;
};

extern _Unwind_Reason_Code _Unwind_RaiseException(struct _Unwind_Exception*);
extern void* _Unwind_GetLanguageSpecificData(struct _Unwind_Context*);
extern uintptr_t _Unwind_GetRegionStart(struct _Unwind_Context*);
extern uintptr_t _Unwind_GetDataRelBase(struct _Unwind_Context*);
extern uintptr_t _Unwind_GetTextRelBase(struct _Unwind_Context*);
extern uintptr_t _Unwind_GetIP(struct _Unwind_Context*);
extern void _Unwind_SetIP(struct _Unwind_Context*, uintptr_t);
extern void _Unwind_SetGR(struct _Unwind_Context*, int, uintptr_t);
extern void _Unwind_DeleteException(struct _Unwind_Exception*);

static objc_uncaught_exception_handler uncaught_exception_handler;

static uint64_t
read_uleb128(const uint8_t **ptr)
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
read_sleb128(const uint8_t **ptr)
{
	const uint8_t *oldptr = *ptr;
	uint8_t bits;
	int64_t value;

	value = read_uleb128(ptr);
	bits = (*ptr - oldptr) * 7;

	if (bits < 64 && value & (1 << (bits - 1)))
		value |= -(1 << bits);

	return value;
}

static uintptr_t
get_base(struct _Unwind_Context *ctx, uint8_t enc)
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
	case DW_EH_PE_datarel:
		return _Unwind_GetDataRelBase(ctx);
	case DW_EH_PE_textrel:
		return _Unwind_GetTextRelBase(ctx);
	}

	abort();
}

static size_t
size_for_encoding(uint8_t enc)
{
	if (enc == DW_EH_PE_omit)
		return 0;

	switch (enc & 0x07) {
	case DW_EH_PE_absptr:
		return sizeof(void*);
	case DW_EH_PE_udata2:
		return 2;
	case DW_EH_PE_udata4:
		return 4;
	case DW_EH_PE_udata8:
		return 8;
	}

	abort();
}

static uint64_t
read_value(uint8_t enc, const uint8_t **ptr)
{
	uint64_t value;

	if (enc == DW_EH_PE_aligned)
		/* Not implemented */
		abort();

#define READ_TYPE(type)				\
	{					\
		value = *(type*)(void*)*ptr;	\
		*ptr += size_for_encoding(enc);	\
		break;				\
	}

	switch (enc & 0x0F) {
	case DW_EH_PE_absptr:
		READ_TYPE(uintptr_t)
	case DW_EH_PE_uleb128:
		value = read_uleb128(ptr);
		break;
	case DW_EH_PE_udata2:
		READ_TYPE(uint16_t)
	case DW_EH_PE_udata4:
		READ_TYPE(uint32_t)
	case DW_EH_PE_udata8:
		READ_TYPE(uint64_t)
	case DW_EH_PE_sleb128:
		value = read_sleb128(ptr);
		break;
	case DW_EH_PE_sdata2:
		READ_TYPE(int16_t)
	case DW_EH_PE_sdata4:
		READ_TYPE(int32_t)
	case DW_EH_PE_sdata8:
		READ_TYPE(int64_t)
	default:
		abort();
	}

#undef READ_TYPE

	return value;
}

static uint64_t
resolve_value(uint64_t value, uint8_t enc, const uint8_t *start, uint64_t base)
{
	if (value == 0)
		return 0;

	value += ((enc & 0x70) == DW_EH_PE_pcrel ? (uintptr_t)start : base);

	if (enc & DW_EH_PE_indirect)
		value = *(uint64_t*)(uintptr_t)value;

	return value;
}

static void
read_lsda(struct _Unwind_Context *ctx, const uint8_t *ptr, struct lsda *lsda)
{
	uint8_t landingpads_start_enc;
	uintptr_t callsites_size;

	lsda->region_start = _Unwind_GetRegionStart(ctx);
	lsda->landingpads_start = lsda->region_start;
	lsda->typestable = NULL;

	if ((landingpads_start_enc = *ptr++) != DW_EH_PE_omit)
		lsda->landingpads_start =
		    (uintptr_t)read_value(landingpads_start_enc, &ptr);

	if ((lsda->typestable_enc = *ptr++) != DW_EH_PE_omit) {
		uintptr_t tmp = (uintptr_t)read_uleb128(&ptr);
		lsda->typestable = ptr + tmp;
	}

	lsda->typestable_base = get_base(ctx, lsda->typestable_enc);

	lsda->callsites_enc = *ptr++;
	callsites_size = (uintptr_t)read_uleb128(&ptr);
	lsda->callsites = ptr;

	lsda->actiontable = lsda->callsites + callsites_size;
}

static BOOL
find_callsite(struct _Unwind_Context *ctx, struct lsda *lsda,
    uintptr_t *landingpad, const uint8_t **actionrecords)
{
	uintptr_t ip = _Unwind_GetIP(ctx);
	const uint8_t *ptr;

	*landingpad = 0;
	*actionrecords = NULL;

	ptr = lsda->callsites;
	while (ptr < lsda->actiontable) {
		uintptr_t callsite_start, callsite_len, callsite_landingpad;
		uintptr_t callsite_action;

		callsite_start = lsda->region_start +
		    (uintptr_t)read_value(lsda->callsites_enc, &ptr);
		callsite_len = (uintptr_t)read_value(lsda->callsites_enc, &ptr);
		callsite_landingpad =
		    (uintptr_t)read_value(lsda->callsites_enc, &ptr);
		callsite_action = (uintptr_t)read_uleb128(&ptr);

		/* We can stop if we passed IP, as the table is sorted */
		if (callsite_start >= ip)
			break;

		if (callsite_start + callsite_len >= ip) {
			if (callsite_landingpad != 0)
				*landingpad = lsda->landingpads_start +
				    callsite_landingpad;
			if (callsite_action != 0)
				*actionrecords = lsda->actiontable +
				    callsite_action - 1;

			return YES;
		}
	}

	return NO;
}

static BOOL
class_matches(Class class, id object)
{
	Class iter;

	if (class == Nil)
		return YES;

	if (object == nil)
		return NO;

	for (iter = object->isa; iter != Nil; iter = class_getSuperclass(iter))
		if (iter == class)
			return YES;

	return NO;
}

static uint8_t
find_actionrecord(const uint8_t *actionrecords, struct lsda *lsda, int actions,
    BOOL foreign, struct objc_exception *e, intptr_t *filtervalue)
{
	uint8_t found = 0;
	const uint8_t *ptr;
	intptr_t filter, displacement;

	do {
		ptr = actionrecords;
		filter = (intptr_t)read_sleb128(&ptr);

		/*
		 * Get the next action record. Since read_sleb128 modifies ptr,
		 * we first set the actionrecord to the current ptr and then
		 * add the displacement.
		 */
		actionrecords = ptr;
		displacement = (intptr_t)read_sleb128(&ptr);
		actionrecords += displacement;

		if (filter > 0 && !(actions & _UA_FORCE_UNWIND) && !foreign) {
			Class class;
			uintptr_t i, c;
			const uint8_t *tmp;

			i = filter * size_for_encoding(lsda->typestable_enc);
			tmp = lsda->typestable - i;
			c = (uintptr_t)read_value(lsda->typestable_enc, &tmp);
			c = (uintptr_t)resolve_value(c, lsda->typestable_enc,
			    lsda->typestable - i, lsda->typestable_base);

			class = (c != 0 ? objc_get_class((const char*)c) : Nil);

			if (class_matches(class, e->object)) {
				*filtervalue = filter;
				return (found | HANDLER_FOUND);
			}
		} else if (filter == 0)
			found |= CLEANUP_FOUND;
		else
			abort();
	} while (displacement != 0);

	return found;
}

_Unwind_Reason_Code
__gnu_objc_personality_v0(int version, int actions, uint64_t ex_class,
    struct _Unwind_Exception *ex, struct _Unwind_Context *ctx)
{
	struct objc_exception *e = (struct objc_exception*)ex;
	BOOL foreign = (ex_class != objc_exception_class);
	const uint8_t *lsda_addr, *actionrecords;
	struct lsda lsda;
	uintptr_t landingpad = 0;
	uint8_t found = 0;
	intptr_t filter = 0;

	if (version != 1)
		return _URC_FATAL_PHASE1_ERROR;

	if (ctx == NULL)
		abort();

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
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(1),
		    e->filter);
		_Unwind_SetIP(ctx, e->landingpad);

		return _URC_INSTALL_CONTEXT;
	}

	/* No LSDA -> nothing to handle */
	if ((lsda_addr = _Unwind_GetLanguageSpecificData(ctx)) == NULL)
		return _URC_CONTINUE_UNWIND;

	read_lsda(ctx, lsda_addr, &lsda);

	if (!find_callsite(ctx, &lsda, &landingpad, &actionrecords))
		return _URC_CONTINUE_UNWIND;

	if (landingpad != 0 && actionrecords == NULL)
		found = CLEANUP_FOUND;
	else if (landingpad != 0)
		found = find_actionrecord(actionrecords, &lsda, actions,
		    foreign, e, &filter);

	if (!found)
		return _URC_CONTINUE_UNWIND;

	if (actions & _UA_SEARCH_PHASE) {
		if (!(found & HANDLER_FOUND))
			return _URC_CONTINUE_UNWIND;

		/* Cache it so we don't have to search it again in phase 2 */
		if (!foreign) {
			e->landingpad = landingpad;
			e->filter = filter;
		}

		return _URC_HANDLER_FOUND;
	} else if (actions & _UA_CLEANUP_PHASE) {
		/* For cleanup, reg #0 must be the exception and reg #1 zero */
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(0),
		    (uintptr_t)e);
		_Unwind_SetGR(ctx, __builtin_eh_return_data_regno(1), 0);
		_Unwind_SetIP(ctx, landingpad);

		return _URC_INSTALL_CONTEXT;
	}

	abort();
}

static void
cleanup(_Unwind_Reason_Code reason, struct _Unwind_Exception *ex)
{
	free(ex);
}

void
objc_exception_throw(id object)
{
	struct objc_exception *e;

	if ((e = malloc(sizeof(*e))) == NULL)
		abort();

	e->exception.class = objc_exception_class;
	e->exception.cleanup = cleanup;
	e->exception.private1 = e->exception.private2 = 0;
	e->object = object;

	if (_Unwind_RaiseException(&e->exception) == _URC_END_OF_STACK &&
	    uncaught_exception_handler != NULL)
		uncaught_exception_handler(object);

	abort();
}

objc_uncaught_exception_handler
objc_setUncaughtExceptionHandler(objc_uncaught_exception_handler handler)
{
	objc_uncaught_exception_handler old = uncaught_exception_handler;
	uncaught_exception_handler = handler;

	return old;
}
