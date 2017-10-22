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

#include "config.h"

#include <math.h>

#import "OFDate.h"
#import "OFStdIOStream.h"
#import "OFTimer.h"
#import "OFLocalization.h"

#import "ProgressBar.h"

#define GIBIBYTE (1024 * 1024 * 1024)
#define MEBIBYTE (1024 * 1024)
#define KIBIBYTE (1024)

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
		_lastReceivedDate = [[OFDate alloc] init];
		_drawTimer = [[OFTimer
		    scheduledTimerWithTimeInterval: UPDATE_INTERVAL
					    target: self
					  selector: @selector(draw)
					   repeats: true] retain];
		_BPSTimer = [[OFTimer
		    scheduledTimerWithTimeInterval: 1.0
					    target: self
					  selector: @selector(
							calculateBPSAndETA)
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

	[_startDate release];
	[_lastReceivedDate release];
	[_drawTimer release];
	[_BPSTimer release];

	[super dealloc];
}

- (void)setReceived: (intmax_t)received
{
	_received = received;
}

- (void)_drawProgress
{
	float bars, percent;
	int columns, barWidth;

	if ((columns = [of_stdout columns]) >= 0) {
		if (columns > 37)
			barWidth = columns - 37;
		else
			barWidth = 0;
	} else
		barWidth = 43;

	bars = (float)(_resumedFrom + _received) /
	    (float)(_resumedFrom + _length) * barWidth;
	percent = (float)(_resumedFrom + _received) /
	    (float)(_resumedFrom + _length) * 100;

	[of_stdout writeString: @"\r  ▕"];

	for (size_t i = 0; i < (size_t)bars; i++)
		[of_stdout writeString: @"█"];
	if (bars < barWidth) {
		float rem = bars - floorf(bars);

		if (rem >= 0.875)
			[of_stdout writeString: @"▉"];
		else if (rem >= 0.75)
			[of_stdout writeString: @"▊"];
		else if (rem >= 0.625)
			[of_stdout writeString: @"▋"];
		else if (rem >= 0.5)
			[of_stdout writeString: @"▌"];
		else if (rem >= 0.375)
			[of_stdout writeString: @"▍"];
		else if (rem >= 0.25)
			[of_stdout writeString: @"▎"];
		else if (rem >= 0.125)
			[of_stdout writeString: @"▏"];
		else
			[of_stdout writeString: @" "];

		for (size_t i = 0; i < barWidth - (size_t)bars - 1; i++)
			[of_stdout writeString: @" "];
	}

	[of_stdout writeFormat: @"▏ %,6.2f%% ", percent];

	if (percent == 100) {
		double timeInterval = -[_startDate timeIntervalSinceNow];

		_BPS = (float)_received / (float)timeInterval;
		_ETA = timeInterval;
	}

	if (isinf(_ETA))
		[of_stdout writeString: @"--:--:-- "];
	else if (_ETA >= 99 * 3600) {
		OFString *num = [OFString stringWithFormat:
		    @"%,4.2f", _ETA / (24 * 3600)];
		[of_stdout writeString: OF_LOCALIZED(@"eta_days",
		    @"%[num] d ",
		    @"num", num)];
	} else
		[of_stdout writeFormat: @"%2u:%02u:%02u ",
		    (uint8_t)(_ETA / 3600), (uint8_t)(_ETA / 60) % 60,
		    (uint8_t)_ETA % 60];

	if (_BPS >= GIBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / GIBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_gibs",
		    @"%[num] GiB/s",
		    @"num", num)];
	} else if (_BPS >= MEBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / MEBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_mibs",
		    @"%[num] MiB/s",
		    @"num", num)];
	} else if (_BPS >= KIBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / KIBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_kibs",
		    @"%[num] KiB/s",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS];
		[of_stdout writeString: OF_LOCALIZED(@"progress_bps",
		    @"%[num] B/s  ",
		    @"num", num)];
	}
}

- (void)_drawReceived
{
	[of_stdout writeString: @"\r  "];

	if (_resumedFrom + _received >= GIBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / GIBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_gib",
		    @"%[num] GiB",
		    @"num", num)];
	} else if (_resumedFrom + _received >= MEBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / MEBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_mib",
		    @"%[num] MiB",
		    @"num", num)];
	} else if (_resumedFrom + _received >= KIBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / KIBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_kib",
		    @"%[num] KiB",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%jd", _resumedFrom + _received];
		[of_stdout writeString: OF_LOCALIZED(@"progress_bytes",
		    @"%[num] bytes",
		    @"num", num)];
	}

	[of_stdout writeString: @" "];

	if (_stopped)
		_BPS = (float)_received /
		    -(float)[_startDate timeIntervalSinceNow];

	if (_BPS >= GIBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / GIBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_gibs",
		    @"%[num] GiB/s",
		    @"num", num)];
	} else if (_BPS >= MEBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / MEBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_mibs",
		    @"%[num] MiB/s",
		    @"num", num)];
	} else if (_BPS >= KIBIBYTE) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / KIBIBYTE];
		[of_stdout writeString: OF_LOCALIZED(@"progress_kibs",
		    @"%[num] KiB/s",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS];
		[of_stdout writeString: OF_LOCALIZED(@"progress_bps",
		    @"%[num] B/s  ",
		    @"num", num)];
	}
}

- (void)draw
{
	if (_length > 0)
		[self _drawProgress];
	else
		[self _drawReceived];
}

- (void)calculateBPSAndETA
{
	_BPS = (float)(_received - _lastReceived) /
	    -(float)[_lastReceivedDate timeIntervalSinceNow];
	_ETA = (double)(_length - _received) / _BPS;

	_lastReceived = _received;
	[_lastReceivedDate release];
	_lastReceivedDate = [[OFDate alloc] init];
}

- (void)stop
{
	[_drawTimer invalidate];
	[_BPSTimer invalidate];

	_stopped = true;
}
@end
