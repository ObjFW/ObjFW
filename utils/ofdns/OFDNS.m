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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFDNSResolver.h"
#import "OFIRI.h"
#import "OFLocale.h"
#import "OFOptionsParser.h"
#import "OFSandbox.h"
#import "OFStdIOStream.h"

@interface OFDNS: OFObject <OFApplicationDelegate, OFDNSResolverQueryDelegate>
{
	size_t _inFlight;
	int _errors;
}
@end

OF_APPLICATION_DELEGATE(OFDNS)

static void
help(OFStream *stream, bool full, int status)
{
	[OFStdErr writeLine:
	    OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] -[chst] domain1 [domain2 ...]",
	    @"prog", [OFApplication programName])];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine: OF_LOCALIZED(@"full_usage",
		    @"Options:\n    "
		    @"-c  --class "
		    @"  The DNS class to query (defaults to IN)\n    "
		    @"-h  --help  "
		    @"  Show this help\n    "
		    @"-s  --server"
		    @"  The server to query\n    "
		    @"-t  --type  "
		    @"  The record type to query (defaults to ALL, can be "
		    @"repeated)")];
	}

	[OFApplication terminateWithStatus: status];
}

@implementation OFDNS
-  (void)resolver: (OFDNSResolver *)resolver
  didPerformQuery: (OFDNSQuery *)query
	 response: (OFDNSResponse *)response
	exception: (id)exception
{
	_inFlight--;

	if (exception == nil)
		[OFStdOut writeFormat: @"%@\n", response];
	else {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"failed_to_resolve",
		    @"Failed to resolve: %[exception]",
		    @"exception", exception)];
		_errors++;
	}

	if (_inFlight == 0)
		[OFApplication terminateWithStatus: _errors];
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFString *DNSClassString, *server;
	const OFOptionsParserOption options[] = {
		{ 'c', @"class", 1, NULL, &DNSClassString },
		{ 'h', @"help", 0, NULL, NULL },
		{ 's', @"server", 1, NULL, &server },
		{ 't', @"type", 1, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFMutableArray OF_GENERIC(OFString *) *recordTypes;
	OFOptionsParser *optionsParser;
	OFUnichar option;
	OFArray OF_GENERIC(OFString *) *remainingArguments;
	OFDNSResolver *resolver;
	OFDNSClass DNSClass;

#ifdef OF_HAVE_FILES
# ifndef OF_AMIGAOS
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @LOCALIZATION_DIR]];
# else
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @"PROGDIR:/share/ofdns/localization"]];
# endif
#endif

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [[OFSandbox alloc] init];
	@try {
		sandbox.allowsStdIO = true;
		sandbox.allowsDNS = true;

		[OFApplication of_activateSandbox: sandbox];
	} @finally {
		[sandbox release];
	}
#endif

	recordTypes = [OFMutableArray array];

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 't':
			[recordTypes addObject: optionsParser.argument];
			break;
		case 'h':
			help(OFStdOut, true, 0);
			break;
		case ':':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"long_option_required_argument",
				    @"%[prog]: Option --%[opt] requires an "
				    @"argument",
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%C",
				    optionsParser.lastOption];
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"option_requires_argument",
				    @"%[prog]: Option -%[opt] requires an "
				    @"argument",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		case '?':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"unknown_long_option",
				    @"%[prog]: Unknown option: --%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%C",
				    optionsParser.lastOption];
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"Unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	remainingArguments = optionsParser.remainingArguments;

	if (remainingArguments.count < 1)
		help(OFStdErr, false, 1);

	resolver = [OFDNSResolver resolver];
	DNSClass = (DNSClassString != nil
	    ? OFDNSClassParseName(DNSClassString) : OFDNSClassIN);

	if (recordTypes.count == 0)
		[recordTypes addObject: @"ALL"];

	if (server != nil) {
		resolver.configReloadInterval = 0;
		resolver.nameServers = [OFArray arrayWithObject: server];
	}

	for (OFString *domainName in remainingArguments) {
		for (OFString *recordTypeString in recordTypes) {
			OFDNSRecordType recordType =
			    OFDNSRecordTypeParseName(recordTypeString);
			OFDNSQuery *query =
			    [OFDNSQuery queryWithDomainName: domainName
						   DNSClass: DNSClass
						 recordType: recordType];

			_inFlight++;
			[resolver asyncPerformQuery: query delegate: self];
		}
	}
}
@end
