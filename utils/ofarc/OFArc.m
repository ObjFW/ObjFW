/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
#import "OFLocale.h"
#import "OFOptionsParser.h"
#import "OFSandbox.h"
#import "OFStdIOStream.h"

#import "OFArc.h"
#import "GZIPArchive.h"
#import "LHAArchive.h"
#import "TarArchive.h"
#import "ZIPArchive.h"
#import "ZooArchive.h"

#ifdef HAVE_TLS_SUPPORT
# import "ObjFWTLS.h"
#endif

#import "OFCreateDirectoryFailedException.h"
#import "OFGetItemAttributesFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFReadFailedException.h"
#import "OFSeekFailedException.h"
#import "OFWriteFailedException.h"

#define bufferSize 4096

#ifdef HAVE_TLS_SUPPORT
void
_reference_to_ObjFWTLS(void)
{
	_ObjFWTLS_reference = 1;
}
#endif

OF_APPLICATION_DELEGATE(OFArc)

static void
help(OFStream *stream, bool full, int status)
{
	[stream writeLine: OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] -[acCfhlnpqtvx] archive.zip [file1 file2 ...]",
	    @"prog", [OFApplication programName])];

	if (full) {
		[stream writeString: @"\n"];
		[stream writeLine: OF_LOCALIZED(@"full_usage",
		    @"Options:\n"
		    @"    -a  --append            Append to archive\n"
		    @"        --archive-comment=  Archive comment to use when "
		    @"creating or appending\n"
		    @"    -c  --create            Create archive\n"
		    @"    -C  --directory=        Extract into the specified "
		    @"directory\n"
		    @"    -E  --encoding=         The encoding used by the "
		    @"archive\n"
		    @"                            (only tar, lha and zoo files)"
		    @"\n"
		    @"    -f  --force             Force / overwrite files\n"
		    @"    -h  --help              Show this help\n"
		    @"        --iri               Use an IRI to access the "
		    @"archive\n"
		    @"    -l  --list              List all files in the archive"
		    @"\n"
		    @"    -n  --no-clobber        Never overwrite files\n"
		    @"    -p  --print             Print one or more files from "
		    @"the archive\n"
		    @"    -q  --quiet             Quiet mode (no output, "
		    @"except errors)\n"
		    @"    -t  --type=             Archive type (gz, lha, tar, "
		    @"tgz, zip, zoo)\n"
		    @"    -v  --verbose           Verbose output for file list"
		    @"\n"
		    @"    -x  --extract           Extract files")];
	}

	[OFApplication terminateWithStatus: status];
}

static void
mutuallyExclusiveError(OFUnichar shortOption1, OFString *longOption1,
    OFUnichar shortOption2, OFString *longOption2)
{
	OFString *shortOption1Str = [OFString stringWithFormat: @"%C",
								shortOption1];
	OFString *shortOption2Str = [OFString stringWithFormat: @"%C",
								shortOption2];

	[OFStdErr writeLine: OF_LOCALIZED(@"2_options_mutually_exclusive",
	    @"Error: -%[shortopt1] / --%[longopt1] and "
	    @"-%[shortopt2] / --%[longopt2] "
	    @"are mutually exclusive!",
	    @"shortopt1", shortOption1Str,
	    @"longopt1", longOption1,
	    @"shortopt2", shortOption2Str,
	    @"longopt2", longOption2)];
	[OFApplication terminateWithStatus: 1];
}

static OFIRI *
argumentToIRI(OFString *argument, bool isIRI)
{
	if (isIRI)
		return [OFIRI IRIWithString: argument];

	if ([argument isEqual: @"-"])
		return nil;

	return [OFIRI fileIRIWithPath: argument];
}

