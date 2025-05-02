/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFApplication.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFIRI.h"
#import "OFLocale.h"
#import "OFOptionsParser.h"
#import "OFSandbox.h"
#import "OFStdIOStream.h"
#import "OFSystemInfo.h"
#import "OFTCPSocket.h"
#import "OFTLSStream.h"
#import "OFTimer.h"

#ifdef HAVE_TLS_SUPPORT
# import "ObjFWTLS.h"
#endif

#import "OFConnectSocketFailedException.h"
#import "OFGetItemAttributesFailedException.h"
#import "OFHTTPRequestFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFInvalidServerResponseException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFResolveHostFailedException.h"
#import "OFSetItemAttributesFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFUnsupportedProtocolException.h"
#import "OFWriteFailedException.h"

#import "ProgressBar.h"

#ifdef OF_AMIGAOS
const char *VER = "$VER: ofhttp " OF_PREPROCESSOR_STRINGIFY(OBJFW_VERSION_MAJOR)
    "." OF_PREPROCESSOR_STRINGIFY(OBJFW_VERSION_MINOR) " (" BUILD_DATE ") "
    "\xA9 2008-2025 Jonathan Schleifer";
#endif

#define GIBIBYTE (1024 * 1024 * 1024)
#define MEBIBYTE (1024 * 1024)
#define KIBIBYTE (1024)

@interface OFHTTP: OFObject <OFApplicationDelegate, OFHTTPClientDelegate,
    OFStreamDelegate>
{
	OFArray OF_GENERIC(OFString *) *_IRIs;
	size_t _IRIIndex;
	int _errorCode;
	OFString *_outputPath, *_currentFileName;
	bool _continue, _force, _detectFileName, _detectFileNameRequest;
	bool _detectedFileName, _quiet, _verbose, _insecure, _ignoreStatus;
	bool _useUnicode;
	OFStream *_body;
	OFHTTPRequestMethod _method;
	OFMutableDictionary *_clientHeaders;
	OFHTTPClient *_HTTPClient;
	char *_buffer;
	OFStream *_output;
	unsigned long long _received, _length, _resumedFrom;
	ProgressBar *_progressBar;
}

- (void)SIGINTCheck;
- (void)downloadNextIRI;
@end

#ifdef HAVE_TLS_SUPPORT
void
_reference_to_ObjFWTLS(void)
{
	_ObjFWTLS_reference = 1;
}
#endif

static volatile sig_atomic_t SIGINTReceived = false;

OF_APPLICATION_DELEGATE(OFHTTP)

static void
help(OFStream *stream, bool full, int status)
{
	[OFStdErr writeLine: OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] -[cehHmoOPqv] iri1 [iri2 ...]",
	    @"prog", [OFApplication programName])];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine: OF_LOCALIZED(@"full_usage",
		    @"Options:\n    "
		    @"-b  --body=          "
		    @"  Specify the file to send as body\n    "
		    @"                     "
		    @"  (- for standard input)\n    "
		    @"-c  --continue       "
		    @"  Continue download of existing file\n    "
		    @"-f  --force          "
		    @"  Force / overwrite existing file\n    "
		    @"-h  --help           "
		    @"  Show this help\n    "
		    @"-H  --header=        "
		    @"  Add a header (e.g. X-Foo:Bar)\n    "
		    @"-m  --method=        "
		    @"  Set the method of the HTTP request\n    "
		    @"-o  --output=        "
		    @"  Specify output file name\n    "
		    @"-O  --detect-filename"
		    @"  Do a HEAD request to detect the file name\n    "
		    @"-P  --proxy=         "
		    @"  Specify SOCKS5 proxy\n    "
		    @"-q  --quiet          "
		    @"  Quiet mode (no output, except errors)\n    "
		    @"-v  --verbose        "
		    @"  Verbose mode (print headers)\n    "
		    @"    --insecure       "
		    @"  Ignore TLS errors and allow insecure redirects\n    "
		    @"    --ignore-status  "
		    @"  Ignore HTTP status code\n    "
		    @"    --version        "
		    @"  Show version information")];
	}

	[OFApplication terminateWithStatus: status];
}

