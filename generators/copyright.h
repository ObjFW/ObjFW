/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFString.h"

#define COPYRIGHT \
    @"/*\n"								       \
    @" * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, " \
    @"2017,\n"								       \
    @" *               2018\n"						       \
    @" *   Jonathan Schleifer <js@heap.zone>\n"				       \
    @" *\n"								       \
    @" * All rights reserved.\n"					       \
    @" *\n"								       \
    @" * This file is part of ObjFW. It may be distributed under the terms "   \
    @"of the\n"								       \
    @" * Q Public License 1.0, which can be found in the file LICENSE.QPL "    \
    @"included in\n"							       \
    @" * the packaging of this file.\n"					       \
    @" *\n"								       \
    @" * Alternatively, it may be distributed under the terms of the GNU "     \
    @"General\n"							       \
    @" * Public License, either version 2 or 3, which can be found in the "    \
    @"file\n"								       \
    @" * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the "	       \
    @"packaging of this\n"						       \
    @" * file.\n"							       \
    @" */\n"								       \
    @"\n"
