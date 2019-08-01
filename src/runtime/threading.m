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

#include <stdio.h>
#include <stdlib.h>

#import "ObjFWRT.h"
#import "private.h"
#import "mutex.h"
#import "once.h"

static of_rmutex_t globalMutex;

static void
init(void)
{
	if (!of_rmutex_new(&globalMutex))
		OBJC_ERROR("Failed to create global mutex!");
}

void
objc_global_mutex_lock(void)
{
	static of_once_t once_control = OF_ONCE_INIT;
	of_once(&once_control, init);

	if (!of_rmutex_lock(&globalMutex))
		OBJC_ERROR("Failed to lock global mutex!");
}

void
objc_global_mutex_unlock(void)
{
	if (!of_rmutex_unlock(&globalMutex))
		OBJC_ERROR("Failed to unlock global mutex!");
}