static void
version(void)
{
	[OFStdOut writeFormat: @"ofhttp %@ (ObjFW %@) "
			       @"<https://objfw.nil.im/>\n"
	    		       @"Copyright (c) 2008-2025 Jonathan Schleifer "
			       @"<js@nil.im>\n"
			       @"Licensed under the LGPL 3.0 "
			       @"<https://www.gnu.org/licenses/lgpl-3.0.html>"
			       @"\n",
			       @PACKAGE_VERSION, [OFSystemInfo ObjFWVersion]];
	[OFApplication terminate];
}

static OFString *
fileNameFromContentDisposition(OFString *contentDisposition)
{
	void *pool;
	const char *UTF8String;
	size_t UTF8StringLength;
	enum {
		stateDispositionType,
		stateDispositionTypeSemicolon,
		stateDispositionParamNameSkipSpace,
		stateDispositionParamName,
		stateDispositionParamValue,
		stateDispositionParamQuoted,
		stateDispositionParamUnquoted,
		stateDispositionExpectSemicolon
	} state;
	size_t last;
	OFString *type = nil, *paramName = nil, *paramValue;
	OFMutableDictionary *params;
	OFString *fileName;

	if (contentDisposition == nil)
		return nil;

	pool = objc_autoreleasePoolPush();

	UTF8String = contentDisposition.UTF8String;
	UTF8StringLength = contentDisposition.UTF8StringLength;
	state = stateDispositionType;
	params = [OFMutableDictionary dictionary];
	last = 0;

	for (size_t i = 0; i < UTF8StringLength; i++) {
		switch (state) {
		case stateDispositionType:
			if (UTF8String[i] == ';' || UTF8String[i] == ' ') {
				type = [OFString
				    stringWithUTF8String: UTF8String
						  length: i];

				state = (UTF8String[i] == ';'
				    ? stateDispositionParamNameSkipSpace
				    : stateDispositionTypeSemicolon);
				last = i + 1;
			}
			break;
		case stateDispositionTypeSemicolon:
			if (UTF8String[i] == ';') {
				state = stateDispositionParamNameSkipSpace;
				last = i + 1;
			} else if (UTF8String[i] != ' ') {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		case stateDispositionParamNameSkipSpace:
			if (UTF8String[i] != ' ') {
				state = stateDispositionParamName;
				last = i;
				i--;
			}
			break;
		case stateDispositionParamName:
			if (UTF8String[i] == '=') {
				paramName = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				state = stateDispositionParamValue;
			}
			break;
		case stateDispositionParamValue:
			if (UTF8String[i] == '"') {
				state = stateDispositionParamQuoted;
				last = i + 1;
			} else {
				state = stateDispositionParamUnquoted;
				last = i;
				i--;
			}
			break;
		case stateDispositionParamQuoted:
			if (UTF8String[i] == '"') {
				paramValue = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				[params setObject: paramValue
					   forKey: paramName.lowercaseString];

				state = stateDispositionExpectSemicolon;
			}
			break;
		case stateDispositionParamUnquoted:
			if (UTF8String[i] <= 31 || UTF8String[i] >= 127)
				return nil;

			switch (UTF8String[i]) {
			case ' ': case '"': case '(': case ')': case ',':
			case '/': case ':': case '<': case '=': case '>':
			case '?': case '@': case '[': case '\\': case ']':
			case '{': case '}':
				return nil;
			case ';':
				paramValue = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				[params setObject: paramValue
					   forKey: paramName.lowercaseString];

				state = stateDispositionParamNameSkipSpace;
				break;
			}
			break;
		case stateDispositionExpectSemicolon:
			if (UTF8String[i] == ';') {
				state = stateDispositionParamNameSkipSpace;
				last = i + 1;
			} else if (UTF8String[i] != ' ') {
				objc_autoreleasePoolPop(pool);
				return nil;
			}
			break;
		}
	}

	if (state == stateDispositionParamUnquoted) {
		paramValue = [OFString
		    stringWithUTF8String: UTF8String + last
				  length: UTF8StringLength - last];

		[params setObject: paramValue
			   forKey: paramName.lowercaseString];
	} else if (state != stateDispositionExpectSemicolon) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if (![type isEqual: @"attachment"] ||
	    (fileName = [params objectForKey: @"filename"]) == nil) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	fileName = fileName.lastPathComponent;

	objc_retain(fileName);
	objc_autoreleasePoolPop(pool);
	return objc_autoreleaseReturnValue(fileName);
}

@implementation OFHTTP
- (instancetype)init
{
	self = [super init];

	@try {
		_method = OFHTTPRequestMethodGet;

		_clientHeaders = [[OFMutableDictionary alloc]
		    initWithObject: @"OFHTTP"
			    forKey: @"User-Agent"];

		_HTTPClient = [[OFHTTPClient alloc] init];
		_HTTPClient.delegate = self;

		_buffer = OFAllocMemory(1, [OFSystemInfo pageSize]);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)addHeader: (OFString *)header
{
	size_t pos = [header rangeOfString: @":"].location;
	OFString *name, *value;

	if (pos == OFNotFound) {
		[OFStdErr writeLine: OF_LOCALIZED(@"invalid_input_header",
		    @"%[prog]: Headers must to be in format name:value!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	name = [header substringToIndex: pos]
	    .stringByDeletingEnclosingWhitespaces;

	value = [header substringFromIndex: pos + 1]
	    .stringByDeletingEnclosingWhitespaces;

	[_clientHeaders setObject: value forKey: name];
}

- (void)setBody: (OFString *)path
{
	OFString *contentLength = nil;

	objc_release(_body);
	_body = nil;

	if ([path isEqual: @"-"])
		_body = [OFStdIn copy];
	else {
		_body = [[OFFile alloc] initWithPath: path mode: @"r"];

		@try {
			unsigned long long fileSize =
			    [[OFFileManager defaultManager]
			    attributesOfItemAtPath: path].fileSize;

			contentLength =
			    [OFString stringWithFormat: @"%ju", fileSize];
			[_clientHeaders setObject: contentLength
					   forKey: @"Content-Length"];
		} @catch (OFGetItemAttributesFailedException *e) {
		}
	}

	if (contentLength == nil)
		[_clientHeaders setObject: @"chunked"
				   forKey: @"Transfer-Encoding"];
}

- (void)setMethod: (OFString *)method
{
	void *pool = objc_autoreleasePoolPush();

	method = method.uppercaseString;

	@try {
		_method = OFHTTPRequestMethodParseString(method);
	} @catch (OFInvalidArgumentException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(@"invalid_input_method",
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
			  options: OFStringSearchBackwards].location;
		OFString *host;
		unsigned short port;

		if (pos == OFNotFound)
			@throw [OFInvalidFormatException exception];

		host = [proxy substringToIndex: pos];
		port = [proxy substringFromIndex: pos + 1].unsignedShortValue;

#if USHRT_MAX != 65535
		if (port > 65535)
			@throw [OFOutOfRangeException exception];
#endif

		[OFTCPSocket setSOCKS5Host: host];
		[OFTCPSocket setSOCKS5Port: (uint16_t)port];
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(@"invalid_input_proxy",
		    @"%[prog]: Proxy must to be in format host:port!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}
}

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFString *outputPath;
	const OFOptionsParserOption options[] = {
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
		{ '\0', @"ignore-status", 0, &_ignoreStatus, NULL },
		{ '\0', @"version", 0, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser;
	OFUnichar option;

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [OFSandbox sandbox];
	sandbox.allowsStdIO = true;
	sandbox.allowsReadingFiles = true;
	sandbox.allowsWritingFiles = true;
	sandbox.allowsCreatingFiles = true;
	sandbox.allowsIPSockets = true;
	sandbox.allowsDNS = true;
	sandbox.allowsUserDatabaseReading = true;
	sandbox.allowsTTY = true;
	/* Dropped after parsing options */
	sandbox.allowsUnveil = true;

	[OFApplication of_activateSandbox: sandbox];
#endif

#ifndef OF_AMIGAOS
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @LOCALIZATION_DIR]];
#else
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @"PROGDIR:/share/ofhttp/localization"]];
#endif

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'b':
			[self setBody: optionsParser.argument];
			break;
		case 'h':
			help(OFStdOut, true, 0);
			break;
		case 'H':
			[self addHeader: optionsParser.argument];
			break;
		case 'm':
			[self setMethod: optionsParser.argument];
			break;
		case 'P':
			[self setProxy: optionsParser.argument];
			break;
		case '-':
			if ([optionsParser.lastLongOption isEqual: @"version"])
				version();
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
		case '=':
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"option_takes_no_argument",
			    @"%[prog]: Option --%[opt] takes no argument",
			    @"prog", [OFApplication programName],
			    @"opt", optionsParser.lastLongOption)];

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
				    @"unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

#ifdef OF_HAVE_SANDBOX
	if (outputPath != nil)
		[sandbox unveilPath: outputPath
			permissions: (_continue ? @"rwc" : @"wc")];
	else
		[sandbox unveilPath: [[OFFileManager defaultManager]
					 currentDirectoryPath]
			permissions: (_continue ? @"rwc" : @"wc")];

	/* In case we use OpenSSL for HTTPS later */
	[sandbox unveilPath: @"/etc/ssl" permissions: @"r"];

	sandbox.allowsUnveil = false;
	[OFApplication of_activateSandbox: sandbox];
#endif

	_outputPath = [outputPath copy];
	_IRIs = [optionsParser.remainingArguments copy];

	if (_IRIs.count < 1)
		help(OFStdErr, false, 1);

	if (_quiet && _verbose) {
		[OFStdErr writeLine: OF_LOCALIZED(@"quiet_xor_verbose",
		    @"%[prog]: -q / --quiet and -v / --verbose are mutually "
		    @"exclusive!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_outputPath != nil && _detectFileName) {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"output_xor_detect_filename",
		    @"%[prog]: -o / --output and -O / --detect-filename are "
		    @"mutually exclusive!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_outputPath != nil && _IRIs.count > 1) {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"output_only_with_one_iri",
		    @"%[prog]: Cannot use -o / --output when more than one IRI "
		    @"has been specified!",
		    @"prog", [OFApplication programName])];
		[OFApplication terminateWithStatus: 1];
	}

	if (_insecure)
		_HTTPClient.allowsInsecureRedirects = true;

#ifdef OF_WINDOWS
	_useUnicode = [OFSystemInfo isWindowsNT];
#else
	_useUnicode = ([OFLocale encoding] == OFStringEncodingUTF8);
#endif

	[OFTimer scheduledTimerWithTimeInterval: 0.1
					 target: self
				       selector: @selector(SIGINTCheck)
					repeats: true];

	[self performSelector: @selector(downloadNextIRI) afterDelay: 0];
}

- (void)applicationDidReceiveSIGINT
{
	SIGINTReceived = true;
}

- (void)SIGINTCheck
{
	if (SIGINTReceived) {
		if (!_quiet) {
			OFStdErr.cursorVisible = true;
			[OFStdErr writeString: @"\n  "];
			[OFStdErr writeLine:
			    OF_LOCALIZED(@"download_aborted", @"Aborted!")];
		}

		[OFApplication terminateWithStatus: 1];
	}
}

-	(void)client: (OFHTTPClient *)client
  didCreateTCPSocket: (OFTCPSocket *)TCPSocket
	     request: (OFHTTPRequest *)request
{
	TCPSocket.canBlock = false;
}

-	(void)client: (OFHTTPClient *)client
  didCreateTLSStream: (OFTLSStream *)stream
	     request: (OFHTTPRequest *)request
{
	/* Use setter instead of property access to work around GCC bug. */
	[stream setVerifiesCertificates: !_insecure];
}

-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)body
	   request: (OFHTTPRequest *)request
{
	/* TODO: Do asynchronously and print status */
	while (!_body.atEndOfStream) {
		char buffer[4096];
		size_t length = [_body readIntoBuffer: buffer length: 4096];
		[body writeBuffer: buffer length: length];
	}
}

-	       (bool)client: (OFHTTPClient *)client
  shouldFollowRedirectToIRI: (OFIRI *)IRI
		 statusCode: (short)statusCode
		    request: (OFHTTPRequest *)request
		   response: (OFHTTPResponse *)response
{
	if (_verbose) {
		void *pool = objc_autoreleasePoolPush();
		OFDictionary OF_GENERIC(OFString *, OFString *) *headers =
		    response.headers;
		OFEnumerator *keyEnumerator = [headers keyEnumerator];
		OFEnumerator *objectEnumerator = [headers objectEnumerator];
		OFString *key, *object;

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[OFStdErr writeFormat: @"  %@: %@\n", key, object];

		objc_autoreleasePoolPop(pool);
	}

	if (!_quiet) {
		if (_useUnicode)
			[OFStdErr writeFormat: @"☇ %@", IRI.string];
		else
			[OFStdErr writeFormat: @"< %@", IRI.string];
	}

	_length = 0;

	return true;
}

-      (bool)stream: (OFStream *)response
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	if (exception != nil) {
		OFString *IRI;

		[_progressBar stop];
		[_progressBar draw];
		objc_release(_progressBar);
		_progressBar = nil;

		if (!_quiet) {
			[OFStdErr writeString: @"\n  "];
			[OFStdErr writeLine: OF_LOCALIZED(@"download_error",
			    @"Error!")];
		}

		IRI = [_IRIs objectAtIndex: _IRIIndex - 1];
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"download_failed_exception",
		    @"%[prog]: Failed to download <%[iri]>!\n"
		    @"  %[exception]",
		    @"prog", [OFApplication programName],
		    @"iri", IRI,
		    @"exception", exception)];

		_errorCode = 1;
		[self performSelector: @selector(downloadNextIRI)
			   afterDelay: 0];
		return false;
	}

	[_output writeBuffer: buffer length: length];

	_received += length;
	[_progressBar setReceived: _received];

	if (response.atEndOfStream) {
		[_progressBar stop];
		[_progressBar draw];
		objc_release(_progressBar);
		_progressBar = nil;

		if (!_quiet) {
			[OFStdErr writeString: @"\n  "];
			[OFStdErr writeLine:
			    OF_LOCALIZED(@"download_done", @"Done!")];
		}

		[self performSelector: @selector(downloadNextIRI)
			   afterDelay: 0];
		return false;
	}

	return true;
}

