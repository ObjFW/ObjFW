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

#include "platform.h"

#if defined(OF_WINDOWS) || defined(OF_MSDOS) || defined(OF_MINT)
# import "platform/Windows/OFString+PathAdditions.m"
#elif defined(OF_AMIGAOS)
# import "platform/AmigaOS/OFString+PathAdditions.m"
#elif defined(OF_NINTENDO_3DS) || defined(OF_WII) || \
    defined(OF_NINTENDO_SWITCH)
# import "platform/libfat/OFString+PathAdditions.m"
#else
# import "platform/POSIX/OFString+PathAdditions.m"
#endif
