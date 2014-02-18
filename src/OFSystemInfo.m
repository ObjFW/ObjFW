/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#define __NO_EXT_QNX

#include "config.h"

#import "OFSystemInfo.h"

#include <unistd.h>

#ifdef __QNX__
# include <sys/syspage.h>
#endif

#ifdef _WIN32
# include <windows.h>
#endif

#import "macros.h"

static size_t pageSize;
static size_t numberOfCPUs;

@implementation OFSystemInfo
+ (void)initialize
{
	if (self != [OFSystemInfo class])
		return;

#if defined(_WIN32)
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	pageSize = si.dwPageSize;
	numberOfCPUs = si.dwNumberOfProcessors;
#elif defined(__QNX__)
	if ((pageSize = sysconf(_SC_PAGESIZE)) < 1)
		pageSize = 4096;
	numberOfCPUs = _syspage_ptr->num_cpu;
#else
# if defined(HAVE_SYSCONF) && defined(_SC_PAGESIZE)
	if ((pageSize = sysconf(_SC_PAGESIZE)) < 1)
# endif
		pageSize = 4096;
# if defined(HAVE_SYSCONF) && defined(_SC_NPROCESSORS_CONF)
	if ((numberOfCPUs = sysconf(_SC_NPROCESSORS_CONF)) < 1)
# endif
		numberOfCPUs = 1;
#endif
}

+ alloc
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (size_t)pageSize
{
	return pageSize;
}

+ (size_t)numberOfCPUs
{
	return numberOfCPUs;
}
@end
