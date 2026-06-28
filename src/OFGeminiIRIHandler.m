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

#include <errno.h>

#import "OFGeminiIRIHandler.h"
#import "OFGeminiClient.h"
#import "OFGeminiResponse.h"
#import "OFIRI.h"
#import "OFTimer.h"

#import "OFOpenItemFailedException.h"

OF_DIRECT_MEMBERS
@interface OFGeminiIRIHandlerAsyncOpener: OFObject <OFGeminiClientDelegate>
{
	OFIRIHandler *_IRIHandler;
	OFIRI *_IRI;
	id <OFIRIHandlerDelegate> _delegate;
	OFGeminiClient *_client;
}

- (instancetype)initWithIRIHandler: (OFIRIHandler *)IRIHandler
			       IRI: (OFIRI *)IRI
			  delegate: (id <OFIRIHandlerDelegate>)delegate;
- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode;
@end

@implementation OFGeminiIRIHandlerAsyncOpener
- (instancetype)initWithIRIHandler: (OFIRIHandler *)IRIHandler
			       IRI: (OFIRI *)IRI
			  delegate: (id <OFIRIHandlerDelegate>)delegate
{
	self = [super init];

	@try {
		_IRIHandler = objc_retain(IRIHandler);
		_IRI = [IRI copy];
		_delegate = objc_retain(delegate);

		_client = [[OFGeminiClient alloc] init];
		_client.delegate = self;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_IRIHandler);
	objc_release(_IRI);
	objc_release(_delegate);
	objc_release(_client);

	[super dealloc];
}

- (void)startWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();

	[_client asyncPerformRequestForIRI: _IRI
				 redirects: 10
			       runLoopMode: runLoopMode];
	objc_retain(self);

	objc_autoreleasePoolPop(pool);
}

-	     (void)client: (OFGeminiClient *)client
  didPerformRequestForIRI: (OFIRI *)IRI
		 response: (OFGeminiResponse *)response
		exception: (id)exception
{
	@try {
		[_delegate IRIHandler: _IRIHandler
		     didOpenItemAtIRI: _IRI
			       stream: response
			    exception: exception];
	} @finally {
		objc_release(self);
	}
}
@end

@implementation OFGeminiIRIHandler
- (OF_KINDOF(OFStream *))openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	void *pool;
	OFGeminiClient *client;
	OFGeminiResponse *response;

	if (![mode isEqual: @"r"])
		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: mode
							     errNo: EROFS];

	pool = objc_autoreleasePoolPush();
	client = [OFGeminiClient client];
	response = [client performRequestForIRI: IRI];

	objc_retain(response);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(response);
}

- (void)asyncOpenItemAtIRI: (OFIRI *)IRI
		      mode: (OFString *)mode
		  delegate: (id <OFIRIHandlerDelegate>)delegate
	       runLoopMode: (OFRunLoopMode)runLoopMode
{
	void *pool = objc_autoreleasePoolPush();
	OFGeminiIRIHandlerAsyncOpener *opener;

	if (![mode isEqual: @"r"]) {
		id exception = [OFOpenItemFailedException
		    exceptionWithIRI: IRI
				mode: mode
			       errNo: EROFS];
		OFTimer *timer = [OFTimer
		    timerWithTimeInterval: 0
				   target: delegate
				 selector: @selector(IRIHandler:
					       didOpenItemAtIRI:stream:
					       exception:)
				   object: self
				   object: IRI
				   object: nil
				   object: exception
				  repeats: false];
		[[OFRunLoop currentRunLoop] addTimer: timer
					     forMode: runLoopMode];
		objc_autoreleasePoolPop(pool);
		return;
	}

	opener = objc_autorelease([[OFGeminiIRIHandlerAsyncOpener alloc]
	    initWithIRIHandler: self
			   IRI: IRI
		      delegate: delegate]);

	[opener startWithRunLoopMode: runLoopMode];

	objc_autoreleasePoolPop(pool);
}
@end
