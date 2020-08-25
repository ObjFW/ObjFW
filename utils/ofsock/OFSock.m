/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFPair.h"
#import "OFStdIOStream.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFTCPSocket.h"
#import "OFURL.h"

#define BUFFER_LEN 4096

@interface OFSock: OFObject <OFApplicationDelegate, OFStreamDelegate>
{
	char _buffer[BUFFER_LEN];
	OFMutableArray OF_GENERIC(OFPair OF_GENERIC(OFStream *, OFStream *) *)
	    *_streams;
	int _errors;
}
@end

OF_APPLICATION_DELEGATE(OFSock)

static OFPair OF_GENERIC(OFStream *, OFStream *) *
streamFromString(OFString *string)
{
	OFURL *URL;
	OFString *scheme;

	if ([string isEqual: @"-"])
		return [OFPair pairWithFirstObject: of_stdin
				      secondObject: of_stdout];

	URL = [OFURL URLWithString: string];
	scheme = URL.scheme;

	if ([scheme isEqual: @"tcp"]) {
		OFTCPSocket *sock = [OFTCPSocket socket];

		if (URL.port == nil) {
			[of_stderr writeLine: @"Need a port!"];
			[OFApplication terminateWithStatus: 1];
		}

		[sock connectToHost: URL.host
			       port: URL.port.shortValue];

		return [OFPair pairWithFirstObject: sock
				      secondObject: sock];
	}

	[of_stderr writeFormat: @"Invalid protocol: %@\n", scheme];
	[OFApplication terminateWithStatus: 1];
	abort();
}

@implementation OFSock
- (void)applicationDidFinishLaunching
{
	OFArray OF_GENERIC(OFString *) *arguments = [OFApplication arguments];

	if (arguments.count < 1) {
		[of_stderr writeLine: @"Need at least one argument!"];
		[OFApplication terminateWithStatus: 1];
	}

	_streams = [[OFMutableArray alloc] init];

	for (OFString *argument in arguments) {
		OFPair *pair = streamFromString(argument);

		[pair.firstObject setDelegate: self];

		[_streams addObject: pair];
	}

	if (arguments.count == 1) {
		of_stdin.delegate = self;

		[_streams addObject:
		    [OFPair pairWithFirstObject: of_stdin
				   secondObject: of_stdout]];
	}

	for (OFPair *pair in _streams)
		[pair.firstObject asyncReadIntoBuffer: _buffer
					       length: BUFFER_LEN];
}

- (void)removeDeadStream: (OFStream *)stream
{
	size_t count = _streams.count;

	for (size_t i = 0; i < count; i++) {
		if ([[_streams objectAtIndex: i] firstObject] == stream) {
			[_streams removeObjectAtIndex: i];
			break;
		}
	}

	if (_streams.count < 2)
		[OFApplication terminateWithStatus: _errors];
}

-      (bool)stream: (OFStream *)stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	if (exception != nil) {
		[of_stderr writeFormat: @"Exception on stream %@: %@\n",
					stream, exception];
		_errors++;
		[self removeDeadStream: stream];
		return false;
	}

	if (stream.atEndOfStream) {
		[self removeDeadStream: stream];
		return false;
	}

	for (OFPair *pair in _streams) {
		if (pair.firstObject == stream)
			continue;

		[pair.secondObject writeBuffer: buffer
					length: length];
	}

	return true;
}
@end
