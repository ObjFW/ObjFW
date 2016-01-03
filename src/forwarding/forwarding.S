/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#ifdef OF_APPLE_RUNTIME
# if defined(__x86_64__)
#  include "apple-forwarding-x86_64.S"
# elif defined(__i386__)
#  include "apple-forwarding-i386.S"
# elif defined(__ARM64_ARCH_8__)
#  include "apple-forwarding-arm64.S"
# elif defined(__arm__)
#  include "apple-forwarding-arm.S"
# elif defined(__ppc__)
#  include "apple-forwarding-ppc.S"
# endif
#else
# if defined(__ELF__)
#  if defined(__x86_64__) || defined(__amd64__)
#   include "forwarding-x86_64-elf.S"
#  elif defined(__i386__)
#   include "forwarding-x86-elf.S"
#  elif defined(__arm__) || defined(__ARM__)
#   include "forwarding-arm-elf.S"
#  elif defined(__ppc__) || defined(__PPC__)
#   include "forwarding-ppc-elf.S"
#  elif (defined(_MIPS_SIM) && _MIPS_SIM == _ABIO32) || \
	(defined(__mips_eabi) && _MIPS_SZPTR == 32)
#   include "forwarding-mips-elf.S"
#  endif
# elif defined(_WIN32)
#  if defined(__x86_64__)
#   include "forwarding-x86_64-win64.S"
#  elif defined(__i386__)
#   include "forwarding-x86-win32.S"
#  endif
# endif
#endif
