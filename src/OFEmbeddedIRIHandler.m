/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#import "OFEmbeddedIRIHandler.h"
#import "OFIRI.h"
#import "OFMemoryStream.h"

#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"

#ifdef OF_HAVE_THREADS
# import "OFOnce.h"
# import "OFPlainMutex.h"
#endif

struct EmbeddedFile {
	OFString *path;
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
OFRegisterEmbeddedFile(OFString *path, const uint8_t *bytes, size_t size)
{
#ifdef OF_HAVE_THREADS
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, init);

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