-      (void)client: (OFHTTPClient *)client
  didReceiveHeaders: (OFDictionary OF_GENERIC(OFString *, OFString *) *)headers
	 statusCode: (short)statusCode
	    request: (OFHTTPRequest *)request
{
	if (statusCode != 206)
		_resumedFrom = 0;

	if (!_quiet) {
		OFString *lengthString =
		    [headers objectForKey: @"Content-Length"];
		OFString *type = [headers objectForKey: @"Content-Type"];

		if (_useUnicode)
			[OFStdErr writeFormat: @" ➜ %hd\n", statusCode];
		else
			[OFStdErr writeFormat: @" -> %hd\n", statusCode];

		if (type == nil)
			type = OF_LOCALIZED(@"type_unknown", @"unknown");

		if (lengthString != nil) {
			_length = lengthString.unsignedLongLongValue;

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
				    @"["
				    @"    ["
				    @"        {'num == 1': '1 byte'},"
				    @"        {'': '%[num] bytes'}"
				    @"    ]"
				    @"]".objectByParsingJSON,
				    @"num", lengthString);
			}
		} else
			lengthString =
			    OF_LOCALIZED(@"size_unknown", @"unknown");

		if (_verbose) {
			void *pool = objc_autoreleasePoolPush();
			OFEnumerator OF_GENERIC(OFString *) *keyEnumerator =
			    [headers keyEnumerator];
			OFEnumerator OF_GENERIC(OFString *) *objectEnumerator =
			    [headers objectEnumerator];
			OFString *key, *object;

			if (statusCode / 100 == 2 && _currentFileName != nil) {
				[OFStdErr writeString: @"  "];
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"info_name_unaligned",
				    @"Name: %[name]",
				    @"name", _currentFileName)];
			}

			while ((key = [keyEnumerator nextObject]) != nil &&
			    (object = [objectEnumerator nextObject]) != nil)
				[OFStdErr writeFormat: @"  %@: %@\n",
						       key, object];

			objc_autoreleasePoolPop(pool);
		} else if (statusCode / 100 == 2 && !_detectFileNameRequest) {
			[OFStdErr writeString: @"  "];

			if (_currentFileName != nil)
				[OFStdErr writeLine: OF_LOCALIZED(@"info_name",
				    @"Name: %[name]",
				    @"name", _currentFileName)];

			[OFStdErr writeString: @"  "];
			[OFStdErr writeLine: OF_LOCALIZED(@"info_type",
			    @"Type: %[type]",
			    @"type", type)];
			[OFStdErr writeString: @"  "];
			[OFStdErr writeLine: OF_LOCALIZED(@"info_size",
			    @"Size: %[size]",
			    @"size", lengthString)];
		}
	}
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	  exception: (id)exception
{
	if (exception != nil) {
		if ([exception isKindOfClass:
		    [OFResolveHostFailedException class]]) {
			if (!_quiet)
				[OFStdErr writeString: @"\n"];

			[OFStdErr writeLine: OF_LOCALIZED(
			    @"download_resolve_host_failed",
			    @"%[prog]: Failed to download <%[iri]>!\n"
			    @"  Failed to resolve host: %[exception]",
			    @"prog", [OFApplication programName],
			    @"iri", request.IRI.string,
			    @"exception", exception)];
		} else if ([exception isKindOfClass:
		    [OFConnectSocketFailedException class]]) {
			if (!_quiet)
				[OFStdErr writeString: @"\n"];

			[OFStdErr writeLine: OF_LOCALIZED(
			    @"download_failed_connection_failed",
			    @"%[prog]: Failed to download <%[iri]>!\n"
			    @"  Connection failed: %[exception]",
			    @"prog", [OFApplication programName],
			    @"iri", request.IRI.string,
			    @"exception", exception)];
		} else if ([exception isKindOfClass:
		    [OFInvalidServerResponseException class]]) {
			if (!_quiet)
				[OFStdErr writeString: @"\n"];

			[OFStdErr writeLine: OF_LOCALIZED(
			    @"download_failed_invalid_server_response",
			    @"%[prog]: Failed to download <%[iri]>!\n"
			    @"  Invalid server response!",
			    @"prog", [OFApplication programName],
			    @"iri", request.IRI.string)];
		} else if ([exception isKindOfClass:
		    [OFUnsupportedProtocolException class]]) {
			if (!_quiet)
				[OFStdErr writeString: @"\n"];

			[OFStdErr writeLine: OF_LOCALIZED(@"no_tls_support",
			    @"%[prog]: No TLS support in ObjFW!\n"
			    @"  In order to download via HTTPS, you need to "
			    @"either build ObjFW with TLS\n"
			    @"  support or preload a library adding TLS "
			    @"support to ObjFW!",
			    @"prog", [OFApplication programName])];
		} else if ([exception isKindOfClass:
		    [OFTLSHandshakeFailedException class]]) {
			OFString *error = OFTLSStreamErrorCodeDescription(
			    ((OFTLSHandshakeFailedException *)exception)
			    .errorCode);

			if (!_quiet)
				[OFStdErr writeString: @"\n"];

			[OFStdErr writeLine: OF_LOCALIZED(
			    @"download_failed_tls_handshake_failed",
			    @"%[prog]: Failed to download <%[iri]>!\n"
			    @"  TLS handshake failed: %[error]",
			    @"prog", [OFApplication programName],
			    @"iri", request.IRI.string,
			    @"error", error)];
		} else if ([exception isKindOfClass:
		    [OFReadOrWriteFailedException class]]) {
			OFString *error = OF_LOCALIZED(
			    @"download_failed_read_or_write_failed_any",
			    @"Read or write failed");

			if (!_quiet)
				[OFStdErr writeString: @"\n"];

			if ([exception isKindOfClass:
			    [OFReadFailedException class]])
				error = OF_LOCALIZED(
				    @"download_failed_read_or_write_failed_"
				    @"read",
				    @"Read failed");
			else if ([exception isKindOfClass:
			    [OFWriteFailedException class]])
				error = OF_LOCALIZED(
				    @"download_failed_read_or_write_failed_"
				    @"write",
				    @"Write failed");

			[OFStdErr writeLine: OF_LOCALIZED(
			    @"download_failed_read_or_write_failed",
			    @"%[prog]: Failed to download <%[iri]>!\n"
			    @"  %[error]: %[exception]",
			    @"prog", [OFApplication programName],
			    @"iri", request.IRI.string,
			    @"error", error,
			    @"exception", exception)];
		} else if ([exception isKindOfClass:
		    [OFHTTPRequestFailedException class]]) {
			short statusCode;
			OFString *codeString;

			if (_ignoreStatus) {
				exception = nil;
				goto after_exception_handling;
			}

			statusCode = response.statusCode;
			codeString = [OFString stringWithFormat: @"%hd %@",
			    statusCode, OFHTTPStatusCodeString(statusCode)];
			[OFStdErr writeLine: OF_LOCALIZED(@"download_failed",
			    @"%[prog]: Failed to download <%[iri]>!\n"
			    @"  HTTP status code: %[code]",
			    @"prog", [OFApplication programName],
			    @"iri", request.IRI.string,
			    @"code", codeString)];
		} else
			@throw exception;

		_errorCode = 1;
		[self performSelector: @selector(downloadNextIRI)
			   afterDelay: 0];
		return;
	}

after_exception_handling:
	if (_method == OFHTTPRequestMethodHead)
		goto next;

	if (_detectFileNameRequest) {
		_currentFileName = [fileNameFromContentDisposition(
		    [response.headers objectForKey: @"Content-Disposition"])
		    copy];
		_detectedFileName = true;

		/* Handle this IRI on the next -[downloadNextIRI] call */
		_IRIIndex--;

		[self performSelector: @selector(downloadNextIRI)
			   afterDelay: 0];
		return;
	}

	if ([_outputPath isEqual: @"-"])
		_output = OFStdOut;
	else {
		if (!_continue && !_force && [[OFFileManager defaultManager]
		    fileExistsAtPath: _currentFileName]) {
			[OFStdErr writeLine:
			    OF_LOCALIZED(@"output_already_exists",
			    @"%[prog]: File %[filename] already exists!",
			    @"prog", [OFApplication programName],
			    @"filename", _currentFileName)];

			_errorCode = 1;
			goto next;
		}

		@try {
			OFString *mode =
			    (response.statusCode == 206 ? @"a" : @"w");
			_output = [[OFFile alloc] initWithPath: _currentFileName
							  mode: mode];
		} @catch (OFOpenItemFailedException *e) {
			[OFStdErr writeLine:
			    OF_LOCALIZED(@"failed_to_open_output",
			    @"%[prog]: Failed to open file %[filename]: "
			    @"%[exception]",
			    @"prog", [OFApplication programName],
			    @"filename", _currentFileName,
			    @"exception", e)];

			_errorCode = 1;
			goto next;
		}

#ifdef OF_FILE_MANAGER_SUPPORTS_EXTENDED_ATTRIBUTES
		@try {
			OFString *IRIString = request.IRI.string;
			OFData *downloadedFromData = [OFData
			    dataWithItems: IRIString.UTF8String
				    count: IRIString.UTF8StringLength + 1];
			[[OFFileManager defaultManager]
			    setExtendedAttributeData: downloadedFromData
					     forName: @"user.ofhttp."
						      @"downloaded_from"
					ofItemAtPath: _currentFileName];
		} @catch (OFSetItemAttributesFailedException *) {
			/* Ignore */
		}
#endif

#ifdef OF_MACOS
		@try {
			OFString *quarantine = [OFString stringWithFormat:
			    @"0000;%08" @PRIx64 @";ofhttp;",
			    (uint64_t)[[OFDate date] timeIntervalSince1970]];
			OFData *quarantineData = [OFData
			    dataWithItems: quarantine.UTF8String
				    count: quarantine.UTF8StringLength];
			[[OFFileManager defaultManager]
			    setExtendedAttributeData: quarantineData
					     forName: @"com.apple.quarantine"
					ofItemAtPath: _currentFileName];
		} @catch (OFSetItemAttributesFailedException *e) {
			/* Ignore */
		}
#endif
	}

	if (!_quiet) {
		_progressBar = [[ProgressBar alloc]
		    initWithLength: _length
		       resumedFrom: _resumedFrom
			useUnicode: _useUnicode];
		[_progressBar setReceived: _received];
		[_progressBar draw];
	}

	objc_release(_currentFileName);
	_currentFileName = nil;

	response.delegate = self;
	[response asyncReadIntoBuffer: _buffer length: [OFSystemInfo pageSize]];
	return;

next:
	objc_release(_currentFileName);
	_currentFileName = nil;

	[self performSelector: @selector(downloadNextIRI) afterDelay: 0];
}