static void
mutuallyExclusiveError5(OFUnichar shortOption1, OFString *longOption1,
    OFUnichar shortOption2, OFString *longOption2,
    OFUnichar shortOption3, OFString *longOption3,
    OFUnichar shortOption4, OFString *longOption4,
    OFUnichar shortOption5, OFString *longOption5)
{
	OFString *shortOption1Str = [OFString stringWithFormat: @"%C",
								shortOption1];
	OFString *shortOption2Str = [OFString stringWithFormat: @"%C",
								shortOption2];
	OFString *shortOption3Str = [OFString stringWithFormat: @"%C",
								shortOption3];
	OFString *shortOption4Str = [OFString stringWithFormat: @"%C",
								shortOption4];
	OFString *shortOption5Str = [OFString stringWithFormat: @"%C",
								shortOption5];

	[OFStdErr writeLine: OF_LOCALIZED(@"5_options_mutually_exclusive",
	    @"Error: -%[shortopt1] / --%[longopt1], "
	    @"-%[shortopt2] / --%[longopt2], -%[shortopt3] / --%[longopt3], "
	    @"-%[shortopt4] / --%[longopt4] and\n"
	    @"       -%[shortopt5] / --%[longopt5] are mutually exclusive!",
	    @"shortopt1", shortOption1Str,
	    @"longopt1", longOption1,
	    @"shortopt2", shortOption2Str,
	    @"longopt2", longOption2,
	    @"shortopt3", shortOption3Str,
	    @"longopt3", longOption3,
	    @"shortopt4", shortOption4Str,
	    @"longopt4", longOption4,
	    @"shortopt5", shortOption5Str,
	    @"longopt5", longOption5)];
	[OFApplication terminateWithStatus: 1];
}

static void
writingNotSupported(OFString *type)
{
	[OFStdErr writeLine: OF_LOCALIZED(
	    @"writing_not_supported",
	    @"Writing archives of type %[type] is not (yet) supported!",
	    @"type", type)];
}

static void
addFiles(id <Archive> archive, OFArray OF_GENERIC(OFString *) *files,
    OFString *archiveComment)
{
	OFMutableArray *expandedFiles =
	    [OFMutableArray arrayWithCapacity: files.count];
	OFFileManager *fileManager = [OFFileManager defaultManager];

	for (OFString *file in files) {
		OFFileAttributes attributes =
		    [fileManager attributesOfItemAtPath: file];

		if ([attributes.fileType isEqual: OFFileTypeDirectory])
			[expandedFiles addObjectsFromArray:
			    [fileManager subpathsOfDirectoryAtPath: file]];
		else
			[expandedFiles addObject: file];
	}

	if (expandedFiles.count < 1) {
		[OFStdErr writeLine: OF_LOCALIZED(@"add_no_file_specified",
		    @"Need one or more files to add!")];
		[OFApplication terminateWithStatus: 1];
	}

	[archive addFiles: expandedFiles archiveComment: archiveComment];
}

