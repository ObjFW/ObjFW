/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#import "OFEmbeddedURIHandler.h"
#import "OFMemoryStream.h"
#import "OFURI.h"

#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"

#ifdef OF_HAVE_THREADS
# import "OFOnce.h"
# import "OFPlainMutex.h"
#endif

struct EmbeddedFile {
	const char *name;
	const uint8_t *bytes;
	size_t size;
} *embeddedFiles = NULL;
size_t numEmbeddedFiles = 0;
#ifdef OF_HAVE_THREADS
static OFPlainMutex mutex;

static void
init(void)
{
	OFEnsure(OFPlainMutexNew(&mutex) == 0);
}
#endif

void
OFRegisterEmbeddedFile(const char *name, const uint8_t *bytes, size_t size)
{
#ifdef OF_HAVE_THREADS
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, init);

	OFEnsure(OFPlainMutexLock(&mutex) == 0);
#endif

	embeddedFiles = realloc(embeddedFiles,
	    sizeof(*embeddedFiles) * (numEmbeddedFiles + 1));
	OFEnsure(embeddedFiles != NULL);

	embeddedFiles[numEmbeddedFiles].name = name;
	embeddedFiles[numEmbeddedFiles].bytes = bytes;
	embeddedFiles[numEmbeddedFiles].size = size;
	numEmbeddedFiles++;

#ifdef OF_HAVE_THREADS
	OFEnsure(OFPlainMutexUnlock(&mutex) == 0);
#endif
}

@implementation OFEmbeddedURIHandler
- (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode
{
	const char *path;

	if (![URI.scheme isEqual: @"objfw-embedded"] || URI.host.length > 0 ||
	    URI.port != nil || URI.user != nil || URI.password != nil ||
	    URI.query != nil || URI.fragment != nil)
		@throw [OFInvalidArgumentException exception];

	if (![mode isEqual: @"r"])
		@throw [OFOpenItemFailedException exceptionWithURI: URI
							      mode: mode
							     errNo: EROFS];

	if ((path = URI.path.UTF8String) == NULL) {
		@throw [OFInvalidArgumentException exception];
	}

#ifdef OF_HAVE_THREADS
	OFEnsure(OFPlainMutexLock(&mutex) == 0);
	@try {
#endif
		for (size_t i = 0; i < numEmbeddedFiles; i++) {
			if (strcmp(embeddedFiles[i].name, path) != 0)
				continue;

			return [OFMemoryStream
			    streamWithMemoryAddress: (void *)
							 embeddedFiles[i].bytes
					       size: embeddedFiles[i].size
					   writable: false];
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		OFEnsure(OFPlainMutexUnlock(&mutex) == 0);
	}
#endif

	@throw [OFOpenItemFailedException exceptionWithURI: URI
						      mode: mode
						     errNo: ENOENT];
}
@end