- (void)downloadNextIRI
{
	OFString *IRIString = nil;
	OFIRI *IRI;
	OFMutableDictionary *clientHeaders;
	OFHTTPRequest *request;

	_received = _length = _resumedFrom = 0;

	if (_output != OFStdOut)
		objc_release(_output);
	_output = nil;

	if (_IRIIndex >= _IRIs.count)
		[OFApplication terminateWithStatus: _errorCode];

	@try {
		IRIString = [_IRIs objectAtIndex: _IRIIndex++];
		IRI = [OFIRI IRIWithString: IRIString];
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(@"invalid_iri",
		    @"%[prog]: Invalid IRI: <%[iri]>!",
		    @"prog", [OFApplication programName],
		    @"iri", IRIString)];

		_errorCode = 1;
		goto next;
	}

	if (![IRI.scheme isEqual: @"http"] && ![IRI.scheme isEqual: @"https"]) {
		[OFStdErr writeLine: OF_LOCALIZED(@"invalid_scheme",
		    @"%[prog]: Invalid scheme: <%[iri]>!",
		    @"prog", [OFApplication programName],
		    @"iri", IRIString)];

		_errorCode = 1;
		goto next;
	}

	clientHeaders = objc_autorelease([_clientHeaders mutableCopy]);

	if (_detectFileName && !_detectedFileName) {
		if (!_quiet) {
			if (_useUnicode)
				[OFStdErr writeFormat: @"⠒ %@", IRI.string];
			else
				[OFStdErr writeFormat: @"? %@", IRI.string];
		}

		request = [OFHTTPRequest requestWithIRI: IRI];
		request.headers = clientHeaders;
		request.method = OFHTTPRequestMethodHead;

		_detectFileNameRequest = true;
		[_HTTPClient asyncPerformRequest: request];
		return;
	}

	if (!_detectedFileName) {
		objc_release(_currentFileName);
		_currentFileName = nil;
	} else
		_detectedFileName = false;

	if (_currentFileName == nil)
		_currentFileName = [_outputPath copy];

	if (_currentFileName == nil)
		_currentFileName = [IRI.path.lastPathComponent copy];

	if ([_currentFileName isEqual: @"/"] || _currentFileName.length == 0) {
		objc_release(_currentFileName);
		_currentFileName = nil;
	}

	if (_currentFileName == nil)
		_currentFileName = @"unnamed";

	if (_continue) {
		@try {
			unsigned long long size =
			    [[OFFileManager defaultManager]
			    attributesOfItemAtPath: _currentFileName].fileSize;
			OFString *range;

			if (size > ULLONG_MAX)
				@throw [OFOutOfRangeException exception];

			_resumedFrom = (unsigned long long)size;

			range = [OFString stringWithFormat: @"bytes=%ju-",
							    _resumedFrom];
			[clientHeaders setObject: range forKey: @"Range"];
		} @catch (OFGetItemAttributesFailedException *e) {
		}
	}

	if (!_quiet) {
		if (_useUnicode)
			[OFStdErr writeFormat: @"⇣ %@", IRI.string];
		else
			[OFStdErr writeFormat: @"v %@", IRI.string];
	}

	request = [OFHTTPRequest requestWithIRI: IRI];
	request.headers = clientHeaders;
	request.method = _method;

	_detectFileNameRequest = false;
	[_HTTPClient asyncPerformRequest: request];
	return;

next:
	[self performSelector: @selector(downloadNextIRI) afterDelay: 0];
}
@end
