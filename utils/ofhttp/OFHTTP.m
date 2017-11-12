/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFData.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFOptionsParser.h"
#import "OFStdIOStream.h"
#import "OFSystemInfo.h"
#import "OFTCPSocket.h"
#import "OFTLSSocket.h"
#import "OFURL.h"
#import "OFLocalization.h"
#import "OFSandbox.h"

#import "OFAddressTranslationFailedException.h"
#import "OFConnectionFailedException.h"
#import "OFHTTPRequestFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerReplyException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFRetrieveItemAttributesFailedException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFWriteFailedException.h"

#import "ProgressBar.h"

#define GIBIBYTE (1024 * 1024 * 1024)
#define MEBIBYTE (1024 * 1024)
#define KIBIBYTE (1024)

@interface OFHTTP: OFObject <OFHTTPClientDelegate>
{
	OFArray OF_GENERIC(OFString *) *_URLs;
	size_t _URLIndex;
	int _errorCode;
	OFString *_outputPath, *_currentFileName;
	bool _continue, _force, _detectFileName, _detectedFileName;
	bool _quiet, _verbose, _insecure;
	OFData *_body;
	of_http_request_method_t _method;
	OFMutableDictionary *_clientHeaders;
	OFHTTPClient *_HTTPClient;
	char *_buffer;
	OFStream *_output;
	intmax_t _received, _length, _resumedFrom;
	ProgressBar *_progressBar;
}

- (void)downloadNextURL;
@end

OF_APPLICATION_DELEGATE(OFHTTP)

static void
help(OFStream *stream, bool full, int status)
{
	[of_stderr writeLine:
	    OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] -[cehHmoOPqv] url1 [url2 ...]",
	    @"prog", [OFApplication programName])];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine: OF_LOCALIZED(@"full_usage",
		    @"Options:\n    "
		    @"-b  --body           "
		    @"  Specify the file to send as body\n    "
		    @"-c  --continue       "
		    @"  Continue download of existing file\n    "
		    @"-f  --force          "
		    @"  Force / overwrite existing file\n    "
		    @"-h  --help           "
		    @"  Show this help\n    "
		    @"-H  --header         "
		    @"  Add a header (e.g. X-Foo:Bar)\n    "
		    @"-m  --method         "
		    @"  Set the method of the HTTP request\n    "
		    @"-o  --output         "
		    @"  Specify output file name\n    "
		    @"-O  --detect-filename"
		    @"  Do a HEAD request to detect the file name\n    "
		    @"-P  --proxy          "
		    @"  Specify SOCKS5 proxy\n    "
		    @"-q  --quiet          "
		    @"  Quiet mode (no output, except errors)\n    "
		    @"-v  --verbose        "
		    @"  Verbose mode (print headers)\n    "
		    @"    --insecure       "
		    @"  Ignore TLS errors")];
	}

	[OFApplication terminateWithStatus: status];
}

