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

#import "OFGetOptionFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFSetOptionFailedException.h"

@interface OFATalkCfg: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(OFATalkCfg)

static void
showError(OFString *error)
{
	[OFStdErr writeFormat: @"%@: %@\n", [OFApplication programName], error];
	[OFApplication terminateWithStatus: 1];
}

static void
showConfiguration(OFArray OF_GENERIC(OFString *) *arguments)
{
	OFAppleTalkInterfaceConfiguration config;
	OFNumber *network, *node, *phase;
	OFPair OF_GENERIC(OFNumber *, OFNumber *) *range;

	if (arguments.count == 0)
		showError(@"No interface specified!");
	if (arguments.count > 1)
		showError(@"More than one interface specified!");

	config = [OFDDPSocket configurationForInterface: arguments.firstObject];
	network = [config
	    objectForKey: OFAppleTalkInterfaceConfigurationNetwork];
	node = [config objectForKey: OFAppleTalkInterfaceConfigurationNode];
	phase = [config objectForKey: OFAppleTalkInterfaceConfigurationPhase];
	range = [config
	    objectForKey: OFAppleTalkInterfaceConfigurationNetworkRange];

	if (network == nil || node == nil)
		[OFApplication terminateWithStatus: 1];

	[OFStdOut writeLine: arguments.firstObject];
	[OFStdOut writeFormat: @"\tNetwork:   %04X\n",
			       network.unsignedShortValue];
	[OFStdOut writeFormat: @"\tNode:      %02X\n", node.unsignedCharValue];
	if (phase != nil)
		[OFStdOut writeFormat: @"\tPhase:     %@\n", phase];
	if (range != nil) {
		unsigned short start = [range.firstObject unsignedShortValue];
		unsigned short end = [range.secondObject unsignedShortValue];
		[OFStdOut writeFormat: @"\tNet range: %04X-%04X\n", start, end];
	}
}

static void
setConfiguration(OFArray OF_GENERIC(OFString *) *arguments,
    OFString *networkString, OFString *nodeString, OFString *phaseString,
    OFString *rangeString)
{
	OFMutableDictionary *config = [OFMutableDictionary dictionary];
	unsigned long long node, network, phase, rangeStart, rangeEnd;
	OFArray OF_GENERIC(OFString *) *rangeArray;

	if (arguments.count == 0)
		showError(@"No interface specified!");
	if (arguments.count > 1)
		showError(@"More than one interface specified!");

	if (networkString == nil)
		showError(@"--network not specified!");
	@try {
		network = [networkString unsignedLongLongValueWithBase: 0];
	} @catch (OFInvalidFormatException *e) {
		showError(@"Invalid format for --network!");
		return;
	}
	if (network > UINT16_MAX)
		showError(@"--network out of range!");
	[config setObject: [OFNumber numberWithUnsignedShort: (uint16_t)network]
		   forKey: OFAppleTalkInterfaceConfigurationNetwork];

	if (nodeString == nil)
		showError(@"--node not specified!");
	@try {
		node = [nodeString unsignedLongLongValueWithBase: 0];
	} @catch (OFInvalidFormatException *e) {
		showError(@"Invalid format for --node!");
		return;
	}
	if (node > UINT8_MAX)
		showError(@"--node out of range!");
	[config setObject: [OFNumber numberWithUnsignedChar: (uint8_t)node]
		   forKey: OFAppleTalkInterfaceConfigurationNode];

	if (phaseString != nil) {
		@try {
			phase = [phaseString unsignedLongLongValueWithBase: 0];
		} @catch (OFInvalidFormatException *e) {
			showError(@"Invalid format for "@"--phase!");
			return;
		}

		if (phase > 2)
			showError(@"--phase out of range!");

		[config setObject: [OFNumber
				       numberWithUnsignedChar: (uint8_t)phase]
			   forKey: OFAppleTalkInterfaceConfigurationPhase];
	}

	if (rangeString != nil) {
		const OFAppleTalkInterfaceConfigurationKey key =
		    OFAppleTalkInterfaceConfigurationNetworkRange;
		OFPair *range;

		rangeArray = [rangeString componentsSeparatedByString: @"-"];
		if (rangeArray.count != 2)
			showError(@"Invalid format for --range!");

		@try {
			rangeStart = [[rangeArray objectAtIndex: 0]
			    unsignedLongLongValueWithBase: 0];
			rangeEnd = [[rangeArray objectAtIndex: 1]
			    unsignedLongLongValueWithBase: 0];
		} @catch (OFInvalidFormatException *e) {
			showError(@"Invalid format for --range!");
			return;
		}
		if (rangeStart > UINT16_MAX || rangeEnd > UINT16_MAX)
			showError(@"--range out of range!");

		range = [OFPair
		    pairWithFirstObject: [OFNumber numberWithUnsignedShort:
					     (uint16_t)rangeStart]
			   secondObject: [OFNumber numberWithUnsignedShort:
					     (uint16_t)rangeEnd]];
		[config setObject: range forKey: key];
	}

	@try {
		[OFDDPSocket setConfiguration: config
				 forInterface: arguments.firstObject];
	} @catch (OFSetOptionFailedException *e) {
		showError([OFString stringWithFormat:
		    @"Setting configuration failed: %@", e]);
	}
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

	if (networkString == nil && nodeString == nil && phaseString == nil &&
	    rangeString == nil)
		showConfiguration(optionsParser.remainingArguments);
	else
		setConfiguration(optionsParser.remainingArguments,
		    networkString, nodeString, phaseString, rangeString);

	[OFApplication terminate];
}
@end
