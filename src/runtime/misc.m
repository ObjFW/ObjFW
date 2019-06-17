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

#include "ObjFWRT.h"
#include "private.h"

static objc_enumeration_mutation_handler_t enumerationMutationHandler = NULL;

void
objc_enumerationMutation(id object)
{
	if (enumerationMutationHandler != NULL)
		enumerationMutationHandler(object);
	else
		OBJC_ERROR("Object was mutated during enumeration!");
}

void
objc_setEnumerationMutationHandler(objc_enumeration_mutation_handler_t handler)
{
	enumerationMutationHandler = handler;
}
