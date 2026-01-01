/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFIRIHandler.h"
#import "OFDictionary.h"
#import "OFIRI.h"
#import "OFNumber.h"

#import "OFArchiveIRIHandler.h"
#import "OFEmbeddedIRIHandler.h"
#ifdef OF_HAVE_FILES
# import "OFFileIRIHandler.h"
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
# import "OFHTTPIRIHandler.h"
#endif

#import "OFUnsupportedProtocolException.h"

static OFMutableDictionary OF_GENERIC(OFString *, OFIRIHandler *) *handlers;

@implementation OFIRIHandler
@synthesize scheme = _scheme;

+ (void)initialize
{
	if (self != [OFIRIHandler class])
		return;

	handlers = [[OFMutableDictionary alloc] init];

	[self registerClass: [OFEmbeddedIRIHandler class]
		  forScheme: @"embedded"];
#ifdef OF_HAVE_FILES
	[self registerClass: [OFFileIRIHandler class] forScheme: @"file"];
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self registerClass: [OFHTTPIRIHandler class] forScheme: @"http"];
	[self registerClass: [OFHTTPIRIHandler class] forScheme: @"https"];
#endif
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"gzip"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"lha"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"tar"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"zip"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"zoo"];
}

+ (bool)registerClass: (Class)class forScheme: (OFString *)scheme
{
	@synchronized (handlers) {
		OFIRIHandler *handler;

		if ([handlers objectForKey: scheme] != nil)
			return false;

		handler = [[class alloc] initWithScheme: scheme];
		@try {
			[handlers setObject: handler forKey: scheme];
		} @finally {
			objc_release(handler);
		}
	}

	return true;
}

+ (OFIRIHandler *)handlerForIRI: (OFIRI *)IRI
{
	OFIRIHandler *handler;

	@synchronized (handlers) {
		handler = [handlers objectForKey: IRI.scheme];
	}

	if (handler == nil)
		@throw [OFUnsupportedProtocolException exceptionWithIRI: IRI];

	return handler;
}

+ (OF_KINDOF(OFStream *))openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	return [[self handlerForIRI: IRI] openItemAtIRI: IRI mode: mode];
}

+ (void)asyncOpenItemAtIRI: (OFIRI *)IRI
		      mode: (OFString *)mode
		  delegate: (id <OFIRIHandlerDelegate>)delegate
{
	[[self handlerForIRI: IRI] asyncOpenItemAtIRI: IRI
						 mode: mode
					     delegate: delegate];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithScheme: (OFString *)scheme
{
	self = [super init];

	@try {
		_scheme = [scheme copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_scheme);

	[super dealloc];
}

- (OF_KINDOF(OFStream *))openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)asyncOpenItemAtIRI: (OFIRI *)IRI
		      mode: (OFString *)mode
		  delegate: (id <OFIRIHandlerDelegate>)delegate
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFFileAttributes)attributesOfItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)fileExistsAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)directoryExistsAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createDirectoryAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFArray OF_GENERIC(OFIRI *) *)contentsOfDirectoryAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)linkItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createSymbolicLinkAtIRI: (OFIRI *)destination
	    withDestinationPath: (OFString *)source
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)copyItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	return false;
}

- (bool)moveItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	return false;
}

- (OFData *)extendedAttributeDataForName: (OFString *)name
			     ofItemAtIRI: (OFIRI *)IRI
{
	OFData *data;

	[self getExtendedAttributeData: &data
			       andType: NULL
			       forName: name
			   ofItemAtIRI: IRI];

	return data;
}

- (void)getExtendedAttributeData: (OFData **)data
			 andType: (id *)type
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI
{
	/*
	 * Only call into -[extendedAttributeDataForName:ofItemAtIRI:] if it
	 * has been overridden. This is to be backwards-compatible with
	 * subclasses that predate the introduction of
	 * -[getExtendedAttributeData:andType:forName:ofItemAtIRI:].
	 * Without this check, this would result in an infinite loop.
	 */
	SEL selector = @selector(extendedAttributeDataForName:ofItemAtIRI:);

	if (class_getMethodImplementation(object_getClass(self), selector) !=
	    class_getMethodImplementation([OFIRIHandler class], selector)) {
		/* Use -[methodForSelector:] to avoid deprecation warning. */
		OFData *(*imp)(id, SEL, OFString *, OFIRI *) =
		    (OFData *(*)(id, SEL, OFString *, OFIRI *))
		    [self methodForSelector: selector];

		*data = imp(self, selector, name, IRI);

		if (type != NULL)
			*type = nil;

		return;
	}

	OF_UNRECOGNIZED_SELECTOR
}

- (void)setExtendedAttributeData: (OFData *)data
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI
{
	[self setExtendedAttributeData: data
			       andType: nil
			       forName: name
			   ofItemAtIRI: IRI];
}

- (void)setExtendedAttributeData: (OFData *)data
			 andType: (id)type
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI
{
	if (type == nil) {
		/*
		 * Only call into
		 * -[setExtendedAttributeData:forName:ofItemAtIRI:] if it has
		 * been overridden. This is to be backwards-compatible with
		 * subclasses that predate the introduction of
		 * -[setExtendedAttributeData:andType:forName:ofItemAtIRI:].
		 * Without this check, this would result in an infinite loop.
		 */
		SEL selector =
		    @selector(setExtendedAttributeData:forName:ofItemAtIRI:);

		if (class_getMethodImplementation(object_getClass(self),
		    selector) !=
		    class_getMethodImplementation([OFIRIHandler class],
		    selector)) {
			/*
			 * Use -[methodForSelector:] to avoid deprecation
			 * warning.
			 */
			void (*imp)(id, SEL, OFData *, OFString *, OFIRI *) =
			    (void (*)(id, SEL, OFData *, OFString *, OFIRI *))
			    [self methodForSelector: selector];

			imp(self, selector, data, name, IRI);
			return;
		}
	}

	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeExtendedAttributeForName: (OFString *)name
			   ofItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
