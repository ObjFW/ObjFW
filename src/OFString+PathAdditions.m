/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include "platform.h"

#if defined(OF_WINDOWS) || defined(OF_MSDOS) || defined(OF_MINT)
# import "platform/Windows/OFString+PathAdditions.m"
#elif defined(OF_AMIGAOS)
# import "platform/AmigaOS/OFString+PathAdditions.m"
#elif defined(OF_WII) || defined(OF_NINTENDO_DS) || \
    defined(OF_NINTENDO_3DS) || defined(OF_NINTENDO_SWITCH)
# import "platform/libfat/OFString+PathAdditions.m"
#else
# import "platform/POSIX/OFString+PathAdditions.m"
#endif
