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
#import "OFDataArray.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFOptionsParser.h"
#import "OFStdIOStream.h"
#import "OFSystemInfo.h"
#import "OFTCPSocket.h"
#import "OFURL.h"

#import "OFAddressTranslationFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFHTTPRequestFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFStatItemFailedException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFWriteFailedException.h"

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
	OFDataArray *_entity;
	of_http_request_method_t _method;
	OFMutableDictionary *_clientHeaders;
	OFHTTPClient *_HTTPClient;
	char *_buffer;
	OFStream *_output;
	intmax_t _received, _length, _resumedFrom;
	ProgressBar *_progressBar;
}
@end

OF_APPLICATION_DELEGATE(OFHTTP)

static void
help(OFStream *stream, bool full, int status)
{
	[of_stderr writeFormat:
	    @"Usage: %@ -[cehHmoPq] url1 [url2 ...]\n",
	    [OFApplication programName]];

	if (full)
		[stream writeString:
		    @"\nOptions:\n"
		    @"    -c  Continue download of existing file\n"
		    @"    -e  Specify the file to send as entity\n"
		    @"    -h  Show this help\n"
		    @"    -H  Add a header (e.g. X-Foo:Bar)\n"
		    @"    -m  Set the method of the HTTP request\n"
		    @"    -o  Output filename\n"
		    @"    -P  Specify SOCKS5 proxy\n"
		    @"    -q  Quiet mode (no output, except errors)\n"];

	[OFApplication terminateWithStatus: status];
}

