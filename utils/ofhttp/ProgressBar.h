/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFObject.h"

@class OFDate;
@class OFTimer;

@interface ProgressBar: OFObject
{
	intmax_t _received, _lastReceived, _length, _resumedFrom;
	OFDate *_startDate, *_lastReceivedDate;
	OFTimer *_drawTimer, *_BPSTimer;
	bool _stopped;
	float _BPS;
	double _ETA;
}

- (instancetype)initWithLength: (intmax_t)length
		   resumedFrom: (intmax_t)resumedFrom;
- (void)setReceived: (intmax_t)received;
- (void)draw;
- (void)calculateBPSAndETA;
- (void)stop;
@end
