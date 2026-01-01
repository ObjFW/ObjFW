/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

@interface ProgressBar ()
- (void)_calculateBPSAndETA;
@end

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
		_drawTimer = objc_retain([OFTimer
		    scheduledTimerWithTimeInterval: updateInterval
					    target: self
					  selector: @selector(draw)
					   repeats: true]);
		_BPSTimer = objc_retain([OFTimer
		    scheduledTimerWithTimeInterval: 1.0
					    target: self
					  selector: @selector(
							_calculateBPSAndETA)
					   repeats: true]);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self stop];

	objc_release(_startDate);
	objc_release(_lastReceivedDate);
	objc_release(_drawTimer);
	objc_release(_BPSTimer);

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

	if ((columns = OFStdErr.columns) >= 0) {
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
		[OFStdErr writeString: @"\r  ▕"];

		for (size_t i = 0; i < (size_t)bars; i++)
			[OFStdErr writeString: @"█"];
		if (bars < barWidth) {
			float rem = bars - truncf(bars);

			if (rem >= 0.875)
				[OFStdErr writeString: @"▉"];
			else if (rem >= 0.75)
				[OFStdErr writeString: @"▊"];
			else if (rem >= 0.625)
				[OFStdErr writeString: @"▋"];
			else if (rem >= 0.5)
				[OFStdErr writeString: @"▌"];
			else if (rem >= 0.375)
				[OFStdErr writeString: @"▍"];
			else if (rem >= 0.25)
				[OFStdErr writeString: @"▎"];
			else if (rem >= 0.125)
				[OFStdErr writeString: @"▏"];
			else
				[OFStdErr writeString: @" "];

			for (size_t i = 0; i < barWidth - (size_t)bars - 1; i++)
				[OFStdErr writeString: @" "];
		}

		[OFStdErr writeFormat: @"▏ %,6.2f%% ", percent];
	} else {
		[OFStdErr writeString: @"\r  ["];

		for (size_t i = 0; i < (size_t)bars; i++)
			[OFStdErr writeString: @"#"];
		if (bars < barWidth) {
			float rem = bars - truncf(bars);

			if (rem >= 0.75)
				[OFStdErr writeString: @"O"];
			else if (rem >= 0.5)
				[OFStdErr writeString: @"o"];
			else if (rem >= 0.25)
				[OFStdErr writeString: @"."];
			else
				[OFStdErr writeString: @" "];

			for (size_t i = 0; i < barWidth - (size_t)bars - 1; i++)
				[OFStdErr writeString: @" "];
		}

		[OFStdErr writeFormat: @"] %,6.2f%% ", percent];
	}

	if (percent == 100) {
		double timeInterval = -_startDate.timeIntervalSinceNow;

		_BPS = (float)_received / (float)timeInterval;
		_ETA = timeInterval;
	}

	if (isinf(_ETA))
		[OFStdErr writeString: @"--:--:-- "];
	else if (_ETA >= 99 * 3600) {
		OFString *num = [OFString stringWithFormat:
		    @"%,4.2f", _ETA / (24 * 3600)];
		[OFStdErr writeString: OF_LOCALIZED(@"eta_days",
		    @"%[num] d ",
		    @"num", num)];
	} else
		[OFStdErr writeFormat: @"%2u:%02u:%02u ",
		    (uint8_t)(_ETA / 3600), (uint8_t)(_ETA / 60) % 60,
		    (uint8_t)_ETA % 60];

	if (_BPS >= oneGibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneGibibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_gibs",
		    @"%[num] GiB/s",
		    @"num", num)];
	} else if (_BPS >= oneMebibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneMebibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_mibs",
		    @"%[num] MiB/s",
		    @"num", num)];
	} else if (_BPS >= oneKibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneKibibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_kibs",
		    @"%[num] KiB/s",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_bps",
		    @"%[num] B/s  ",
		    @"num", num)];
	}
}

- (void)_drawReceived
{
	[OFStdErr writeString: @"\r  "];

	if (_resumedFrom + _received >= oneGibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / oneGibibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_gib",
		    @"%[num] GiB",
		    @"num", num)];
	} else if (_resumedFrom + _received >= oneMebibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / oneMebibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_mib",
		    @"%[num] MiB",
		    @"num", num)];
	} else if (_resumedFrom + _received >= oneKibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", (float)(_resumedFrom + _received) / oneKibibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_kib",
		    @"%[num] KiB",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%jd", _resumedFrom + _received];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_bytes",
		    @"["
		    @"    ["
		    @"        {'num == 1': '1 byte '},"
		    @"        {'': '%[num] bytes'}"
		    @"    ]"
		    @"]".objectByParsingJSON,
		    @"num", num)];
	}

	[OFStdErr writeString: @" "];

	if (_stopped)
		_BPS = (float)_received /
		    -(float)_startDate.timeIntervalSinceNow;

	if (_BPS >= oneGibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneGibibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_gibs",
		    @"%[num] GiB/s",
		    @"num", num)];
	} else if (_BPS >= oneMebibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneMebibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_mibs",
		    @"%[num] MiB/s",
		    @"num", num)];
	} else if (_BPS >= oneKibibyte) {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS / oneKibibyte];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_kibs",
		    @"%[num] KiB/s",
		    @"num", num)];
	} else {
		OFString *num = [OFString stringWithFormat:
		    @"%,7.2f", _BPS];
		[OFStdErr writeString: OF_LOCALIZED(@"progress_bps",
		    @"%[num] B/s  ",
		    @"num", num)];
	}
}

- (void)draw
{
	OFStdErr.cursorVisible = false;

	if (_length > 0)
		[self _drawProgress];
	else
		[self _drawReceived];
}

- (void)_calculateBPSAndETA
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
	objc_release(_lastReceivedDate);
	_lastReceivedDate = nil;
	_lastReceivedDate = [[OFDate alloc] init];
}

- (void)stop
{
	[_drawTimer invalidate];
	[_BPSTimer invalidate];

	_stopped = true;

	OFStdErr.cursorVisible = true;
}
@end
