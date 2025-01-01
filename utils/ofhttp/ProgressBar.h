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

#import "OFObject.h"

@class OFDate;
@class OFTimer;

#define BPS_WINDOW_SIZE 10

@interface ProgressBar: OFObject
{
	bool _useUnicode;
	unsigned long long _received, _lastReceived, _length, _resumedFrom;
	OFDate *_startDate, *_lastReceivedDate;
	OFTimer *_drawTimer, *_BPSTimer;
	bool _stopped;
	float _BPS;
	double _ETA;
	float _BPSWindow[BPS_WINDOW_SIZE];
	size_t _BPSWindowIndex, _BPSWindowLength;
}

- (instancetype)initWithLength: (unsigned long long)length
		   resumedFrom: (unsigned long long)resumedFrom
		    useUnicode: (bool)useUnicode OF_DESIGNATED_INITIALIZER;
- (void)setReceived: (unsigned long long)received;
- (void)draw;
- (void)calculateBPSAndETA;
- (void)stop;
@end
