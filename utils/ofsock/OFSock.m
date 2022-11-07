/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
#import "OFURI.h"

#define bufferLen 4096

@interface OFSock: OFObject <OFApplicationDelegate, OFStreamDelegate>
{
	char _buffer[bufferLen];
	OFMutableArray OF_GENERIC(OFPair OF_GENERIC(OFStream *, OFStream *) *)
	    *_streams;
	int _errors;
}
@end

OF_APPLICATION_DELEGATE(OFSock)

static OFPair OF_GENERIC(OFStream *, OFStream *) *
streamFromString(OFString *string)
{
	OFURI *URI;
	OFString *scheme;

	if ([string isEqual: @"-"])
		return [OFPair pairWithFirstObject: OFStdIn
				      secondObject: OFStdOut];

	URI = [OFURI URIWithString: string];
	scheme = URI.scheme;

	if ([scheme isEqual: @"tcp"]) {
		OFTCPSocket *sock = [OFTCPSocket socket];

		if (URI.port == nil) {
			[OFStdErr writeLine: @"Need a port!"];
			[OFApplication terminateWithStatus: 1];
		}

		[sock connectToHost: URI.host port: URI.port.shortValue];
		return [OFPair pairWithFirstObject: sock secondObject: sock];
	}

	[OFStdErr writeFormat: @"Invalid protocol: %@\n", scheme];
	[OFApplication terminateWithStatus: 1];
	abort();
}

@implementation OFSock
- (void)applicationDidFinishLaunching
{
	OFArray OF_GENERIC(OFString *) *arguments = [OFApplication arguments];

	if (arguments.count < 1) {
		[OFStdErr writeLine: @"Need at least one argument!"];
		[OFApplication terminateWithStatus: 1];
	}

	_streams = [[OFMutableArray alloc] init];

	for (OFString *argument in arguments) {
		OFPair *pair = streamFromString(argument);

		[pair.firstObject setDelegate: self];

		[_streams addObject: pair];
	}

	if (arguments.count == 1) {
		OFStdIn.delegate = self;

		[_streams addObject: [OFPair pairWithFirstObject: OFStdIn
						    secondObject: OFStdOut]];
	}

	for (OFPair *pair in _streams)
		[pair.firstObject asyncReadIntoBuffer: _buffer
					       length: bufferLen];
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
		[OFStdErr writeFormat: @"Exception on stream %@: %@\n",
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

		[pair.secondObject writeBuffer: buffer length: length];
	}

	return true;
}
@end
