/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include "runtime.h"
#include "runtime-private.h"

static void (*enumeration_mutation_handler)(id) = NULL;

void
objc_enumerationMutation(id obj)
{
	if (enumeration_mutation_handler != NULL)
		enumeration_mutation_handler(obj);
	else
		OBJC_ERROR("Object was mutated during enumeration!");
}

void
objc_setEnumerationMutationHandler(void (*handler)(id))
{
	enumeration_mutation_handler = handler;
}
