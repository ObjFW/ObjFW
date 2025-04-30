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

#if defined(OF_MORPHOS)
.section .eh_frame, "aw"
	.long 0
.section .ctors, "aw"
	.long 0
#else
.section .list___EH_FRAME_BEGINS__, "aw"
	.long 0
.section .dlist___EH_FRAME_OBJECTS__, "aw"
	.long 0
.section .list___CTOR_LIST__, "aw"
	.long 0
#endif
