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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFDDPSocket.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFOptionsParser.h"
#import "OFPair.h"
#import "OFStdIOStream.h"

#import "OFInvalidFormatException.h"

@interface OFATalkCfg: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(OFATalkCfg)

@implementation OFATalkCfg
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFMutableDictionary *config = [OFMutableDictionary dictionary];
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
		return;
	}
	if (network > UINT16_MAX) {
		[OFStdErr writeFormat: @"%@: --network out of range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	[config setObject: [OFNumber numberWithUnsignedShort: (uint16_t)network]
		   forKey: OFAppleTalkInterfaceConfigurationNetwork];

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
		return;
	}
	if (node > UINT8_MAX) {
		[OFStdErr writeFormat: @"%@: --node out of range!\n",
				       [OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
	[config setObject: [OFNumber numberWithUnsignedChar: (uint8_t)node]
		   forKey: OFAppleTalkInterfaceConfigurationNode];

	if (phaseString != nil) {
		@try {
			phase = [phaseString unsignedLongLongValueWithBase: 0];
		} @catch (OFInvalidFormatException *e) {
			[OFStdErr writeFormat:
			    @"%@: Invalid format for "@"--phase!\n",
			    [OFApplication programName]];
			[OFApplication terminateWithStatus: 1];
			return;
		}

		if (phase > 2) {
			[OFStdErr writeFormat: @"%@: --phase out of range!\n",
					       [OFApplication programName]];
			[OFApplication terminateWithStatus: 1];
		}

		[config setObject: [OFNumber
				       numberWithUnsignedChar: (uint8_t)phase]
			   forKey: OFAppleTalkInterfaceConfigurationPhase];
	}

	if (rangeString != nil) {
		const OFAppleTalkInterfaceConfigurationKey key =
		    OFAppleTalkInterfaceConfigurationNetworkRange;
		OFPair *range;

		rangeArray = [rangeString componentsSeparatedByString: @"-"];
		if (rangeArray.count != 2) {
			[OFStdErr writeFormat:
			    @"%@: Invalid format for --range!\n",
			    [OFApplication programName]];
			[OFApplication terminateWithStatus: 1];
		}

		@try {
			rangeStart = [[rangeArray objectAtIndex: 0]
			    unsignedLongLongValueWithBase: 0];
			rangeEnd = [[rangeArray objectAtIndex: 1]
			    unsignedLongLongValueWithBase: 0];
		} @catch (OFInvalidFormatException *e) {
			[OFStdErr writeFormat:
			    @"%@: Invalid format for --range!\n",
			    [OFApplication programName]];
			[OFApplication terminateWithStatus: 1];
			return;
		}

		if (rangeStart > UINT16_MAX || rangeEnd > UINT16_MAX) {
			[OFStdErr writeFormat: @"%@: --range out of range!\n",
					       [OFApplication programName]];
			[OFApplication terminateWithStatus: 1];
		}

		range = [OFPair
		    pairWithFirstObject: [OFNumber numberWithUnsignedShort:
					     (uint16_t)rangeStart]
			   secondObject: [OFNumber numberWithUnsignedShort:
					     (uint16_t)rangeEnd]];
		[config setObject: range forKey: key];
	}

	[OFDDPSocket setConfiguration: config
			 forInterface: optionsParser.remainingArguments
					   .firstObject];

	[OFApplication terminate];
}
@end
