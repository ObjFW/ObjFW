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

#import "OFString.h"

#define COPYRIGHT							\
    @"/*\n"								\
    @" * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>\n"	\
    @" *\n"								\
    @" * All rights reserved.\n"					\
    @" *\n"								\
    @" * This program is free software: you can redistribute it "	\
    @"and/or modify it\n"						\
    @" * under the terms of the GNU Lesser General Public License "	\
    @"version 3.0 only,\n"						\
    @" * as published by the Free Software Foundation.\n"		\
    @" *\n"								\
    @" * This program is distributed in the hope that it will be "	\
    @"useful, but WITHOUT\n"						\
    @" * ANY WARRANTY; without even the implied warranty of "		\
    @"MERCHANTABILITY or\n"						\
    @" * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General "	\
    @"Public License\n"							\
    @" * version 3.0 for more details.\n"				\
    @" *\n"								\
    @" * You should have received a copy of the GNU Lesser General "	\
    @"Public License\n"							\
    @" * version 3.0 along with this program. If not, see\n"		\
    @" * <https://www.gnu.org/licenses/>.\n"				\
    @" */\n"								\
    @"\n"
