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

#include <stdlib.h>

#import "macros.h"

#ifndef OF_HAVE_ATOMIC_OPS
# error No atomic operations available!
#endif

#if !defined(OF_HAVE_THREADS)
# import "atomic_no_threads.h"
#elif defined(OF_X86_64_ASM) || defined(OF_X86_ASM)
# import "atomic_x86.h"
#elif defined(OF_POWERPC_ASM) && !defined(__APPLE_CC__) && !defined(OF_AIX)
# import "atomic_powerpc.h"
#elif defined(OF_HAVE_ATOMIC_BUILTINS)
# import "atomic_builtins.h"
#elif defined(OF_HAVE_SYNC_BUILTINS)
# import "atomic_sync_builtins.h"
#elif defined(OF_HAVE_OSATOMIC)
# import "atomic_osatomic.h"
#else
# error No atomic operations available!
#endif
