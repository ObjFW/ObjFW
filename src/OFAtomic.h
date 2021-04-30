/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
# import "OFAtomic_no_threads.h"
#elif (defined(OF_X86_64) || defined(OF_X86)) && defined(__GNUC__)
# import "OFAtomic_x86.h"
#elif defined(OF_POWERPC) && defined(__GNUC__) && !defined(__APPLE_CC__) && \
    !defined(OF_AIX)
# import "OFAtomic_powerpc.h"
#elif defined(OF_HAVE_ATOMIC_BUILTINS)
# import "OFAtomic_builtins.h"
#elif defined(OF_HAVE_SYNC_BUILTINS)
# import "OFAtomic_sync_builtins.h"
#elif defined(OF_HAVE_OSATOMIC)
# import "OFAtomic_osatomic.h"
#else
# error No atomic operations available!
#endif
