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

#include "config.h"

#include <math.h>

#import "OFDate.h"
#import "OFStdIOStream.h"
#import "OFTimer.h"
#import "OFLocale.h"

#import "ProgressBar.h"

static const float oneKibibyte = 1024;
static const float oneMebibyte = 1024 * 1024;
static const float oneGibibyte = 1024 * 1024 * 1024;

static const OFTimeInterval updateInterval = 0.1;

#ifdef OF_MINT
/* freemint-gcc does not have trunc() */
# define trunc(x) ((int64_t)(x))
#endif

#ifndef HAVE_TRUNCF
# define truncf(x) trunc(x)
#endif

@implementation ProgressBar
- (instancetype)initWithLength: (unsigned long long)length
		   resumedFrom: (unsigned long long)resumedFrom
		    useUnicode: (bool)useUnicode
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_useUnicode = useUnicode;
		_length = length;
		_resumedFrom = resumedFrom;
		_startDate = [[OFDate alloc] init];
		_lastReceivedDate = [[OFDate alloc] init];
		_drawTimer = [[OFTimer
		    scheduledTimerWithTimeInterval: updateInterval
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

- (void)setReceived: (unsigned long long)received
{
	_received = received;
}

- (void)_drawProgress
{
	float bars, percent;
	int columns, barWidth;

	if ((columns = OFStdOut.columns) >= 0) {
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

	if (_useUnicode) {
		[OFStdOut writeString: @"\r  ▕"];

		for (size_t i = 0; i < (size_t)bars; i++)
			[OFStdOut writeString: @"█"];
		if (bars < barWidth) {
			float rem = bars - truncf(bars);

			if (rem >= 0.875)
				[OFStdOut writeString: @"▉"];
			else if (rem >= 0.75)
				[OFStdOut writeString: @"▊"];
			else if (rem >= 0.625)
				[OFStdOut writeString: @"▋"];
			else if (rem >= 0.5)
				[OFStdOut writeString: @"▌"];
			else if (rem >= 0.375)
				[OFStdOut writeString: @"▍"];
			else if (rem >= 0.25)
				[OFStdOut writeString: @"▎"];
			else if (rem >= 0.125)
				[OFStdOut writeString: @"▏"];
			else
				[OFStdOut writeString: @" "];

			for (size_t i = 0; i < barWidth - (size_t)bars - 1; i++)
				[OFStdOut writeString: @" "];
		}

		[OFStdOut writeFormat: @"▏ %,6.2f%% ", percent];
	} else {
		[OFStdOut writeString: @"\r  ["];

		for (size_t i = 0; i < (size_t)bars; i++)
			[OFStdOut writeString: @"#"];
		if (bars < barWidth) {
			float rem = bars - truncf(bars);

			if (rem >= 0.75)
				[OFStdOut writeString: @"O"];
			else if (rem >= 0.5)
				[OFStdOut writeString: @"o"];
			else if (rem >= 0.25)
				[OFStdOut writeString: @"."];
			else
				[OFStdOut writeString: @" "];

			for (size_t i = 0; i < barWidth - (size_t)bars - 1; i++)
				[OFStdOut writeString: @" "];
		}

		[OFStdOut writeFormat: @"] %,6.2f%% ", percent];
	}

	if (percent == 100) {
		double timeInterval = -_startDate.timeIntervalSinceNow;

		_BPS = (float)_received / (float)timeInterval;
		_ETA = timeInterval;
	}

	if (isinf(_ETA))
		[OFStdOut writeString: @"--:--:-- "];
	else if (_ETA >= 99 * 3600) {
		OFString *num = [OFString stringWithFormat:
		    @"%,4.2f", _ETA / (24 * 3600)];
		[OFStdOut writeString: OF_LOCALIZED(@"eta_days",
		    @"%[num] d ",
		    @"num", num)];
	} else
		[OFStdOut writeFormat: @"%2u:%02u:%02u ",
		    (uint8_t)(_ETA / 3600), (uint8_t)(_ETA / 60) % 60,
		    (uint8_t)_ETA % 60];

	if (_BPS >= oneGibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneGibibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_gibs",
		    @"%[num] GiB/s",
		    @"num", num)];
	} else if (_BPS >= oneMebibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneMebibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_mibs",
		    @"%[num] MiB/s",
		    @"num", num)];
	} else if (_BPS >= oneKibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneKibibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_kibs",
		    @"%[num] KiB/s",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_bps",
		    @"%[num] B/s  ",
		    @"num", num)];
	}
}

- (void)_drawReceived
{
	[OFStdOut writeString: @"\r  "];

	if (_resumedFrom + _received >= oneGibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / oneGibibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_gib",
		    @"%[num] GiB",
		    @"num", num)];
	} else if (_resumedFrom + _received >= oneMebibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / oneMebibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_mib",
		    @"%[num] MiB",
		    @"num", num)];
	} else if (_resumedFrom + _received >= oneKibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / oneKibibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_kib",
		    @"%[num] KiB",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%jd", _resumedFrom + _received];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_bytes",
		    @"["
		    @"    ["
		    @"        {'num == 1': '1 byte '},"
		    @"        {'': '%[num] bytes'}"
		    @"    ]"
		    @"]".objectByParsingJSON,
		    @"num", num)];
	}

	[OFStdOut writeString: @" "];

	if (_stopped)
		_BPS = (float)_received /
		    -(float)_startDate.timeIntervalSinceNow;

	if (_BPS >= oneGibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneGibibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_gibs",
		    @"%[num] GiB/s",
		    @"num", num)];
	} else if (_BPS >= oneMebibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneMebibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_mibs",
		    @"%[num] MiB/s",
		    @"num", num)];
	} else if (_BPS >= oneKibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneKibibyte];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_kibs",
		    @"%[num] KiB/s",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS];
		[OFStdOut writeString: OF_LOCALIZED(@"progress_bps",
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
	_BPSWindow[_BPSWindowIndex++ % BPS_WINDOW_SIZE] =
	    (float)(_received - _lastReceived) /
	    -(float)_lastReceivedDate.timeIntervalSinceNow;

	if (_BPSWindowLength < BPS_WINDOW_SIZE)
		_BPSWindowLength++;

	_BPS = 0;
	for (size_t i = 0; i < _BPSWindowLength; i++)
		_BPS += _BPSWindow[i];
	_BPS /= _BPSWindowLength;

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
