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

/* Provide compatibility defines for old evdev headers. */

#include <linux/input.h>

#ifndef BTN_NORTH
# define BTN_NORTH BTN_X
#endif
#ifndef BTN_SOUTH
# define BTN_SOUTH BTN_A
#endif
#ifndef BTN_WEST
# define BTN_WEST BTN_Y
#endif
#ifndef BTN_EAST
# define BTN_EAST BTN_B
#endif

#ifndef BTN_DPAD_UP
# define BTN_DPAD_UP 0x220
#endif
#ifndef BTN_DPAD_DOWN
# define BTN_DPAD_DOWN 0x221
#endif
#ifndef BTN_DPAD_LEFT
# define BTN_DPAD_LEFT 0x222
#endif
#ifndef BTN_DPAD_RIGHT
# define BTN_DPAD_RIGHT 0x223
#endif
