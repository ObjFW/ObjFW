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

#include "config.h"

#include <errno.h>
#include <stdio.h>
#include <unistd.h>

#import "macros.h"
#import "amiga-library.h"

#define USE_INLINE_STDARG
#include <proto/exec.h>
#include <proto/intuition.h>

#include <constructor.h>

extern struct Library *ObjFWRTBase, *ObjFWBase, *ObjFWHIDBase;
extern int _Unwind_RaiseException(void *);
extern void _Unwind_DeleteException(void *);
extern void *_Unwind_GetLanguageSpecificData(void *);
extern uintptr_t _Unwind_GetRegionStart(void *);
extern uintptr_t _Unwind_GetDataRelBase(void *);
extern uintptr_t _Unwind_GetTextRelBase(void *);
extern uintptr_t _Unwind_GetIP(void *);
extern uintptr_t _Unwind_GetGR(void *, int);
extern void _Unwind_SetIP(void *, uintptr_t);
extern void _Unwind_SetGR(void *, int, uintptr_t);
extern void _Unwind_Resume(void *);
extern int _Unwind_Backtrace(int (*)(void *, void *), void *);
extern void __register_frame(void *);
extern void __deregister_frame(void *);

void *__objc_class_name_OH8BitDoPro2Gamepad;
void *__objc_class_name_OH8BitDoUltimate2CWirelessGamepad;
void *__objc_class_name_OHDualSenseGamepad;
void *__objc_class_name_OHDualShock3Gamepad;
void *__objc_class_name_OHDualShock4Gamepad;
void *__objc_class_name_OHDualShockGamepad;
void *__objc_class_name_OHExtendedN64Controller;
void *__objc_class_name_OHExtendedSNESGamepad;
void *__objc_class_name_OHGameController;
void *__objc_class_name_OHGameControllerAxis;
void *__objc_class_name_OHGameControllerButton;
void *__objc_class_name_OHGameControllerDirectionalPad;
void *__objc_class_name_OHGameControllerElement;
void *__objc_class_name_OHGameCubeController;
void *__objc_class_name_OHJoyConPair;
void *__objc_class_name_OHLeftJoyCon;
void *__objc_class_name_OHN64Controller;
void *__objc_class_name_OHNESGamepad;
void *__objc_class_name_OHRightJoyCon;
void *__objc_class_name_OHSNESGamepad;
void *__objc_class_name_OHStadiaGamepad;
void *__objc_class_name_OHSwitchProController;
void *__objc_class_name_OHXboxGamepad;

#ifndef OF_AMIGA_LIB
static void
error(const char *string, ULONG arg)
{
	struct Library *IntuitionBase = OpenLibrary("intuition.library", 0);

	if (IntuitionBase != NULL) {
		struct EasyStruct easy = {
			.es_StructSize = sizeof(easy),
			.es_Flags = 0,
			.es_Title = (UBYTE *)NULL,
			.es_TextFormat = (UBYTE *)string,
			(UBYTE *)"OK"
		};

		EasyRequest(NULL, &easy, NULL, arg);

		CloseLibrary(IntuitionBase);
	}

	exit(EXIT_FAILURE);
}

static void __attribute__((__used__))
ctor(void)
{
	static bool initialized = false;
	struct OHLinklibContext ctx = {
		.ObjFWRTBase = ObjFWRTBase,
		.ObjFWBase = ObjFWBase,
		._Unwind_RaiseException = _Unwind_RaiseException,
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
		._Unwind_Resume = _Unwind_Resume,
		._Unwind_Backtrace = _Unwind_Backtrace,
		.__register_frame = __register_frame,
		.__deregister_frame = __deregister_frame,
	};

	if (initialized)
		return;

	if ((ObjFWHIDBase = OpenLibrary(OBJFWHID_AMIGA_LIB,
	    OBJFWHID_LIB_MINOR)) == NULL)
		error("Failed to open " OBJFWHID_AMIGA_LIB " version %lu!",
		    OBJFWHID_LIB_MINOR);

	if (!OHInit(1, &ctx))
		error("Failed to initialize " OBJFWHID_AMIGA_LIB "!", 0);

	initialized = true;
}

static void __attribute__((__used__))
dtor(void)
{
	if (ObjFWHIDBase != NULL)
		CloseLibrary(ObjFWHIDBase);
}

CONSTRUCTOR_P(ObjFWHID, 127)
{
	ctor();

	return 0;
}

DESTRUCTOR_P(ObjFWHID, 127)
{
	dtor();
}
#endif
