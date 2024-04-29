/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#include <stdlib.h>
#include <string.h>

#import "OFEmbeddedIRIHandler.h"
#import "OFIRI.h"
#import "OFMemoryStream.h"

#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"

#ifdef OF_HAVE_THREADS
# import "OFOnce.h"
# import "OFPlainMutex.h"
#endif

static struct EmbeddedFile {
	OFString *path;
	const uint8_t *bytes;
	size_t size;
} *embeddedFiles = NULL;
static size_t numEmbeddedFiles = 0;
#ifdef OF_HAVE_THREADS
static OFPlainMutex mutex;
static OFOnceControl mutexOnceControl = OFOnceControlInitValue;

static void
initMutex(void)
{
	OFEnsure(OFPlainMutexNew(&mutex) == 0);
}
#endif

void
OFRegisterEmbeddedFile(OFString *path, const uint8_t *bytes, size_t size)
{
#ifdef OF_HAVE_THREADS
	OFOnce(&mutexOnceControl, initMutex);

	OFEnsure(OFPlainMutexLock(&mutex) == 0);
#endif

	embeddedFiles = realloc(embeddedFiles,
	    sizeof(*embeddedFiles) * (numEmbeddedFiles + 1));
	OFEnsure(embeddedFiles != NULL);

	embeddedFiles[numEmbeddedFiles].path = path;
	embeddedFiles[numEmbeddedFiles].bytes = bytes;
	embeddedFiles[numEmbeddedFiles].size = size;
	numEmbeddedFiles++;

#ifdef OF_HAVE_THREADS
	OFEnsure(OFPlainMutexUnlock(&mutex) == 0);
#endif
}

@implementation OFEmbeddedIRIHandler
#ifdef OF_HAVE_THREADS
+ (void)initialize
{
	if (self == [OFEmbeddedIRIHandler class])
		OFOnce(&mutexOnceControl, initMutex);
}
#endif

- (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	OFString *path;

	if (![IRI.scheme isEqual: @"embedded"] || IRI.host.length > 0 ||
	    IRI.port != nil || IRI.user != nil || IRI.password != nil ||
	    IRI.query != nil || IRI.fragment != nil)
		@throw [OFInvalidArgumentException exception];

	if (![mode isEqual: @"r"])
		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: mode
							     errNo: EROFS];

	if ((path = IRI.path) == nil) {
		@throw [OFInvalidArgumentException exception];
	}

#ifdef OF_HAVE_THREADS
	OFEnsure(OFPlainMutexLock(&mutex) == 0);
	@try {
#endif
		for (size_t i = 0; i < numEmbeddedFiles; i++) {
			if (![embeddedFiles[i].path isEqual: path])
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

	@throw [OFOpenItemFailedException exceptionWithIRI: IRI
						      mode: mode
						     errNo: ENOENT];
}
@end
