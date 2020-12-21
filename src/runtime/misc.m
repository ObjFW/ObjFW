/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "ObjFWRT.h"
#include "private.h"

#ifdef OF_AMIGAOS
# define USE_INLINE_STDARG
# include <proto/exec.h>
# include <clib/debug_protos.h>
# define __NOLIBBASE__
# define Class IntuitionClass
# include <proto/intuition.h>
# undef Class
# undef __NOLIBBASE__
#endif

static objc_enumeration_mutation_handler_t enumerationMutationHandler = NULL;

void
objc_enumerationMutation(id object)
{
	if (enumerationMutationHandler != NULL)
		enumerationMutationHandler(object);
	else
		OBJC_ERROR("Object was mutated during enumeration!");
}

void
objc_setEnumerationMutationHandler(objc_enumeration_mutation_handler_t handler)
{
	enumerationMutationHandler = handler;
}

void
objc_error(const char *title, const char *format, ...)
{
#ifdef OF_AMIGAOS
# define BUF_LEN 512
	char message[BUF_LEN];
	int status;
	va_list args;
	struct Library *IntuitionBase;
# ifdef OF_AMIGAOS4
	struct IntuitionIFace *IIntuition;
# endif
	struct EasyStruct easy;

	va_start(args, format);
	status = vsnprintf(message, BUF_LEN, format, args);
	if (status <= 0 || status >= BUF_LEN)
		message[0] = '\0';
	va_end(args);

# ifndef OF_AMIGAOS4
	kprintf("[%s] %s\n", title, message);
# endif

	if ((IntuitionBase = OpenLibrary("intuition.library", 0)) == NULL)
		exit(EXIT_FAILURE);

# ifdef OF_AMIGAOS4
	if ((IIntuition = (struct IntuitionIFace *)GetInterface(IntuitionBase,
	    "main", 1, NULL)) == NULL)
		exit(EXIT_FAILURE);
# endif

	easy.es_StructSize = sizeof(easy);
	easy.es_Flags = 0;
	easy.es_Title = (void *)title;
	easy.es_TextFormat = (void *)"%s";
	easy.es_GadgetFormat = (void *)"OK";

	EasyRequest(NULL, &easy, NULL, (ULONG)message);

# ifdef OF_AMIGAOS4
	DropInterface((struct Interface *)IIntuition);
# endif

	CloseLibrary(IntuitionBase);

	exit(EXIT_FAILURE);
# undef BUF_LEN
#else
	va_list args;

	va_start(args, format);

	fprintf(stderr, "[%s] ", title);
	vfprintf(stderr, format, args);
	fprintf(stderr, "\n");
	fflush(stderr);

	va_end(args);

	abort();
#endif

	OF_UNREACHABLE
}
