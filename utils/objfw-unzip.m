#import "OFApplication.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFStdIOStream.h"
#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"

#import "autorelease.h"
#import "macros.h"

#define BUFFER_SIZE 4096

@interface UnZIP: OFObject
- (void)extractAllFilesFromArchive: (OFZIPArchive*)archive;
@end

OF_APPLICATION_DELEGATE(UnZIP)

@implementation UnZIP
- (void)applicationDidFinishLaunching
{
	OFEnumerator *enumerator = [[OFApplication arguments] objectEnumerator];
	OFString *file;

	while ((file = [enumerator nextObject]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		[self extractAllFilesFromArchive:
		    [OFZIPArchive archiveWithPath: file]];

		objc_autoreleasePoolPop(pool);
	}

	[OFApplication terminate];
}

- (void)extractAllFilesFromArchive: (OFZIPArchive*)archive
{
	OFEnumerator *enumerator = [[archive entries] objectEnumerator];
	OFZIPArchiveEntry *entry;
	bool override = false;

	while ((entry = [enumerator nextObject]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = [entry fileName];
		OFString *outFileName = [fileName stringByStandardizingPath];
		OFEnumerator *componentEnumerator;
		OFString *component, *directory;
		OFStream *stream;
		OFFile *output;
		char buffer[BUFFER_SIZE];
		off_t written = 0, size = [entry uncompressedSize];
		int_fast8_t percent = -1, newPercent;

#ifndef _WIN32
		if ([outFileName hasPrefix: @"/"]) {
#else
		if ([outFileName hasPrefix: @"/"] ||
		    [outFileName containsString: @":"]) {
#endif
			[of_stdout writeFormat: @"Refusing to extract %@!\n",
						fileName];
			[OFApplication terminateWithStatus: 1];
		}

		componentEnumerator =
		    [[outFileName pathComponents] objectEnumerator];
		while ((component = [componentEnumerator nextObject]) != nil) {
			if ([component isEqual: OF_PATH_PARENT_DIRECTORY]) {
				[of_stdout writeFormat:
				    @"Refusing to extract %@!\n", fileName];
				[OFApplication terminateWithStatus: 1];
			}
		}

		[of_stdout writeFormat: @"Extracting %@...", fileName];

		if ([fileName hasSuffix: @"/"]) {
			[OFFile createDirectoryAtPath: outFileName
					createParents: true];
			[of_stdout writeLine: @" done"];
			continue;
		}

		directory = [outFileName stringByDeletingLastPathComponent];
		if (![OFFile directoryExistsAtPath: directory])
			[OFFile createDirectoryAtPath: directory
					createParents: true];

		if ([OFFile fileExistsAtPath: outFileName] && !override) {
			OFString *line;

			do {
				[of_stderr writeFormat:
				    @"\rOverride %@? [ynA] ", fileName];

				line = [of_stdin readLine];
			} while (![line isEqual: @"y"] &&
			    ![line isEqual: @"n"] && ![line isEqual: @"A"]);

			if ([line isEqual: @"n"]) {
				[of_stdout writeFormat: @"Skipping %@...\n",
							fileName];
				continue;
			}

			if ([line isEqual: @"A"])
				override = true;

			[of_stdout writeFormat: @"Extracting %@...", fileName];
		}

		stream = [archive streamForReadingFile: fileName];
		output = [OFFile fileWithPath: outFileName
					 mode: @"w"];

		while (![stream isAtEndOfStream]) {
			size_t length = [stream readIntoBuffer: buffer
							length: BUFFER_SIZE];
			[output writeBuffer: buffer
				     length: length];

			written += length;
			newPercent = (written == size
			    ? 100 : written * 100 / size);

			if (percent != newPercent) {
				percent = newPercent;

				[of_stdout writeFormat:
				    @"\rExtracting %@... %3u%%",
				    fileName, percent];
			}
		}

		[of_stdout writeFormat: @"\rExtracting %@... done\n", fileName];

		objc_autoreleasePoolPop(pool);
	}
}
@end