@implementation OFArc
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFString *archiveComment, *outputDir, *encodingString, *type;
	bool isIRI;
	const OFOptionsParserOption options[] = {
		{ 'a', @"append", 0, NULL, NULL },
		{ 0,   @"archive-comment", 1, NULL, &archiveComment },
		{ 'c', @"create", 0, NULL, NULL },
		{ 'C', @"directory", 1, NULL, &outputDir },
		{ 'E', @"encoding", 1, NULL, &encodingString },
		{ 'f', @"force", 0, NULL, NULL },
		{ 'h', @"help", 0, NULL, NULL },
		{ 0,   @"iri", 0, &isIRI, NULL },
		{ 'l', @"list", 0, NULL, NULL },
		{ 'n', @"no-clobber", 0, NULL, NULL },
		{ 'p', @"print", 0, NULL, NULL },
		{ 'q', @"quiet", 0, NULL, NULL },
		{ 't', @"type", 1, NULL, &type },
		{ 'v', @"verbose", 0, NULL, NULL },
		{ 'x', @"extract", 0, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFUnichar option, mode = '\0';
	OFStringEncoding encoding = OFStringEncodingAutodetect;
	OFOptionsParser *optionsParser;
	OFArray OF_GENERIC(OFString *) *remainingArguments, *files;
	OFIRI *IRI;
	id <Archive> archive;

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [OFSandbox sandbox];
	sandbox.allowsStdIO = true;
	sandbox.allowsReadingFiles = true;
	sandbox.allowsWritingFiles = true;
	sandbox.allowsCreatingFiles = true;
	sandbox.allowsChangingFileAttributes = true;
	sandbox.allowsUserDatabaseReading = true;
	/* Dropped after parsing options */
	sandbox.allowsUnveil = true;

	[OFApplication of_activateSandbox: sandbox];
#endif

#ifndef OF_AMIGAOS
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @LOCALIZATION_DIR]];
#else
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @"PROGDIR:/share/ofarc/localization"]];
#endif

	optionsParser = [OFOptionsParser parserWithOptions: options];
	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'f':
			if (_overwrite < 0)
				mutuallyExclusiveError(
				    'f', @"force", 'n', @"no-clobber");

			_overwrite = 1;
			break;
		case 'n':
			if (_overwrite > 0)
				mutuallyExclusiveError(
				    'f', @"force", 'n', @"no-clobber");

			_overwrite = -1;
			break;
		case 'v':
			if (_outputLevel < 0)
				mutuallyExclusiveError(
				    'q', @"quiet", 'v', @"verbose");

			_outputLevel++;
			break;
		case 'q':
			if (_outputLevel > 0)
				mutuallyExclusiveError(
				    'q', @"quiet", 'v', @"verbose");

			_outputLevel--;
			break;
		case 'a':
		case 'c':
		case 'l':
		case 'p':
		case 'x':
			if (mode != '\0')
				mutuallyExclusiveError5(
				    'a', @"append",
				    'c', @"create",
				    'l', @"list",
				    'p', @"print",
				    'x', @"extract");

			mode = option;
			break;
		case 'h':
			help(OFStdOut, true, 0);
			break;
		case '=':
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"option_takes_no_argument",
			    @"%[prog]: Option --%[opt] takes no argument",
			    @"prog", [OFApplication programName],
			    @"opt", optionsParser.lastLongOption)];

			[OFApplication terminateWithStatus: 1];
			break;
		case ':':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"long_option_requires_argument",
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
				    @"unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	@try {
		if (encodingString != nil)
			encoding = OFStringEncodingParseName(encodingString);
	} @catch (OFInvalidArgumentException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"invalid_encoding",
		    @"%[prog]: Invalid encoding: %[encoding]",
		    @"prog", [OFApplication programName],
		    @"encoding", encodingString)];

		[OFApplication terminateWithStatus: 1];
	}

	remainingArguments = optionsParser.remainingArguments;

	switch (mode) {
	case 'a':
	case 'c':
		if (remainingArguments.count < 1)
			help(OFStdErr, false, 1);

		IRI = argumentToIRI(remainingArguments.firstObject, isIRI);
		files = [remainingArguments objectsInRange:
		    OFMakeRange(1, remainingArguments.count - 1)];

#ifdef OF_HAVE_SANDBOX
		if ([IRI.scheme isEqual: @"file"])
			[sandbox unveilPath: IRI.fileSystemRepresentation
				permissions: (mode == 'a' ? @"rwc" : @"wc")];

		for (OFString *path in files)
			[sandbox unveilPath: path permissions: @"r"];

		sandbox.allowsUnveil = false;
		[OFApplication of_activateSandbox: sandbox];
#endif

		archive = [self openArchiveWithIRI: IRI
					      type: type
					      mode: mode
					  encoding: encoding];

		addFiles(archive, files, archiveComment);
		break;
	case 'l':
		if (remainingArguments.count != 1)
			help(OFStdErr, false, 1);

		IRI = argumentToIRI(remainingArguments.firstObject, isIRI);

#ifdef OF_HAVE_SANDBOX
		if ([IRI.scheme isEqual: @"file"])
			[sandbox unveilPath: IRI.fileSystemRepresentation
				permissions: @"r"];

		sandbox.allowsUnveil = false;
		[OFApplication of_activateSandbox: sandbox];
#endif

		archive = [self openArchiveWithIRI: IRI
					      type: type
					      mode: mode
					  encoding: encoding];

		[archive listFiles];
		break;
	case 'p':
		if (remainingArguments.count < 1)
			help(OFStdErr, false, 1);

		IRI = argumentToIRI(remainingArguments.firstObject, isIRI);
		files = [remainingArguments objectsInRange:
		    OFMakeRange(1, remainingArguments.count - 1)];

#ifdef OF_HAVE_SANDBOX
		if ([IRI.scheme isEqual: @"file"])
			[sandbox unveilPath: IRI.fileSystemRepresentation
				permissions: @"r"];

		sandbox.allowsUnveil = false;
		[OFApplication of_activateSandbox: sandbox];
#endif

		archive = [self openArchiveWithIRI: IRI
					      type: type
					      mode: mode
					  encoding: encoding];

		[archive printFiles: files];
		break;
	case 'x':
		if (remainingArguments.count < 1)
			help(OFStdErr, false, 1);

		IRI = argumentToIRI(remainingArguments.firstObject, isIRI);
		files = [remainingArguments objectsInRange:
		    OFMakeRange(1, remainingArguments.count - 1)];

#ifdef OF_HAVE_SANDBOX
		if ([IRI.scheme isEqual: @"file"])
			[sandbox unveilPath: IRI.fileSystemRepresentation
				permissions: @"r"];

		if (files.count > 0)
			for (OFString *path in files)
				[sandbox unveilPath: path permissions: @"wc"];
		else {
			OFString *path = outputDir;

			if (path == nil)
				path = [[OFFileManager defaultManager]
				    currentDirectoryPath];

			/* We need 'r' to change the directory to it. */
			[sandbox unveilPath: path permissions: @"rwc"];
		}

		sandbox.allowsUnveil = false;
		[OFApplication of_activateSandbox: sandbox];
#endif

		archive = [self openArchiveWithIRI: IRI
					      type: type
					      mode: mode
					  encoding: encoding];

#ifdef OF_MACOS
		if ([IRI.scheme isEqual: @"file"]) {
			@try {
				OFString *attributeName =
				    @"com.apple.quarantine";

				_quarantine = [[[OFFileManager defaultManager]
				    extendedAttributeDataForName: attributeName
						     ofItemAtIRI: IRI] retain];
			} @catch (OFGetItemAttributesFailedException *e) {
				if (e.errNo != /*ENOATTR*/ 93)
					@throw e;
			}
		}
#endif

		if (outputDir != nil) {
			OFFileManager *fileManager =
			    [OFFileManager defaultManager];

			if (![fileManager directoryExistsAtPath: outputDir])
				[fileManager createDirectoryAtPath: outputDir
						     createParents: true];

			[fileManager changeCurrentDirectoryPath: outputDir];
		}

		@try {
			[archive extractFiles: files];
		} @catch (OFCreateDirectoryFailedException *e) {
			[OFStdErr writeString: @"\r"];
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"failed_to_create_directory",
			    @"Failed to create directory %[dir]: %[error]",
			    @"dir", e.IRI.fileSystemRepresentation,
			    @"error", OFStrError(e.errNo))];
			_exitStatus = 1;
		} @catch (OFOpenItemFailedException *e) {
			[OFStdErr writeString: @"\r"];
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"failed_to_open_file",
			    @"Failed to open file %[file]: %[error]",
			    @"file", e.path,
			    @"error", OFStrError(e.errNo))];
			_exitStatus = 1;
		}

		break;
	default:
		help(OFStdErr, true, 1);
		break;
	}

	[OFApplication terminateWithStatus: _exitStatus];
}

