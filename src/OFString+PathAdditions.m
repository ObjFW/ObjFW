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

#include "config.h"

#import "platform.h"

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
# import "OFString+PathAdditions_DOS.m"
#elif defined(OF_AMIGAOS)
# import "OFString+PathAdditions_AmigaOS.m"
#elif defined(OF_NINTENDO_3DS) || defined(OF_WII)
# import "OFString+PathAdditions_libfat.m"
#else
# import "OFString+PathAdditions_UNIX.m"
#endif
