/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone> *
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

#include <stdlib.h>	/* Make sure we have any libc include */

#ifdef HAVE_UNISTD_H
# ifdef __GLIBC__
#  undef __USE_XOPEN	/* Needed to avoid old glibc using __block */
# endif
# include <unistd.h>
# ifdef __GLIBC__
#  define __USE_XOPEN 1
# endif
#endif
