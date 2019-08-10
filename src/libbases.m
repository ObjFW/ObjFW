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

#include <proto/exec.h>

#import "OFInitializationFailedException.h"

#import "macros.h"

#ifdef OF_AMIGAOS4
extern struct Library *DOSBase;
extern struct DOSIFace *IDOS;
#endif
struct Library *LocaleBase;
#ifdef OF_AMIGAOS4
struct LocaleIFace *ILocale;
#endif

OF_CONSTRUCTOR()
{
#ifdef OF_AMIGAOS4
	if ((DOSBase = OpenLibrary("dos.library", 36)) == NULL)
		@throw [OFInitializationFailedException exception];

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
}

OF_DESTRUCTOR()
{
#ifdef OF_AMIGAOS4
	if (ILocale != NULL)
		DropInterface((struct Interface *)ILocale);
#endif

	if (LocaleBase != NULL)
		CloseLibrary(LocaleBase);

#ifdef OF_AMIGAOS4
	if (DOSBase != NULL)
		CloseLibrary(DOSBase);

	if (IDOS != NULL)
		DropInterface((struct Interface *)IDOS);
#endif
}
