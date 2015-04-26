/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFOptionsParser.h"
#import "OFStdIOStream.h"
#import "OFSystemInfo.h"
#import "OFURL.h"

#import "OFHTTPRequestFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#import "OFUnsupportedProtocolException.h"

#import "ProgressBar.h"

#define GIBIBYTE (1024 * 1024 * 1024)
#define MEBIBYTE (1024 * 1024)
#define KIBIBYTE (1024)

@interface OFHTTP: OFObject
{
	OFArray *_URLs;
	size_t _URLIndex;
	int _errorCode;
	OFString *_outputPath;
	bool _continue, _quiet;
	OFHTTPClient *_HTTPClient;
	char *_buffer;
	OFStream *_output;
	intmax_t _received, _length;
	ProgressBar *_progressBar;
}

- (void)downloadNextURL;
@end

OF_APPLICATION_DELEGATE(OFHTTP)

static void
help(OFStream *stream, bool full, int status)
{
	[of_stderr writeFormat:
	    @"Usage: %@ -[hoq] url1 [url2 ...]\n",
	    [OFApplication programName]];

	if (full)
		[stream writeString:
		    @"\nOptions:\n"
		    @"    -h  Show this help\n"
		    @"    -o  Output filename\n"
		    @"    -q  Quiet mode (no output, except errors)\n"];

	[OFApplication terminateWithStatus: status];
}

