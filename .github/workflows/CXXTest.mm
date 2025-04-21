#import <ObjFW/ObjFW.h>

#include <string>

@interface CXXTest: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(CXXTest)

@implementation CXXTest
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	std::string output;

	try {
		@try {
			throw @"Hello ";
		} @catch (OFString *string) {
			output += string.UTF8String;
		}

		throw std::string("C++");
	} catch (std::string &string) {
		output += "C++";
	}

	OFLog(@"%s", output.c_str());

	[OFApplication terminate];
}
@end
