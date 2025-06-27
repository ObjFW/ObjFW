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

#import "ObjFWRT.h"
#import "private.h"

#import "OFPlainMutex.h"

extern int OFPlainMutexNew(OFPlainMutex *mutex) OF_VISIBILITY_INTERNAL;
extern int OFPlainMutexLock(OFPlainMutex *mutex) OF_VISIBILITY_INTERNAL;
extern int OFPlainMutexTryLock(OFPlainMutex *mutex) OF_VISIBILITY_INTERNAL;
extern int OFPlainMutexUnlock(OFPlainMutex *mutex) OF_VISIBILITY_INTERNAL;
extern int OFPlainMutexFree(OFPlainMutex *mutex) OF_VISIBILITY_INTERNAL;
extern int OFPlainRecursiveMutexNew(OFPlainRecursiveMutex *rmutex)
    OF_VISIBILITY_INTERNAL;
extern int OFPlainRecursiveMutexLock(OFPlainRecursiveMutex *rmutex)
    OF_VISIBILITY_INTERNAL;
extern int OFPlainRecursiveMutexTryLock(OFPlainRecursiveMutex *rmutex)
    OF_VISIBILITY_INTERNAL;
extern int OFPlainRecursiveMutexUnlock(OFPlainRecursiveMutex *rmutex)
    OF_VISIBILITY_INTERNAL;
extern int OFPlainRecursiveMutexFree(OFPlainRecursiveMutex *rmutex)
    OF_VISIBILITY_INTERNAL;

#include "../OFPlainMutex.m"
