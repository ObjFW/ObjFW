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
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFHTTPServer.h"
#import "OFIRI.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFOptionsParser.h"
#import "OFStdIOStream.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"

@interface OFHTTPD: OFObject <OFApplicationDelegate, OFHTTPServerDelegate>
{
	OFHTTPServer *_server;
}
@end

OF_APPLICATION_DELEGATE(OFHTTPD)

static OFString *
safeLocalPathForIRI(OFIRI *IRI)
{
	OFString *path = IRI.IRIByStandardizingPath.path;

	if (![path hasPrefix: @"/"])
		return nil;

	path = [path substringWithRange: OFMakeRange(1, path.length - 1)];

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
	if ([path containsString: @":"] || [path containsString: @"\\"])
#elif defined(OF_AMIGAOS)
	if ([path containsString: @":"] || [path hasPrefix: @"/"])
#else
	/* Shouldn't even be possible after standardization, but just in case */
	if ([path hasPrefix: @"/"])
#endif
		return nil;

	/*
	 * After -[IRIByStandardizingPath], everything representing parent
	 * directory should be at the beginning, so in theory checking the
	 * first component should be enough. But it does not hurt being
	 * paranoid and checking all components, just in case.
	 */
	for (OFString *component in [path componentsSeparatedByString: @"/"])
		if ([component isEqual: @".."])
			return nil;

	return path;
}

@implementation OFHTTPD
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFString *directory, *host;
	unsigned long long port = 0;
	const OFOptionsParserOption options[] = {
		{ 'd', @"directory", 1, NULL, &directory },
		{ 'H', @"host", 1, NULL, &host },
		{ 'p', @"port", 1, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFFileManager *fileManager = [OFFileManager defaultManager];
	OFOptionsParser *optionsParser;
	OFUnichar option;
	OFMutableIRI *serverIRI;

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'd':
			[fileManager changeCurrentDirectoryPath:
			    optionsParser.argument];
			OFLog(@"Serving directory %@",
			    fileManager.currentDirectoryPath);
			break;
		case 'p':
			@try {
				port = optionsParser.argument.longLongValue;

				if (port > UINT16_MAX)
					@throw [OFInvalidFormatException
					    exception];
			} @catch (OFInvalidFormatException *e) {
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"invalid_port",
				    @"%[prog]: Port must be between 0 and "
				    @"65536!",
				    @"prog", [OFApplication programName])];
				[OFApplication terminateWithStatus: 1];
			}
			break;
		case ':':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"long_argument_missing",
				    @"%[prog]: Argument for option --%[opt] "
				    @"missing",
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%C",
				    optionsParser.lastOption];
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"argument_missing",
				    @"%[prog]: Argument for option -%[opt] "
				    @"missing",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		/* case '=': */
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
				    @"unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	if (host == nil)
		host = @"127.0.0.1";

	_server = [[OFHTTPServer alloc] init];
	_server.host = host;
	_server.port = (uint16_t)port;
	_server.delegate = self;
	[_server start];

	serverIRI = [OFMutableIRI IRIWithScheme: @"http"];
	serverIRI.host = _server.host;
	serverIRI.port = [OFNumber numberWithUnsignedShort: _server.port];
	OFLog(@"Started server on %@", serverIRI.string);
}

-      (void)server: (OFHTTPServer *)server
  didReceiveRequest: (OFHTTPRequest *)request
	requestBody: (OFStream *)requestBody
	   response: (OFHTTPResponse *)response
{
	OFString *path;

	OFLog(@"Handling request %@", request);

	path = safeLocalPathForIRI(request.IRI);
	if (path == nil) {
		response.statusCode = 403;
		return;
	}

	if ([[OFFileManager defaultManager] directoryExistsAtPath: path])
		path = [path stringByAppendingPathComponent: @"index.html"];

	OFLog(@"Sending file %@", path);

	@try {
		OFFile *file = [OFFile fileWithPath: path mode: @"r"];

		response.statusCode = 200;

		/* TODO: Async stream copy */

		while (!file.atEndOfStream) {
			char buffer[4096];
			size_t length;

			length = [file readIntoBuffer: buffer length: 4096];
			[response writeBuffer: buffer length: length];
		}
	} @catch (OFOpenItemFailedException *e) {
		switch (e.errNo) {
		case EACCES:
			response.statusCode = 403;
			return;
		case ENOENT:
		case ENOTDIR:
			response.statusCode = 404;
			return;
		}
	}
}
@end
