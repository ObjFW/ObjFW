/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#define CASE_MISSING_IS_KEEP(nr)				\
	case nr:						\
		if OF_UNLIKELY ((c & 0xFF) < page##nr##Start) {	\
			output[i] = (unsigned char)c;		\
			continue;				\
		}						\
								\
		index = (c & 0xFF) - page##nr##Start;		\
								\
		if (index >= page##nr##Size) {			\
			output[i] = (unsigned char)c;		\
			continue;				\
		}						\
								\
		if (page##nr[index] == 0x00) {			\
			if (lossy) {				\
				output[i] = '?';		\
				continue;			\
			} else					\
				return false;			\
		}						\
								\
		output[i] = page##nr[index];			\
		break;
#define CASE_MISSING_IS_ERROR(nr)					\
	case 0x##nr:							\
		if OF_UNLIKELY ((c & 0xFF) < page##nr##Start) {		\
			if (lossy) {					\
				output[i] = '?';			\
				continue;				\
			} else						\
				return false;				\
		}							\
									\
		index = (c & 0xFF) - page##nr##Start;			\
									\
		if (index >= page##nr##Size || page##nr[index] == 0) {	\
			if (lossy) {					\
				output[i] = '?';			\
				continue;				\
			} else						\
				return false;				\
		}							\
									\
		output[i] = page##nr[index];				\
		break;
