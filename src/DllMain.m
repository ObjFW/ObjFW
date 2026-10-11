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

#include "config.h"

#include <windows.h>

#ifdef OF_HAVE_THREADS
extern void _OFPlainThreadExitHandler(void);
#endif

WINBOOL WINAPI
DllMain(HINSTANCE hinst, DWORD reason, LPVOID reserved)
{
	switch (reason) {
	case DLL_THREAD_DETACH:
#ifdef OF_HAVE_THREADS
		_OFPlainThreadExitHandler();
#endif
		break;
	}

	return TRUE;
}