- (id <Archive>)openArchiveWithIRI: (OFIRI *)IRI
			      type: (OFString *)type
			      mode: (char)mode
			  encoding: (OFStringEncoding)encoding
{
	/* To make clang-analyzer happy about assigning nil to path later. */
	OFString *modeString, *fileModeString;
	OFStream *file = nil;
	id <Archive> archive = nil;

	switch (mode) {
	case 'a':
		modeString = @"a";
		fileModeString = @"r+";
		break;
	case 'c':
		modeString = @"w";
		fileModeString = @"w+";
		break;
	case 'l':
	case 'p':
	case 'x':
		modeString = fileModeString = @"r";
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	if (IRI == nil) {
		switch (mode) {
		case 'a':
		case 'c':
			file = OFStdOut;
			break;
		case 'l':
		case 'p':
		case 'x':
			file = OFStdIn;
			break;
		default:
			@throw [OFInvalidArgumentException exception];
		}
	} else {
		@try {
			file = [OFIRIHandler openItemAtIRI: IRI
						      mode: fileModeString];
		} @catch (OFOpenItemFailedException *e) {
			[OFStdErr writeString: @"\r"];
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"failed_to_open_file",
			    @"Failed to open file %[file]: %[error]",
			    @"file", e.IRI.string,
			    @"error", OFStrError(e.errNo))];
			[OFApplication terminateWithStatus: 1];
		}
	}

	if (type == nil || [type isEqual: @"auto"]) {
		OFString *lowercasePath = IRI.path.lowercaseString;

		/* This one has to be first for obvious reasons */
		if ([lowercasePath hasSuffix: @".tar.gz"] ||
		    [lowercasePath hasSuffix: @".tgz"])
			type = @"tgz";
		else if ([lowercasePath hasSuffix: @".gz"])
			type = @"gz";
		else if ([lowercasePath hasSuffix: @".lha"] ||
		    [lowercasePath hasSuffix: @".lzh"] ||
		    [lowercasePath hasSuffix: @".lzs"] ||
		    [lowercasePath hasSuffix: @".pma"])
			type = @"lha";
		else if ([lowercasePath hasSuffix: @".tar"])
			type = @"tar";
		else if ([lowercasePath hasSuffix: @".zoo"])
			type = @"zoo";
		else
			type = @"zip";
	}

	@try {
		if ([type isEqual: @"gz"])
			archive = [GZIPArchive archiveWithIRI: IRI
						       stream: file
							 mode: modeString
						     encoding: encoding];
		else if ([type isEqual: @"lha"])
			 archive = [LHAArchive archiveWithIRI: IRI
						       stream: file
							 mode: modeString
						      encoding: encoding];
		else if ([type isEqual: @"tar"])
			archive = [TarArchive archiveWithIRI: IRI
						      stream: file
							mode: modeString
						    encoding: encoding];
		else if ([type isEqual: @"tgz"]) {
			OFStream *GZIPStream = [OFGZIPStream
			    streamWithStream: file
					mode: modeString];
			archive = [TarArchive archiveWithIRI: IRI
						      stream: GZIPStream
							mode: modeString
						    encoding: encoding];
		} else if ([type isEqual: @"zip"])
			archive = [ZIPArchive archiveWithIRI: IRI
						      stream: file
							mode: modeString
						    encoding: encoding];
		else if ([type isEqual: @"zoo"])
			archive = [ZooArchive archiveWithIRI: IRI
						      stream: file
							mode: modeString
						    encoding: encoding];
		else {
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"unknown_archive_type",
			    @"Unknown archive type: %[type]",
			    @"type", type)];
			goto error;
		}
	} @catch (OFNotImplementedException *e) {
		if ((mode == 'a' || mode == 'c') && sel_isEqual(e.selector,
		    @selector(initWithStream:mode:))) {
			writingNotSupported(type);
			goto error;
		}

		@throw e;
	} @catch (OFReadFailedException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(@"failed_to_read_file",
		    @"Failed to read file %[file]: %[error]",
		    @"file", IRI.string,
		    @"error", OFStrError(e.errNo))];
		goto error;
	} @catch (OFSeekFailedException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(@"failed_to_seek_in_file",
		    @"Failed to seek in file %[file]: %[error]",
		    @"file", IRI.string,
		    @"error", OFStrError(e.errNo))];
		goto error;
	} @catch (OFInvalidFormatException *e) {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"file_is_not_a_valid_archive",
		    @"File %[file] is not a valid archive!",
		    @"file", IRI.string)];
		goto error;
	}

	if ((mode == 'a' || mode == 'c') && ![archive respondsToSelector:
	    @selector(addFiles:archiveComment:)]) {
		writingNotSupported(type);
		goto error;
	}

	return archive;

