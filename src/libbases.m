/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "macros.h"

#define Class IntuitionClass
#include <proto/exec.h>
#undef Class

#ifdef OF_MORPHOS
# include <devices/timer.h>
# include <ppcinline/timer.h>
#endif

#import "OFInitializationFailedException.h"

#ifdef OF_COMPILING_AMIGA_LIBRARY
struct Library *DOSBase;
#endif
#ifdef OF_AMIGAOS4
extern struct Library *DOSBase;
extern struct DOSIFace *IDOS;
#endif
struct Library *LocaleBase;
#ifdef OF_AMIGAOS4
struct LocaleIFace *ILocale;
#endif
#ifdef OF_MORPHOS
struct Device *TimerBase;
static struct timerequest timeRequest;
#endif

OF_CONSTRUCTOR()
{
#if defined(OF_COMPILING_AMIGA_LIBRARY) || defined(OF_AMIGAOS4)
	if ((DOSBase = OpenLibrary("dos.library", 36)) == NULL)
		@throw [OFInitializationFailedException exception];
#endif

#ifdef OF_AMIGAOS4
	if ((IDOS = (struct DOSIFace *)
	    GetInterface(DOSBase, "main", 1, NULL)) == NULL)
		@throw [OFInitializationFailedException exception];
#endif

	if ((LocaleBase = OpenLibrary("locale.library", 38)) == NULL)
		@throw [OFInitializationFailedException exception];

#ifdef OF_AMIGAOS4
	if ((ILocale = (struct LocaleIFace *)
	    GetInterface(LocaleBase, "main", 1, NULL)) == NULL)
		@throw [OFInitializationFailedException exception];
#endif

#ifdef OF_MORPHOS
	if (OpenDevice("timer.device", UNIT_MICROHZ,
	    &timeRequest.tr_node, 0) != 0)
		@throw [OFInitializationFailedException exception];

	TimerBase = timeRequest.tr_node.io_Device;
#endif
}

OF_DESTRUCTOR()
{
#ifdef OF_MORPHOS
	if (TimerBase != NULL)
		CloseDevice(&timeRequest.tr_node);
#endif

#ifdef OF_AMIGAOS4
	if (ILocale != NULL)
		DropInterface((struct Interface *)ILocale);
#endif

	if (LocaleBase != NULL)
		CloseLibrary(LocaleBase);

#ifdef OF_AMIGAOS4
	if (IDOS != NULL)
		DropInterface((struct Interface *)IDOS);
#endif

#if defined(OF_COMPILING_AMIGA_LIBRARY) || defined(OF_AMIGAOS4)
	if (DOSBase != NULL)
		CloseLibrary(DOSBase);
#endif
}
