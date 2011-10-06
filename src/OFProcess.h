#include <sys/types.h>

#import "OFStream.h"

/**
 * \brief A class for stream-like communication with a newly created process.
 */
@interface OFProcess: OFStream
{
	pid_t pid;
	int readPipe[2], writePipe[2];
	int status;
	BOOL atEndOfStream;
}

/**
 * \brief Creates a new OFProcess with the specified program, program name and
 *	  arguments and invokes the program.
 *
 * \param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * \param programName The program name for the program to invoke (argv[0]).
 *		      Usually, this is equal to program.
 * \param arguments The arguments to pass to the program, or nil
 * \return A new, autoreleased OFProcess.
 */
+ processWithProgram: (OFString*)program
	 programName: (OFString*)programName
	   arguments: (OFArray*)arguments;

/**
 * \brief Initializes an already allocated OFProcess with the specified
 *	  program, program name and arguments and invokes the program.
 *
 * \param program The program to execute. If it does not start with a slash, the
 *		  search path specified in PATH is used.
 * \param programName The program name for the program to invoke (argv[0]).
 *		      Usually, this is equal to program.
 * \param arguments The arguments to pass to the program, or nil
 * \return An initialized OFProcess.
 */
- initWithProgram: (OFString*)program
      programName: (OFString*)programName
	arguments: (OFArray*)arguments;
@end