error:
	if (mode == 'c' && IRI != nil)
		[[OFFileManager defaultManager] removeItemAtIRI: IRI];

	[OFApplication terminateWithStatus: 1];
	abort();
}

- (bool)shouldExtractFile: (OFString *)fileName
	      outFileName: (OFString *)outFileName
{
	OFString *line;

	if (_overwrite == 1 ||
	    ![[OFFileManager defaultManager] fileExistsAtPath: outFileName])
		return true;

	if (_overwrite == -1) {
		if (_outputLevel >= 0) {
			[OFStdOut writeString: @" "];
			[OFStdOut writeLine:
			    OF_LOCALIZED(@"file_skipped", @"skipped")];
		}
		return false;
	}

	do {
		[OFStdErr writeString: @"\r"];
		[OFStdErr writeString: OF_LOCALIZED(@"ask_overwrite",
		    @"Overwrite %[file]? [ynAN?]",
		    @"file", fileName)];
		[OFStdErr writeString: @" "];

		line = [OFStdIn readLine];

		if ([line isEqual: @"?"])
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"ask_overwrite_help",
			    @" y: yes\n"
			    @" n: no\n"
			    @" A: always\n"
			    @" N: never")];
	} while (![line isEqual: @"y"] && ![line isEqual: @"n"] &&
	    ![line isEqual: @"N"] && ![line isEqual: @"A"]);

	if ([line isEqual: @"A"])
		_overwrite = 1;
	else if ([line isEqual: @"N"])
		_overwrite = -1;

	if ([line isEqual: @"n"] || [line isEqual: @"N"]) {
		if (_outputLevel >= 0)
			[OFStdOut writeLine: OF_LOCALIZED(@"skipping_file",
			    @"Skipping %[file]...",
			    @"file", fileName)];

		return false;
	}

	if (_outputLevel >= 0)
		[OFStdOut writeString: OF_LOCALIZED(@"extracting_file",
		    @"Extracting %[file]...",
		    @"file", fileName)];

	return true;
}

