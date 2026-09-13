/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <stdint.h>

#define GNUCOBJC_EXCEPTION_CLASS UINT64_C(0x474E55434F424A43) /* GNUCOBJC */
#define GNUCCXX0_EXCEPTION_CLASS UINT64_C(0x474E5543432B2B00) /* GNUCC++\0 */
#define CLNGCXX0_EXCEPTION_CLASS UINT64_C(0x434C4E47432B2B00) /* CLNGC++\0 */

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
# ifndef __SEH__
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
#ifdef OBJC_COMPILING_AMIGA_LIBRARY
	struct Library *ObjFWRTBase;
#endif
};
