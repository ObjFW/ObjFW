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

#include "config.h"

#include <errno.h>

#ifdef HAVE_NET_IF_H
# include <net/if.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
# include <sys/ioctl.h>
#endif
#include "unistd.h"

#import "OFApplication.h"
#import "OFArray.h"
#import "OFOptionsParser.h"
#import "OFSocket.h"
#import "OFStdIOStream.h"

#import "OFInvalidFormatException.h"

@interface OFATalkCfg: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(OFATalkCfg)

static void
configureInterface(OFString *interface, uint16_t network, uint8_t node,
    uint8_t phase, uint16_t rangeStart, uint16_t rangeEnd)
{
	struct ifreq request = { 0 };
	struct sockaddr_at *sat;
#ifdef OF_LINUX
	struct atalk_netrange *nr;
#else
	struct netrange *nr;
#endif
	int sock;

	if (interface.UTF8StringLength > IFNAMSIZ) {
		[OFStdErr writeFormat: @"%@: Interface name too long!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	strncpy(request.ifr_name, interface.UTF8String, IFNAMSIZ);
	sat = (struct sockaddr_at *)&request.ifr_addr;
	sat->sat_family = AF_APPLETALK;
	sat->sat_net = OFToBigEndian16(network);
	sat->sat_node = node;
	nr = (__typeof__(nr))(void *)sat->sat_zero;
	nr->nr_phase = phase;
	nr->nr_firstnet = OFToBigEndian16(rangeStart);
	nr->nr_lastnet = OFToBigEndian16(rangeEnd);

	if ((sock = socket(AF_APPLETALK, SOCK_DGRAM, 0)) < 0) {
		int errNo = OFSocketErrNo();

		[OFStdErr writeFormat: @"%@: Failed to create socket: %@\n",
				       [OFApplication programName],
				       OFStrError(errNo)];

#ifdef OF_LINUX
		if (errNo == EAFNOSUPPORT)
			[OFStdErr writeLine: @"Did you forget to run "
					     @"\"modprobe appletalk\"?"];
#endif

		[OFApplication terminateWithStatus: 1];
	}

	if (ioctl(sock, SIOCSIFADDR, &request) != 0) {
		[OFStdErr writeFormat: @"%@: Failed to set address: %@\n",
				       [OFApplication programName],
				       OFStrError(OFSocketErrNo())];
		[OFApplication terminateWithStatus: 1];
	}

	close(sock);
}

@implementation OFATalkCfg
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFString *nodeString = nil, *networkString = nil, *phaseString = nil;
	OFString *rangeString = nil;
	const OFOptionsParserOption options[] = {
		{ '\0', @"network", 1, NULL, &networkString },
		{ '\0', @"node", 1, NULL, &nodeString },
		{ '\0', @"phase", 1, NULL, &phaseString },
		{ '\0', @"range", 1, NULL, &rangeString },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	OFUnichar option;
	unsigned long long node, network, phase, rangeStart, rangeEnd;
	OFArray OF_GENERIC(OFString *) *rangeArray;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case ':':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeFormat:
				    @"%@: Argument for option --%@ missing\n",
				    [OFApplication programName],
				    optionsParser.lastLongOption];
			else
				[OFStdErr writeFormat:
				    @"%@: Argument for option -%C missing\n",
				    [OFApplication programName],
				    optionsParser.lastOption];

			[OFApplication terminateWithStatus: 1];
			break;
		case '?':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeFormat:
				    @"%@: Unknown option: --%@\n",
				    [OFApplication programName],
				    optionsParser.lastLongOption];
			else
				[OFStdErr writeFormat:
				    @"%@: Unknown option: -%C\n",
				    [OFApplication programName],
				    optionsParser.lastOption];

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	if (optionsParser.remainingArguments.count == 0) {
		[OFStdErr writeFormat: @"%@: No interface specified!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	if (optionsParser.remainingArguments.count > 1) {
		[OFStdErr writeFormat: @"%@: More than one interface "
				       @"specified!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	if (networkString == nil) {
		[OFStdErr writeFormat: @"%@: --network not specified!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	@try {
		network = [networkString unsignedLongLongValueWithBase: 0];
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeFormat: @"%@: Invalid format for --network!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	if (network > UINT16_MAX) {
		[OFStdErr writeFormat: @"%@: --network out of range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	if (nodeString == nil) {
		[OFStdErr writeFormat: @"%@: --node not specified!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	@try {
		node = [nodeString unsignedLongLongValueWithBase: 0];
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeFormat: @"%@: Invalid format for --node!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	if (node > UINT8_MAX) {
		[OFStdErr writeFormat: @"%@: --node out of range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	if (phaseString == nil) {
		[OFStdErr writeFormat: @"%@: --phase not specified!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	@try {
		phase = [phaseString unsignedLongLongValueWithBase: 0];
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeFormat: @"%@: Invalid format for --phase!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	if (phase > 2) {
		[OFStdErr writeFormat: @"%@: --phase out of range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	if (rangeString == nil) {
		[OFStdErr writeFormat: @"%@: --range not specified!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	rangeArray = [rangeString componentsSeparatedByString: @"-"];
	if (rangeArray.count != 2) {
		[OFStdErr writeFormat: @"%@: Invalid format for --range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	@try {
		rangeStart = [[rangeArray objectAtIndex: 0]
		    unsignedLongLongValueWithBase: 0];
		rangeEnd = [[rangeArray objectAtIndex: 1]
		    unsignedLongLongValueWithBase: 0];
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeFormat: @"%@: Invalid format for --range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	if (rangeStart > UINT16_MAX || rangeEnd > UINT16_MAX) {
		[OFStdErr writeFormat: @"%@: --range out of range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	configureInterface(optionsParser.remainingArguments.firstObject,
	    (uint16_t)network, (uint8_t)node, (uint8_t)phase,
	    (uint16_t)rangeStart, (uint16_t)rangeEnd);

	[OFApplication terminate];
}
@end