- (ssize_t)copyBlockFromStream: (OFStream *)input
		      toStream: (OFStream *)output
		      fileName: (OFString *)fileName
{
	char buffer[bufferSize];
	size_t length;

	@try {
		length = [input readIntoBuffer: buffer length: bufferSize];
	} @catch (OFReadFailedException *e) {
		[OFStdOut writeString: @"\r"];
		[OFStdErr writeLine: OF_LOCALIZED(@"failed_to_read_file",
		    @"Failed to read file %[file]: %[error]",
		    @"file", fileName,
		    @"error", OFStrError(e.errNo))];
		return -1;
	}

	@try {
		[output writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		[OFStdOut writeString: @"\r"];
		[OFStdErr writeLine: OF_LOCALIZED(@"failed_to_write_file",
		    @"Failed to write file %[file]: %[error]",
		    @"file", fileName,
		    @"error", OFStrError(e.errNo))];
		return -1;
	}

	return length;
}

- (OFString *)safeLocalPathForPath: (OFString *)path
{
	void *pool = objc_autoreleasePoolPush();

	path = path.stringByStandardizingPath;

#if defined(OF_WINDOWS) || defined(OF_MSDOS)
	if ([path containsString: @":"] || [path hasPrefix: @"\\"]) {
#elif defined(OF_AMIGAOS)
	if ([path containsString: @":"] || [path hasPrefix: @"/"]) {
#else
	if ([path hasPrefix: @"/"]) {
#endif
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if (path.length == 0) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	/*
	 * After -[stringByStandardizingPath], everything representing parent
	 * directory should be at the beginning, so in theory checking the
	 * first component should be enough. But it does not hurt being
	 * paranoid and checking all components, just in case.
	 */
	for (OFString *component in path.pathComponents) {
#ifdef OF_AMIGAOS
		if (component.length == 0 || [component isEqual: @"/"]) {
#else
		if (component.length == 0 || [component isEqual: @".."]) {
#endif
			objc_autoreleasePoolPop(pool);
			return nil;
		}
	}

	[path retain];

	objc_autoreleasePoolPop(pool);

	return [path autorelease];
}

- (void)quarantineFile: (OFString *)path
{
#ifdef OF_MACOS
	if (_quarantine != nil)
		[[OFFileManager defaultManager]
		    setExtendedAttributeData: _quarantine
				     forName: @"com.apple.quarantine"
				ofItemAtPath: path];
#endif
}
@end
