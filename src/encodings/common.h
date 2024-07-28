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

#define CASE_MISSING_IS_KEEP(nr)				\
	case 0x##nr:						\
		if OF_UNLIKELY ((c & 0xFF) < page##nr##Start) {	\
			output[i] = (unsigned char)c;		\
			continue;				\
		}						\
								\
		idx = (c & 0xFF) - page##nr##Start;		\
								\
		if (idx >= sizeof(page##nr)) {			\
			output[i] = (unsigned char)c;		\
			continue;				\
		}						\
								\
		if (page##nr[idx] == 0) {			\
			if (lossy) {				\
				output[i] = '?';		\
				continue;			\
			} else					\
				return false;			\
		}						\
								\
		output[i] = page##nr[idx];			\
		break;
#define CASE_MISSING_IS_ERROR(nr)					 \
	case 0x##nr:							 \
		if OF_UNLIKELY ((c & 0xFF) < page##nr##Start) {		 \
			if (lossy) {					 \
				output[i] = '?';			 \
				continue;				 \
			} else						 \
				return false;				 \
		}							 \
									 \
		idx = (c & 0xFF) - page##nr##Start;			 \
									 \
		if (idx >= sizeof(page##nr) || page##nr[idx] == 0) {	 \
			if (lossy) {					 \
				output[i] = '?';			 \
				continue;				 \
			} else						 \
				return false;				 \
		}							 \
									 \
		output[i] = page##nr[idx];				 \
		break;
