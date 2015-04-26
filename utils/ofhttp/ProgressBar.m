/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <math.h>

#import "OFDate.h"
#import "OFStdIOStream.h"
#import "OFTimer.h"

#import "ProgressBar.h"

#define GIBIBYTE (1024 * 1024 * 1024)
#define MEBIBYTE (1024 * 1024)
#define KIBIBYTE (1024)

#define BAR_WIDTH 52
#define UPDATE_INTERVAL 0.1

@implementation ProgressBar
- initWithLength: (intmax_t)length
     resumedFrom: (intmax_t)resumedFrom
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_length = length;
		_resumedFrom = resumedFrom;
		_startDate = [[OFDate alloc] init];
		_timer = [[OFTimer
		    scheduledTimerWithTimeInterval: UPDATE_INTERVAL
					    target: self
					  selector: @selector(draw)
					   repeats: true] retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self stop];

	[_timer release];

	[super dealloc];
}

- (void)setReceived: (intmax_t)received
{
	_received = received;
}

- (void)_drawProgress
{
	uint_fast8_t i;
	float bars, percent, bps;

	bars = (float)(_resumedFrom + _received) /
	    (_resumedFrom + _length) * BAR_WIDTH;
	percent = (float)(_resumedFrom + _received) /
	    (_resumedFrom + _length) * 100;

	[of_stdout writeString: @"\r  ▕"];

	for (i = 0; i < (uint_fast8_t)bars; i++)
		[of_stdout writeString: @"█"];
	if (bars < BAR_WIDTH) {
		float rest = bars - floorf(bars);

		if (rest >= 0.875)
			[of_stdout writeString: @"▉"];
		else if (rest >= 0.75)
			[of_stdout writeString: @"▊"];
		else if (rest >= 0.625)
			[of_stdout writeString: @"▋"];
		else if (rest >= 0.5)
			[of_stdout writeString: @"▌"];
		else if (rest >= 0.375)
			[of_stdout writeString: @"▍"];
		else if (rest >= 0.25)
			[of_stdout writeString: @"▎"];
		else if (rest >= 0.125)
			[of_stdout writeString: @"▏"];
		else
			[of_stdout writeString: @" "];

		for (i = 0; i < BAR_WIDTH - (uint_fast8_t)bars - 1; i++)
			[of_stdout writeString: @" "];
	}

	[of_stdout writeFormat: @"▏ %6.2f%% ", percent];

	if (percent == 100)
		bps = (float)_received / -[_startDate timeIntervalSinceNow];
	else
		bps = (float)(_received - _lastReceived) / UPDATE_INTERVAL;

	if (bps >= GIBIBYTE)
		[of_stdout writeFormat: @"%7.2f GiB/s", bps / GIBIBYTE];
	else if (bps >= MEBIBYTE)
		[of_stdout writeFormat: @"%7.2f MiB/s", bps / MEBIBYTE];
	else if (bps >= KIBIBYTE)
		[of_stdout writeFormat: @"%7.2f KiB/s", bps / KIBIBYTE];
	else
		[of_stdout writeFormat: @"%7.2f B/s  ", bps];

	_lastDrawn = [[OFDate date] timeIntervalSince1970];
	_lastReceived = _received;
}

- (void)_drawReceived
{
	float bps;

	if (_resumedFrom + _received >= GIBIBYTE)
		[of_stdout writeFormat:
		    @"\r  %7.2f GiB ",
		    (float)(_resumedFrom + _received) / GIBIBYTE];
	else if (_resumedFrom + _received >= MEBIBYTE)
		[of_stdout writeFormat:
		    @"\r  %7.2f MiB ",
		    (float)(_resumedFrom + _received) / MEBIBYTE];
	else if (_resumedFrom + _received >= KIBIBYTE)
		[of_stdout writeFormat:
		    @"\r  %7.2f KiB ",
		    (float)(_resumedFrom + _received) / KIBIBYTE];
	else
		[of_stdout writeFormat:
		    @"\r  %jd bytes ", _resumedFrom + _received];

	if (_stopped)
		bps = (float)_received / -[_startDate timeIntervalSinceNow];
	else
		bps = (float)(_received - _lastReceived) / UPDATE_INTERVAL;

	if (bps >= GIBIBYTE)
		[of_stdout writeFormat: @"%7.2f GiB/s", bps / GIBIBYTE];
	else if (bps >= MEBIBYTE)
		[of_stdout writeFormat: @"%7.2f MiB/s", bps / MEBIBYTE];
	else if (bps >= KIBIBYTE)
		[of_stdout writeFormat: @"%7.2f KiB/s", bps / KIBIBYTE];
	else
		[of_stdout writeFormat: @"%7.2f B/s  ", bps];

	_lastDrawn = [[OFDate date] timeIntervalSince1970];
	_lastReceived = _received;
}

- (void)draw
{
	if (_length > 0)
		[self _drawProgress];
	else
		[self _drawReceived];
}

- (void)stop
{
	[_timer invalidate];

	_stopped = true;
}
@end
