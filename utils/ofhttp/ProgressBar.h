/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
