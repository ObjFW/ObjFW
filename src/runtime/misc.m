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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "ObjFWRT.h"
#include "private.h"

#ifdef OF_WINDOWS
# include <windows.h>
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# define USE_INLINE_STDARG
# include <proto/exec.h>
# include <clib/debug_protos.h>
# define __NOLIBBASE__
# include <proto/intuition.h>
# undef __NOLIBBASE__
# undef Class
#endif

static objc_enumeration_mutation_handler enumerationMutationHandler = NULL;

void
objc_enumerationMutation(id object)
{
	if (enumerationMutationHandler != NULL)
		enumerationMutationHandler(object);
	else
		_OBJC_ERROR("Object was mutated during enumeration!");
}

void
objc_setEnumerationMutationHandler(objc_enumeration_mutation_handler handler)
{
	enumerationMutationHandler = handler;
}

void
_objc_error(const char *title, const char *format, ...)
{
#if defined(OF_WINDOWS) || defined(OF_AMIGAOS)
# define messageLen 512
	char message[messageLen];
	int status;
	va_list args;

	va_start(args, format);
	status = vsnprintf(message, messageLen, format, args);
	if (status <= 0 || status >= messageLen)
		message[0] = '\0';
	va_end(args);
# undef BUF_LEN
#endif

#if defined(OF_WINDOWS)
	fprintf(stderr, "[%s] %s\n", title, message);
	fflush(stderr);

	MessageBoxA(NULL, message, title,
	    MB_OK | MB_SYSTEMMODAL | MB_ICONERROR);

	abort();
#elif defined(OF_AMIGAOS)
	struct Library *IntuitionBase;
# ifdef OF_AMIGAOS4
	struct IntuitionIFace *IIntuition;
# endif
	struct EasyStruct easy;

# ifndef OF_AMIGAOS4
	kprintf("[%s] %s\n", title, message);
# endif

	if ((IntuitionBase = OpenLibrary("intuition.library", 0)) == NULL)
		abort();

# ifdef OF_AMIGAOS4
	if ((IIntuition = (struct IntuitionIFace *)GetInterface(IntuitionBase,
	    "main", 1, NULL)) == NULL)
		abort();
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

	abort();
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

char *
_objc_strdup(const char *string)
{
	char *copy;
	size_t length = strlen(string);

	if ((copy = (char *)malloc(length + 1)) == NULL)
		return NULL;

	memcpy(copy, string, length + 1);

	return copy;
}