static OFString *
fileNameFromContentDisposition(OFString *contentDisposition)
{
	void *pool;
	const char *UTF8String;
	size_t UTF8StringLength;
	enum {
		DISPOSITION_TYPE,
		DISPOSITION_TYPE_SEMICOLON,
		DISPOSITION_PARAM_NAME_SKIP_SPACE,
		DISPOSITION_PARAM_NAME,
		DISPOSITION_PARAM_VALUE,
		DISPOSITION_PARAM_QUOTED,
		DISPOSITION_EXPECT_SEMICOLON
	} state;
	size_t last;
	OFString *type = nil, *paramName = nil, *paramValue;
	OFMutableDictionary *params;
	OFString *fileName;

	if (contentDisposition == nil)
		return nil;

	pool = objc_autoreleasePoolPush();

	UTF8String = [contentDisposition UTF8String];
	UTF8StringLength = [contentDisposition UTF8StringLength];
	state = DISPOSITION_TYPE;
	params = [OFMutableDictionary dictionary];
	last = 0;

	for (size_t i = 0; i < UTF8StringLength; i++) {
		switch (state) {
		case DISPOSITION_TYPE:
			if (UTF8String[i] == ';' || UTF8String[i] == ' ') {
				type = [OFString
				    stringWithUTF8String: UTF8String
						  length: i];

				state = (UTF8String[i] == ';'
				    ? DISPOSITION_PARAM_NAME_SKIP_SPACE
				    : DISPOSITION_TYPE_SEMICOLON);
				last = i + 1;
			}
			break;
		case DISPOSITION_TYPE_SEMICOLON:
			if (UTF8String[i] == ';') {
				state = DISPOSITION_PARAM_NAME_SKIP_SPACE;
				last = i + 1;
			} else if (UTF8String[i] != ' ') {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		case DISPOSITION_PARAM_NAME_SKIP_SPACE:
			if (UTF8String[i] != ' ') {
				state = DISPOSITION_PARAM_NAME;
				last = i;
				i--;
			}
			break;
		case DISPOSITION_PARAM_NAME:
			if (UTF8String[i] == '=') {
				paramName = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				state = DISPOSITION_PARAM_VALUE;
			}
			break;
		case DISPOSITION_PARAM_VALUE:
			if (UTF8String[i] == '"') {
				state = DISPOSITION_PARAM_QUOTED;
				last = i + 1;
			} else {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		case DISPOSITION_PARAM_QUOTED:
			if (UTF8String[i] == '"') {
				paramValue = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				[params setObject: paramValue
					   forKey: paramName];

				state = DISPOSITION_EXPECT_SEMICOLON;
			}
			break;
		case DISPOSITION_EXPECT_SEMICOLON:
			if (UTF8String[i] == ';') {
				state = DISPOSITION_PARAM_NAME_SKIP_SPACE;
				last = i + 1;
			} else if (UTF8String[i] != ' ') {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		}
	}

	if (state != DISPOSITION_EXPECT_SEMICOLON) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if (![type isEqual: @"attachment"] ||
	    (fileName = [params objectForKey: @"filename"]) == nil) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	fileName = [fileName lastPathComponent];

	[fileName retain];
	objc_autoreleasePoolPop(pool);
	return [fileName autorelease];
}

@implementation OFHTTP
- (instancetype)init
{
	self = [super init];

	@try {
		_method = OF_HTTP_REQUEST_METHOD_GET;

		_clientHeaders = [[OFMutableDictionary alloc]
		    initWithObject: @"OFHTTP"
			    forKey: @"User-Agent"];

		_HTTPClient = [[OFHTTPClient alloc] init];
		[_HTTPClient setDelegate: self];

		_buffer = [self allocMemoryWithSize: [OFSystemInfo pageSize]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)addHeader: (OFString *)header
{
	size_t pos = [header rangeOfString: @":"].location;
	OFString *name, *value;

	if (pos == OF_NOT_FOUND) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_input_header",
		    @"%[prog]: Headers must to be in format name:value!",
		    @"prog", [OFApplication programName])];
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

- (void)setBody: (OFString *)file
{
	[_body release];

	if ([file isEqual: @"-"]) {
		void *pool = objc_autoreleasePoolPush();

		_body = [[of_stdin readDataUntilEndOfStream] copy];

		objc_autoreleasePoolPop(pool);
	} else
		_body = [[OFData alloc] initWithContentsOfFile: file];
}

- (void)setMethod: (OFString *)method
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
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_input_method",
		    @"%[prog]: Invalid request method %[method]!",
		    @"prog", [OFApplication programName],
		    @"method", method)];
		[OFApplication terminateWithStatus: 1];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setProxy: (OFString *)proxy
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
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_input_proxy",
		    @"%[prog]: Proxy must to be in format host:port!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}
}

- (void)applicationDidFinishLaunching
{
	OFString *outputPath;
	const of_options_parser_option_t options[] = {
		{ 'b', @"body",	1, NULL, NULL },
		{ 'c', @"continue", 0, &_continue, NULL },
		{ 'f', @"force", 0, &_force, NULL },
		{ 'h', @"help",	0, NULL, NULL },
		{ 'H', @"header", 1, NULL, NULL },
		{ 'm', @"method", 1, NULL, NULL },
		{ 'o', @"output", 1, NULL, &outputPath },
		{ 'O', @"detect-filename", 0, &_detectFileName, NULL },
		{ 'P', @"socks5-proxy", 1, NULL, NULL },
		{ 'q', @"quiet", 0, &_quiet, NULL },
		{ 'v', @"verbose", 0, &_verbose, NULL },
		{ '\0', @"insecure", 0, &_insecure, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser;
	of_unichar_t option;

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [[OFSandbox alloc] init];
	@try {
		[sandbox setAllowsStdIO: true];
		[sandbox setAllowsReadingFiles: true];
		[sandbox setAllowsWritingFiles: true];
		[sandbox setAllowsCreatingFiles: true];
		[sandbox setAllowsIPSockets: true];
		[sandbox setAllowsDNS: true];
		[sandbox setAllowsTTY: true];

		[OFApplication activateSandbox: sandbox];
	} @finally {
		[sandbox release];
	}
#endif

#ifndef OF_MORPHOS
	[OFLocalization addLanguageDirectory: @LANGUAGE_DIR];
#else
	[OFLocalization addLanguageDirectory: @"PROGDIR:/share/ofhttp/lang"];
#endif

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'b':
			[self setBody: [optionsParser argument]];
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
		case 'P':
			[self setProxy: [optionsParser argument]];
			break;
		case ':':
			if ([optionsParser lastLongOption] != nil)
				[of_stderr writeLine:
				    OF_LOCALIZED(@"long_argument_missing",
				    @"%[prog]: Argument for option --%[opt] "
				    @"missing"
				    @"prog", [OFApplication programName],
				    @"opt", [optionsParser lastLongOption])];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%c",
				    [optionsParser lastOption]];
				[of_stderr writeLine:
				    OF_LOCALIZED(@"argument_missing",
				    @"%[prog]: Argument for option -%[opt] "
				    @"missing",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		case '=':
			[of_stderr writeLine:
			    OF_LOCALIZED(@"option_takes_no_argument",
			    @"%[prog]: Option --%[opt] takes no argument",
			    @"prog", [OFApplication programName],
			    @"opt", [optionsParser lastLongOption])];

			[OFApplication terminateWithStatus: 1];
			break;
		case '?':
			if ([optionsParser lastLongOption] != nil)
				[of_stderr writeLine:
				    OF_LOCALIZED(@"unknown_long_option",
				    @"%[prog]: Unknown option: --%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", [optionsParser lastLongOption])];
			else {
				OFString *optStr = [OFString
				    stringWithFormat: @"%c",
				    [optionsParser lastOption]];
				[of_stderr writeLine:
				    OF_LOCALIZED(@"unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	_outputPath = [outputPath copy];
	_URLs = [[optionsParser remainingArguments] retain];

	if ([_URLs count] < 1)
		help(of_stderr, false, 1);

	if (_quiet && _verbose) {
		[of_stderr writeLine: OF_LOCALIZED(@"quiet_xor_verbose",
		    @"%[prog]: -q / --quiet and -v / --verbose are mutually "
		    @"exclusive!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_outputPath != nil && [_URLs count] > 1) {
		[of_stderr writeLine:
		    OF_LOCALIZED(@"output_only_with_one_url",
		    @"%[prog]: Cannot use -o / --output when more than one URL "
		    @"has been specified!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}

-    (void)client: (OFHTTPClient *)client
  didCreateSocket: (OF_KINDOF(OFTCPSocket *))sock
	  request: (OFHTTPRequest *)request
	  context: (id)context
{
	if (_insecure && [sock respondsToSelector:
	    @selector(setCertificateVerificationEnabled:)])
		[sock setCertificateVerificationEnabled: false];
}

-	  (bool)client: (OFHTTPClient *)client
  shouldFollowRedirect: (OFURL *)URL
	    statusCode: (int)statusCode
	       request: (OFHTTPRequest *)request
	      response: (OFHTTPResponse *)response
	       context: (id)context
{
	if (!_quiet)
		[of_stdout writeFormat: @" ➜ %d\n", statusCode];

	if (_verbose) {
		void *pool = objc_autoreleasePoolPush();
		OFDictionary OF_GENERIC(OFString *, OFString *) *headers =
		    [response headers];
		OFEnumerator *keyEnumerator = [headers keyEnumerator];
		OFEnumerator *objectEnumerator =
		    [headers objectEnumerator];
		OFString *key, *object;

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[of_stdout writeFormat: @"  %@: %@\n",
						key, object];

		objc_autoreleasePoolPop(pool);
	}

	if (!_quiet)
		[of_stdout writeFormat: @"☇ %@", [URL string]];

	return true;
}

-	   (void)client: (OFHTTPClient *)client
  didEncounterException: (id)e
	     forRequest: (OFHTTPRequest *)request
		context: (id)context
{
	if ([e isKindOfClass: [OFAddressTranslationFailedException class]]) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeLine:
		    OF_LOCALIZED(@"download_failed_address_translation",
		    @"%[prog]: Failed to download <%[url]>!\n"
		    @"  Address translation failed: %[exception]",
		    @"prog", [OFApplication programName],
		    @"url", [[request URL] string],
		    @"exception", e)];
	} else if ([e isKindOfClass: [OFConnectionFailedException class]]) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeLine:
		    OF_LOCALIZED(@"download_failed_connection_failed",
		    @"%[prog]: Failed to download <%[url]>!\n"
		    @"  Connection failed: %[exception]",
		    @"prog", [OFApplication programName],
		    @"url", [[request URL] string],
		    @"exception", e)];
	} else if ([e isKindOfClass: [OFInvalidServerReplyException class]]) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeLine:
		    OF_LOCALIZED(@"download_failed_invalid_server_reply",
		    @"%[prog]: Failed to download <%[url]>!\n"
		    @"  Invalid server reply!",
		    @"prog", [OFApplication programName],
		    @"url", [[request URL] string])];
	} else if ([e isKindOfClass: [OFUnsupportedProtocolException class]]) {
		if (!_quiet)
			[of_stdout writeString: @"\n"];

		[of_stderr writeLine: OF_LOCALIZED(@"no_ssl_library",
		    @"%[prog]: No TLS library loaded!\n"
		    @"  In order to download via https, you need to preload an "
		    @"TLS library for ObjFW\n"
		    @"  such as ObjOpenSSL!",
		    @"prog", [OFApplication programName])];
	} else if ([e isKindOfClass: [OFReadOrWriteFailedException class]]) {
		OFString *error = OF_LOCALIZED(
		    @"download_failed_read_or_write_failed_any",
		    @"Read or write failed");

		if (!_quiet)
			[of_stdout writeString: @"\n"];

		if ([e isKindOfClass: [OFReadFailedException class]])
			error = OF_LOCALIZED(
			    @"download_failed_read_or_write_failed_read",
			    @"Read failed");
		else if ([e isKindOfClass: [OFWriteFailedException class]])
			error = OF_LOCALIZED(
			    @"download_failed_read_or_write_failed_write",
			    @"Write failed");

		[of_stderr writeLine:
		    OF_LOCALIZED(@"download_failed_read_or_write_failed",
		    @"%[prog]: Failed to download <%[url]>!\n"
		    @"  %[error]: %[exception]",
		    @"prog", [OFApplication programName],
		    @"url", [[request URL] string],
		    @"error", error,
		    @"exception", e)];
	} else if ([e isKindOfClass: [OFHTTPRequestFailedException class]]) {
		if (!_quiet)
			[of_stdout writeFormat: @" ➜ %d\n",
						[[e response] statusCode]];

		[of_stderr writeLine: OF_LOCALIZED(@"download_failed",
		    @"%[prog]: Failed to download <%[url]>!",
		    @"prog", [OFApplication programName],
		    @"url", [[request URL] string])];
	} else
		@throw e;

	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}

-      (bool)stream: (OFHTTPResponse *)response
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	    context: (id)context
	  exception: (OFException *)e
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
		[of_stderr writeLine:
		    OF_LOCALIZED(@"download_failed_exception",
		    @"%[prog]: Failed to download <%[url]>: %[exception]",
		    @"prog", [OFApplication programName],
		    @"url", URL,
		    @"exception", e)];

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

		if (!_quiet) {
			[of_stdout writeString: @"\n  "];
			[of_stdout writeLine:
			    OF_LOCALIZED(@"download_done", @"Done!")];
		}

		goto next;
	}

	return true;

next:
	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
	return false;
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	    context: (id)context
{
	OFDictionary OF_GENERIC(OFString *, OFString *) *headers;
	OFString *lengthString, *type;

	if ([context isEqual: @"detectFileName"]) {
		_currentFileName = [fileNameFromContentDisposition(
		    [[response headers] objectForKey: @"Content-Disposition"])
		    copy];
		_detectedFileName = true;

		if (!_quiet)
			[of_stdout writeFormat: @" ➜ %d\n",
						[response statusCode]];

		[self performSelector: @selector(downloadNextURL)
			   afterDelay: 0];
		return;
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
			type = OF_LOCALIZED(@"type_unknown", @"unknown");

		if (_length >= 0) {
			if (_resumedFrom + _length >= GIBIBYTE) {
				lengthString = [OFString stringWithFormat:
				    @"%,.2f",
				    (float)(_resumedFrom + _length) / GIBIBYTE];
				lengthString = OF_LOCALIZED(@"size_gib",
				    @"%[num] GiB",
				    @"num", lengthString);
			} else if (_resumedFrom + _length >= MEBIBYTE) {
				lengthString = [OFString stringWithFormat:
				    @"%,.2f",
				    (float)(_resumedFrom + _length) / MEBIBYTE];
				lengthString = OF_LOCALIZED(@"size_mib",
				    @"%[num] MiB",
				    @"num", lengthString);
			} else if (_resumedFrom + _length >= KIBIBYTE) {
				lengthString = [OFString stringWithFormat:
				    @"%,.2f",
				    (float)(_resumedFrom + _length) / KIBIBYTE];
				lengthString = OF_LOCALIZED(@"size_kib",
				    @"%[num] KiB",
				    @"num", lengthString);
			} else {
				lengthString = [OFString stringWithFormat:
				    @"%jd", _resumedFrom + _length];
				lengthString = OF_LOCALIZED(@"size_bytes",
				    @"%[num] bytes",
				    @"num", lengthString);
			}
		} else
			lengthString =
			    OF_LOCALIZED(@"size_unknown", @"unknown");

		if (_verbose) {
			void *pool = objc_autoreleasePoolPush();
			OFDictionary OF_GENERIC(OFString *, OFString *)
			    *responseHeaders = [response headers];
			OFEnumerator *keyEnumerator =
			    [responseHeaders keyEnumerator];
			OFEnumerator *objectEnumerator =
			    [responseHeaders objectEnumerator];
			OFString *key, *object;

			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"info_name_unaligned",
			    @"Name: %[name]",
			    @"name", _currentFileName)];

			while ((key = [keyEnumerator nextObject]) != nil &&
			    (object = [objectEnumerator nextObject]) != nil)
				[of_stdout writeFormat: @"  %@: %@\n",
							key, object];

			objc_autoreleasePoolPop(pool);
		} else {
			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(@"info_name",
			    @"Name: %[name]",
			    @"name", _currentFileName)];
			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(@"info_type",
			    @"Type: %[type]",
			    @"type", type)];
			[of_stdout writeString: @"  "];
			[of_stdout writeLine: OF_LOCALIZED(@"info_size",
			    @"Size: %[size]",
			    @"size", lengthString)];
		}
	}

	if ([_outputPath isEqual: @"-"])
		_output = of_stdout;
	else {
		if (!_continue && !_force && [[OFFileManager defaultManager]
		    fileExistsAtPath: _currentFileName]) {
			[of_stderr writeLine:
			    OF_LOCALIZED(@"output_already_exists",
			    @"%[prog]: File %[filename] already exists!",
			    @"prog", [OFApplication programName],
			    @"filename", _currentFileName)];

			_errorCode = 1;
			goto next;
		}

		@try {
			OFString *mode =
			    ([response statusCode] == 206 ? @"a" : @"w");
			_output = [[OFFile alloc] initWithPath: _currentFileName
							  mode: mode];
		} @catch (OFOpenItemFailedException *e) {
			[of_stderr writeLine:
			    OF_LOCALIZED(@"failed_to_open_output",
			    @"%[prog]: Failed to open file %[filename]: "
			    @"%[exception]",
			    @"prog", [OFApplication programName],
			    @"filename", _currentFileName,
			    @"exception", e)];

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

	[_currentFileName release];
	_currentFileName = nil;

	[response asyncReadIntoBuffer: _buffer
			       length: [OFSystemInfo pageSize]
			       target: self
			     selector: @selector(stream:didReadIntoBuffer:
					   length:context:exception:)
			      context: nil];

	return;

next:
	[_currentFileName release];
	_currentFileName = nil;

	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}

- (void)downloadNextURL
{
	OFString *URLString = nil;
	OFURL *URL;
	OFMutableDictionary *clientHeaders;
	OFHTTPRequest *request;

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
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_url",
		    @"%[prog]: Invalid URL: <%[url]>!",
		    @"prog", [OFApplication programName],
		    @"url", URLString)];

		_errorCode = 1;
		goto next;
	}

	if (![[URL scheme] isEqual: @"http"] &&
	    ![[URL scheme] isEqual: @"https"]) {
		[of_stderr writeLine: OF_LOCALIZED(@"invalid_scheme",
		    @"%[prog]: Invalid scheme: <%[url]>!",
		    @"prog", [OFApplication programName],
		    @"url", URLString)];

		_errorCode = 1;
		goto next;
	}

	clientHeaders = [[_clientHeaders mutableCopy] autorelease];

	if (_detectFileName && !_detectedFileName) {
		/* Handle this URL on the next -[downloadNextURL] call */
		_URLIndex--;

		if (!_quiet)
			[of_stdout writeFormat: @"⠒ %@", [URL string]];

		request = [OFHTTPRequest requestWithURL: URL];
		[request setHeaders: clientHeaders];
		[request setMethod: OF_HTTP_REQUEST_METHOD_HEAD];

		[_HTTPClient asyncPerformRequest: request
					 context: @"detectFileName"];
		return;
	}

	_detectedFileName = false;

	if (!_quiet)
		[of_stdout writeFormat: @"⇣ %@", [URL string]];

	if (_outputPath != nil) {
		[_currentFileName release];
		_currentFileName = [_outputPath copy];
	}

	if (_currentFileName == nil)
		_currentFileName = [[[URL path] lastPathComponent] copy];

	if (_continue) {
		@try {
			uintmax_t size = [[[OFFileManager defaultManager]
			    attributesOfItemAtPath: _currentFileName] fileSize];
			OFString *range;

			if (size > INTMAX_MAX)
				@throw [OFOutOfRangeException exception];

			_resumedFrom = (intmax_t)size;

			range = [OFString stringWithFormat: @"bytes=%jd-",
							    _resumedFrom];
			[clientHeaders setObject: range
					  forKey: @"Range"];
		} @catch (OFRetrieveItemAttributesFailedException *e) {
		}
	}

	request = [OFHTTPRequest requestWithURL: URL];
	[request setHeaders: clientHeaders];
	[request setMethod: _method];
	[request setBody: _body];

	[_HTTPClient asyncPerformRequest: request
				 context: nil];
	return;

next:
	[self performSelector: @selector(downloadNextURL)
		   afterDelay: 0];
}
@end