@implementation OFHTTP
- init
{
	self = [super init];

	@try {
		_HTTPClient = [[OFHTTPClient alloc] init];
		[_HTTPClient setDelegate: self];

		_buffer = [self allocMemoryWithSize: [OFSystemInfo pageSize]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)applicationDidFinishLaunching
{
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: @"ho:q"];
	of_unichar_t option;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'h':
			help(of_stdout, true, 0);
			break;
		case 'o':
			[_outputPath release];
			_outputPath = [[optionsParser argument] retain];
			break;
		case 'q':
			_quiet = true;
			break;
		case ':':
			[of_stderr writeFormat: @"%@: Argument for option -%C "
						@"missing\n",
						[OFApplication programName],
						[optionsParser lastOption]];
			[OFApplication terminateWithStatus: 1];
		default:
			[of_stderr writeFormat: @"%@: Unknown option: -%C\n",
						[OFApplication programName],
						[optionsParser lastOption]];
			[OFApplication terminateWithStatus: 1];
		}
	}

	_URLs = [[optionsParser remainingArguments] retain];

	if ([_URLs count] < 1)
		help(of_stderr, false, 1);

	if (_outputPath != nil && [_URLs count] > 1) {
		[of_stderr writeFormat: @"%@: Cannot use -o when more than "
					@"one URL has been specified!\n",
					[OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}

-	  (bool)client: (OFHTTPClient*)client
  shouldFollowRedirect: (OFURL*)URL
	    statusCode: (int)statusCode
	       request: (OFHTTPRequest*)request
{
	if (!_quiet)
		[of_stdout writeFormat: @" ➜ %d\n↻ %@",
					statusCode, [URL string]];

	return true;
}

-      (bool)stream: (OFHTTPResponse*)response
  didReadIntoBuffer: (void*)buffer
	     length: (size_t)length
	  exception: (OFException*)e
{
	if (e != nil) {
		OFURL *URL;

		[_progressBar stop];
		[_progressBar draw];
		[_progressBar release];
		_progressBar = nil;

		if (!_quiet)
			[of_stdout writeString: @"\n  Error!\n"];

		URL = [_URLs objectAtIndex: _URLIndex - 1];
		[of_stderr writeFormat: @"%@: Failed to download <%@>: %@\n",
					[OFApplication programName],
					[URL string], e];

		_errorCode = 1;
		goto next;
	}

	_received += length;

	[_output writeBuffer: buffer
		      length: length];

	[_progressBar setReceived: _received];

	if ([response isAtEndOfStream] ||
	    (_length >= 0 && _received >= _length)) {
		[_progressBar stop];
		[_progressBar draw];
		[_progressBar release];
		_progressBar = nil;

		if (!_quiet)
			[of_stdout writeString: @"\n  Done!\n"];

		goto next;
	}

	return true;

next:
	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
	return false;
}

- (void)downloadNextURL
{
	OFString *URLString = nil;
	OFURL *URL;
	OFHTTPRequest *request;
	OFHTTPResponse *response;
	OFDictionary *headers;
	OFString *fileName, *lengthString, *type;

	_length = -1;
	_received = 0;

	if (_output != of_stdout)
		[_output release];
	_output = nil;

	if (_URLIndex >= [_URLs count])
		[OFApplication terminateWithStatus: _errorCode];

	@try {
		URLString = [_URLs objectAtIndex: _URLIndex++];
		URL = [OFURL URLWithString: URLString];
	} @catch (OFInvalidFormatException *e) {
		[of_stderr writeFormat: @"%@: Invalid URL: <%@>!\n",
					[OFApplication programName],
					URLString];

		_errorCode = 1;
		goto next;
	}

	if (![[URL scheme] isEqual: @"http"] &&
	    ![[URL scheme] isEqual: @"https"]) {
		[of_stderr writeFormat: @"%@: Invalid scheme: <%@:>!\n",
					[OFApplication programName],
					URLString];

		_errorCode = 1;
		goto next;
	}

	if (!_quiet)
		[of_stdout writeFormat: @"⇣ %@", [URL string]];

	request = [OFHTTPRequest requestWithURL: URL];

	@try {
		response = [_HTTPClient performRequest: request];
	} @catch (OFHTTPRequestFailedException *e) {
		if (!_quiet)
			[of_stdout writeFormat: @" ➜ %d\n",
						[[e response] statusCode]];

		[of_stderr writeFormat: @"%@: Failed to download <%@>!\n",
					[OFApplication programName],
					[URL string]];

		_errorCode = 1;
		goto next;
	} @catch (OFUnsupportedProtocolException *e) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeFormat: @"%@: No SSL library loaded!\n"
					@"  In order to download via https, "
					@"you need to preload an SSL library "
					@"for ObjFW\n  such as ObjOpenSSL!\n",
					[OFApplication programName]];

		_errorCode = 1;
		goto next;
	}

	if (!_quiet)
		[of_stdout writeFormat: @" ➜ %d\n", [response statusCode]];

	headers = [response headers];
	lengthString = [headers objectForKey: @"Content-Length"];
	type = [headers objectForKey: @"Content-Type"];

	if (_outputPath != nil)
		fileName = _outputPath;
	else
		fileName = [[URL path] lastPathComponent];

	if (lengthString != nil)
		_length = [lengthString decimalValue];

	if (!_quiet) {
		if (type == nil)
			type = @"unknown";

		if (lengthString != nil) {
			if (_length >= GIBIBYTE)
				lengthString = [OFString stringWithFormat:
				    @"%.2f GiB", (float)_length / GIBIBYTE];
			else if (_length >= MEBIBYTE)
				lengthString = [OFString stringWithFormat:
				    @"%.2f MiB", (float)_length / MEBIBYTE];
			else if (_length >= KIBIBYTE)
				lengthString = [OFString stringWithFormat:
				    @"%.2f KiB", (float)_length / KIBIBYTE];
			else
				lengthString = [OFString stringWithFormat:
				    @"%jd bytes", _length];
		} else
			lengthString = @"unknown";

		[of_stdout writeFormat: @"  Name: %@\n", fileName];
		[of_stdout writeFormat: @"  Type: %@\n", type];
		[of_stdout writeFormat: @"  Size: %@\n", lengthString];
	}

	if ([_outputPath isEqual: @"-"])
		_output = of_stdout;
	else {
		if ([OFFile fileExistsAtPath: fileName]) {
			[of_stderr writeFormat:
			    @"%@: File %@ already exists!\n",
			    [OFApplication programName], fileName];

			_errorCode = 1;
			goto next;
		}

		@try {
			_output = [[OFFile alloc] initWithPath: fileName
							  mode: @"wb"];
		} @catch (OFOpenItemFailedException *e) {
			[of_stderr writeFormat:
			    @"%@: Failed to open file %@!\n",
			    [OFApplication programName], fileName];

			_errorCode = 1;
			goto next;
		}
	}

	if (!_quiet) {
		_progressBar = [[ProgressBar alloc] initWithLength: _length];
		[_progressBar draw];
	}

	[response asyncReadIntoBuffer: _buffer
			       length: [OFSystemInfo pageSize]
			       target: self
			     selector: @selector(stream:didReadIntoBuffer:
					   length:exception:)];
	return;

next:
	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}
@end
