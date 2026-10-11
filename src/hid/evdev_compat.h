/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#ifndef BTN_TRIGGER_HAPPY1
# define BTN_TRIGGER_HAPPY1 0x2C0
#endif
#ifndef BTN_TRIGGER_HAPPY2
# define BTN_TRIGGER_HAPPY2 0x2C1
#endif
#ifndef BTN_TRIGGER_HAPPY3
# define BTN_TRIGGER_HAPPY3 0x2C2
#endif
#ifndef BTN_TRIGGER_HAPPY4
# define BTN_TRIGGER_HAPPY4 0x2C3
#endif
#ifndef BTN_TRIGGER_HAPPY5
# define BTN_TRIGGER_HAPPY5 0x2C4
#endif
#ifndef BTN_TRIGGER_HAPPY6
# define BTN_TRIGGER_HAPPY6 0x2C5
#endif
#ifndef BTN_TRIGGER_HAPPY7
# define BTN_TRIGGER_HAPPY7 0x2C6
#endif
#ifndef BTN_TRIGGER_HAPPY8
# define BTN_TRIGGER_HAPPY8 0x2C7
#endif
#ifndef BTN_TRIGGER_HAPPY9
# define BTN_TRIGGER_HAPPY9 0x2C8
#endif
#ifndef BTN_TRIGGER_HAPPY10
# define BTN_TRIGGER_HAPPY10 0x2C9
#endif
#ifndef BTN_TRIGGER_HAPPY11
# define BTN_TRIGGER_HAPPY11 0x2CA
#endif
#ifndef BTN_TRIGGER_HAPPY12
# define BTN_TRIGGER_HAPPY12 0x2CB
#endif
#ifndef BTN_TRIGGER_HAPPY13
# define BTN_TRIGGER_HAPPY13 0x2CC
#endif
#ifndef BTN_TRIGGER_HAPPY14
# define BTN_TRIGGER_HAPPY14 0x2CD
#endif
#ifndef BTN_TRIGGER_HAPPY15
# define BTN_TRIGGER_HAPPY15 0x2CE
#endif
#ifndef BTN_TRIGGER_HAPPY16
# define BTN_TRIGGER_HAPPY16 0x2CF
#endif
#ifndef BTN_TRIGGER_HAPPY17
# define BTN_TRIGGER_HAPPY17 0x2D0
#endif
#ifndef BTN_TRIGGER_HAPPY18
# define BTN_TRIGGER_HAPPY18 0x2D1
#endif
#ifndef BTN_TRIGGER_HAPPY19
# define BTN_TRIGGER_HAPPY19 0x2D2
#endif
#ifndef BTN_TRIGGER_HAPPY20
# define BTN_TRIGGER_HAPPY20 0x2D3
#endif
#ifndef BTN_TRIGGER_HAPPY21
# define BTN_TRIGGER_HAPPY21 0x2D4
#endif
#ifndef BTN_TRIGGER_HAPPY22
# define BTN_TRIGGER_HAPPY22 0x2D5
#endif
#ifndef BTN_TRIGGER_HAPPY23
# define BTN_TRIGGER_HAPPY23 0x2D6
#endif
#ifndef BTN_TRIGGER_HAPPY24
# define BTN_TRIGGER_HAPPY24 0x2D7
#endif
#ifndef BTN_TRIGGER_HAPPY25
# define BTN_TRIGGER_HAPPY25 0x2D8
#endif
#ifndef BTN_TRIGGER_HAPPY26
# define BTN_TRIGGER_HAPPY26 0x2D9
#endif
#ifndef BTN_TRIGGER_HAPPY27
# define BTN_TRIGGER_HAPPY27 0x2DA
#endif
#ifndef BTN_TRIGGER_HAPPY28
# define BTN_TRIGGER_HAPPY28 0x2DB
#endif
#ifndef BTN_TRIGGER_HAPPY29
# define BTN_TRIGGER_HAPPY29 0x2DC
#endif
#ifndef BTN_TRIGGER_HAPPY30
# define BTN_TRIGGER_HAPPY30 0x2DD
#endif
#ifndef BTN_TRIGGER_HAPPY31
# define BTN_TRIGGER_HAPPY31 0x2DE
#endif
#ifndef BTN_TRIGGER_HAPPY32
# define BTN_TRIGGER_HAPPY32 0x2DF
#endif
#ifndef BTN_TRIGGER_HAPPY33
# define BTN_TRIGGER_HAPPY33 0x2E0
#endif
#ifndef BTN_TRIGGER_HAPPY34
# define BTN_TRIGGER_HAPPY34 0x2E1
#endif
#ifndef BTN_TRIGGER_HAPPY35
# define BTN_TRIGGER_HAPPY35 0x2E2
#endif
#ifndef BTN_TRIGGER_HAPPY36
# define BTN_TRIGGER_HAPPY36 0x2E3
#endif
#ifndef BTN_TRIGGER_HAPPY37
# define BTN_TRIGGER_HAPPY37 0x2E4
#endif
#ifndef BTN_TRIGGER_HAPPY38
# define BTN_TRIGGER_HAPPY38 0x2E5
#endif
#ifndef BTN_TRIGGER_HAPPY39
# define BTN_TRIGGER_HAPPY39 0x2E6
#endif
#ifndef BTN_TRIGGER_HAPPY40
# define BTN_TRIGGER_HAPPY40 0x2E7
#endif