@implementation OFHTTP
- init
{
	self = [super init];

	@try {
		_method = OF_HTTP_REQUEST_METHOD_GET;

		_clientHeaders = [[OFMutableDictionary alloc] init];

		_HTTPClient = [[OFHTTPClient alloc] init];
		[_HTTPClient setDelegate: self];

		_buffer = [self allocMemoryWithSize: [OFSystemInfo pageSize]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)addHeader: (OFString*)header
{
	size_t pos = [header rangeOfString: @":"].location;
	OFString *name, *value;

	if (pos == OF_NOT_FOUND) {
		[of_stderr writeFormat: @"%@: Headers must to be in format "
					"name:value!\n",
					[OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}

	name = [header substringWithRange: of_range(0, pos)];
	name = [name stringByDeletingEnclosingWhitespaces];

	value = [header substringWithRange:
	    of_range(pos + 1, [header length] - pos - 1)];
	value = [value stringByDeletingEnclosingWhitespaces];

	[_clientHeaders setObject: value
			   forKey: name];
}

- (void)setEntity: (OFString*)entity
{
	[_entity release];
	_entity = [[OFDataArray alloc] initWithContentsOfFile: entity];
}

- (void)setMethod: (OFString*)method
{
	void *pool = objc_autoreleasePoolPush();

	method = [method uppercaseString];

	if ([method isEqual: @"GET"])
		_method = OF_HTTP_REQUEST_METHOD_GET;
	else if ([method isEqual: @"HEAD"])
		_method = OF_HTTP_REQUEST_METHOD_HEAD;
	else if ([method isEqual: @"POST"])
		_method = OF_HTTP_REQUEST_METHOD_POST;
	else if ([method isEqual: @"PUT"])
		_method = OF_HTTP_REQUEST_METHOD_PUT;
	else if ([method isEqual: @"DELETE"])
		_method = OF_HTTP_REQUEST_METHOD_DELETE;
	else if ([method isEqual: @"TRACE"])
		_method = OF_HTTP_REQUEST_METHOD_TRACE;
	else {
		[of_stderr writeFormat: @"%@: Invalid request method %@!\n",
					[OFApplication programName],
					method];
		[OFApplication terminateWithStatus: 1];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setProxy: (OFString*)proxy
{
	@try {
		size_t pos = [proxy
		    rangeOfString: @":"
			  options: OF_STRING_SEARCH_BACKWARDS].location;
		OFString *host;
		intmax_t port;

		if (pos == OF_NOT_FOUND)
			@throw [OFInvalidFormatException exception];

		host = [proxy substringWithRange: of_range(0, pos)];
		port = [[proxy substringWithRange:
		    of_range(pos + 1, [proxy length] - pos - 1)] decimalValue];

		if (port > UINT16_MAX)
			@throw [OFOutOfRangeException exception];

		[OFTCPSocket setSOCKS5Host: host];
		[OFTCPSocket setSOCKS5Port: (uint16_t)port];
	} @catch (OFInvalidFormatException *e) {
		[of_stderr writeFormat: @"%@: Proxy must to be in format "
					"host:port!\n",
					[OFApplication programName]];
		[OFApplication terminateWithStatus: 1];
	}
}

- (void)applicationDidFinishLaunching
{
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: @"ce:hH:m:o:P:q"];
	of_unichar_t option;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'c':
			_continue = true;
			break;
		case 'e':
			[self setEntity: [optionsParser argument]];
			break;
		case 'h':
			help(of_stdout, true, 0);
			break;
		case 'H':
			[self addHeader: [optionsParser argument]];
			break;
		case 'm':
			[self setMethod: [optionsParser argument]];
			break;
		case 'o':
			[_outputPath release];
			_outputPath = [[optionsParser argument] retain];
			break;
		case 'P':
			[self setProxy: [optionsParser argument]];
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
		OFString *URL;

		[_progressBar stop];
		[_progressBar draw];
		[_progressBar release];
		_progressBar = nil;

		if (!_quiet)
			[of_stdout writeString: @"\n  Error!\n"];

		URL = [_URLs objectAtIndex: _URLIndex - 1];
		[of_stderr writeFormat: @"%@: Failed to download <%@>: %@\n",
					[OFApplication programName], URL, e];

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
	OFMutableDictionary *clientHeaders;
	OFHTTPRequest *request;
	OFHTTPResponse *response;
	OFDictionary *headers;
	OFString *fileName, *lengthString, *type;

	_length = -1;
	_received = _resumedFrom = 0;

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

	if (_outputPath != nil)
		fileName = _outputPath;
	else
		fileName = [[URL path] lastPathComponent];

	clientHeaders = [[_clientHeaders mutableCopy] autorelease];

	if (_continue) {
		@try {
			of_offset_t size = [OFFile sizeOfFileAtPath: fileName];
			OFString *range;

			if (size > INTMAX_MAX)
				@throw [OFOutOfRangeException exception];

			_resumedFrom = (intmax_t)size;

			range = [OFString stringWithFormat: @"bytes=%jd-",
							    _resumedFrom];
			[clientHeaders setObject: range
					  forKey: @"Range"];
		} @catch (OFStatItemFailedException *e) {
		}
	}

	request = [OFHTTPRequest requestWithURL: URL];
	[request setHeaders: clientHeaders];
	[request setMethod: _method];
	[request setEntity: _entity];

	@try {
		response = [_HTTPClient performRequest: request];
	} @catch (OFAddressTranslationFailedException *e) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeFormat: @"%@: Failed to download <%@>!\n"
					@"  Address translation failed: %@\n",
					[OFApplication programName],
					[URL string], e];

		_errorCode = 1;
		goto next;
	} @catch (OFConnectionFailedException *e) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeFormat: @"%@: Failed to download <%@>!\n"
					@"  Connection failed: %@\n",
					[OFApplication programName],
					[URL string], e];

		_errorCode = 1;
		goto next;
	} @catch (OFInvalidServerReplyException *e) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeFormat: @"%@: Failed to download <%@>!\n"
					@"  Invalid server reply!\n",
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
	} @catch (OFReadOrWriteFailedException *e) {
		OFString *action = @"Read or write";

		if (!_quiet)
			[of_stdout writeString: @"\n"];

		if ([e isKindOfClass: [OFReadFailedException class]])
			action = @"Read";
		else if ([e isKindOfClass: [OFWriteFailedException class]])
			action = @"Write";

		[of_stderr writeFormat: @"%@: Failed to download <%@>!\n"
					@"  %@ failed: %@\n",
					[OFApplication programName],
					[URL string], action, e];

		_errorCode = 1;
		goto next;
	} @catch (OFHTTPRequestFailedException *e) {
		if (!_quiet)
			[of_stdout writeFormat: @" ➜ %d\n",
						[[e response] statusCode]];

		[of_stderr writeFormat: @"%@: Failed to download <%@>!\n",
					[OFApplication programName],
					[URL string]];

		_errorCode = 1;
		goto next;
	}

	if (!_quiet)
		[of_stdout writeFormat: @" ➜ %d\n", [response statusCode]];

	headers = [response headers];
	lengthString = [headers objectForKey: @"Content-Length"];
	type = [headers objectForKey: @"Content-Type"];

	if (lengthString != nil)
		_length = [lengthString decimalValue];

	if (!_quiet) {
		if (type == nil)
			type = @"unknown";

		if (lengthString != nil) {
			if (_resumedFrom + _length >= GIBIBYTE)
				lengthString = [OFString stringWithFormat:
				    @"%.2f GiB",
				    (float)(_resumedFrom + _length) / GIBIBYTE];
			else if (_resumedFrom + _length >= MEBIBYTE)
				lengthString = [OFString stringWithFormat:
				    @"%.2f MiB",
				    (float)(_resumedFrom + _length) / MEBIBYTE];
			else if (_resumedFrom + _length >= KIBIBYTE)
				lengthString = [OFString stringWithFormat:
				    @"%.2f KiB",
				    (float)(_resumedFrom + _length) / KIBIBYTE];
			else
				lengthString = [OFString stringWithFormat:
				    @"%jd bytes", _resumedFrom + _length];
		} else
			lengthString = @"unknown";

		[of_stdout writeFormat: @"  Name: %@\n", fileName];
		[of_stdout writeFormat: @"  Type: %@\n", type];
		[of_stdout writeFormat: @"  Size: %@\n", lengthString];
	}

	if ([_outputPath isEqual: @"-"])
		_output = of_stdout;
	else {
		if (!_continue && [OFFile fileExistsAtPath: fileName]) {
			[of_stderr writeFormat:
			    @"%@: File %@ already exists!\n",
			    [OFApplication programName], fileName];

			_errorCode = 1;
			goto next;
		}

		@try {
			OFString *mode =
			    ([response statusCode] == 206 ? @"ab" : @"wb");
			_output = [[OFFile alloc] initWithPath: fileName
							  mode: mode];
		} @catch (OFOpenItemFailedException *e) {
			[of_stderr writeFormat:
			    @"%@: Failed to open file %@!\n",
			    [OFApplication programName], fileName];

			_errorCode = 1;
			goto next;
		}
	}

	if (!_quiet) {
		_progressBar = [[ProgressBar alloc]
		    initWithLength: _length
		       resumedFrom: _resumedFrom];
		[_progressBar setReceived: _received];
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
