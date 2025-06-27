/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#if defined(OF_HAVE_PTHREADS)
# include "platform/POSIX/OFTLSKey.m"
#elif defined(OF_WINDOWS)
# include "platform/Windows/OFTLSKey.m"
#elif defined(OF_MORPHOS)
# include "platform/MorphOS/OFTLSKey.m"
#elif defined(OF_AMIGAOS)
# include "platform/AmigaOS/OFTLSKey.m"
#endif
