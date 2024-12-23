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

#include "unistd_wrapper.h"

#import "OFCFRunLoopKernelEventObserver.h"
#import "OFMapTable.h"
#import "OFPair.h"
#import "OFRunLoop.h"

#import "OFInitializationFailedException.h"
#import "OFObserveKernelEventsFailedException.h"

extern id objc_retain(id object);
extern void objc_release(id object);

@interface OFKernelEventObserver (CFRunLoop)
@end

struct MapTableEntry {
	CFSocketRef socket;
	CFRunLoopSourceRef source;
	CFOptionFlags types;
};

static void
freeMapTableEntry(void *object)
{
	struct MapTableEntry *entry = object;

	if (entry->source != NULL) {
		CFRunLoopSourceInvalidate(entry->source);
		CFRelease(entry->source);
	}

	if (entry->socket != NULL) {
		CFSocketInvalidate(entry->socket);
		CFRelease(entry->socket);
	}

	free(entry);
}

static OFMapTableFunctions objectFunctions = {
	.retain = (void *(*)(void *))objc_retain,
	.release = (void (*)(void *))objc_release
};
static OFMapTableFunctions mapTableEntryFunctions = {
	.release = freeMapTableEntry
};

#ifdef __clang__
# pragma clang diagnostic push
# pragma clang diagnostic ignored "-Wunknown-pragmas"
# pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
#endif
@implementation OFKernelEventObserver (CFRunLoop)
+ (instancetype)alloc
{
	if (self == [OFKernelEventObserver class])
		return [OFCFRunLoopKernelEventObserver alloc];

	return [super alloc];
}

+ (bool)handlesForeignEvents
{
	return true;
}
@end
#ifdef __clang__
# pragma clang diagnostic pop
#endif

@implementation OFCFRunLoopKernelEventObserver
static void
callback(CFSocketRef sock, CFSocketCallBackType type, CFDataRef address,
    const void *data, void *info_)
{
	OFPair *info = info_;
	id object;
	OFCFRunLoopKernelEventObserver *observer;

	OFAssert(info != nil);

	object = info.firstObject;
	observer = info.secondObject;

	if (object == nil) {
		char buffer;

		OFAssert(sock == observer->_cancelSocket);
		OFAssert(type == kCFSocketReadCallBack);
		OFEnsure(read(observer->_cancelFD[0], &buffer, 1) == 1);

		return;
	}

	if (type & kCFSocketReadCallBack)
		[observer->_delegate objectIsReadyForReading: object];
	if (type & kCFSocketWriteCallBack)
		[observer->_delegate objectIsReadyForWriting: object];
}

+ (unsigned int)of_createID
{
	@synchronized (self) {
		static unsigned int ID = 0;

		return ID++;
	}
}

- (instancetype)initWithRunLoopMode: (OFRunLoopMode)mode
{
	self = [super initWithRunLoopMode: mode];

	@try {
		void *pool = objc_autoreleasePoolPush();
		CFSocketContext context = {
			.version = 0,
			.info = [OFPair pairWithFirstObject: nil
					       secondObject: self],
			.retain = (const void *(*)(const void *))objc_retain,
			.release = (void (*)(const void *))objc_release
		};
		CFOptionFlags flags;

		_runLoop = (CFRunLoopRef)CFRetain(CFRunLoopGetCurrent());

		if ([mode isEqual: OFDefaultRunLoopMode])
			_runLoopMode = CFRetain(kCFRunLoopDefaultMode);
		else
			_runLoopMode = CFStringCreateWithFormat(
			    kCFAllocatorDefault, NULL,
			    CFSTR("OFCFRunLoopKernelEventObserver_%u"),
			    [OFCFRunLoopKernelEventObserver of_createID]);

		if (_runLoopMode == NULL)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_mapTable = [[OFMapTable alloc]
		    initWithKeyFunctions: objectFunctions
			 objectFunctions: mapTableEntryFunctions];

		_cancelSocket = CFSocketCreateWithNative(kCFAllocatorDefault,
		    _cancelFD[0], kCFSocketReadCallBack, callback, &context);
		if (_cancelSocket == NULL)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		flags = CFSocketGetSocketFlags(_cancelSocket);
		flags &= ~kCFSocketCloseOnInvalidate;
		CFSocketSetSocketFlags(_cancelSocket, flags);

		_cancelSource = CFSocketCreateRunLoopSource(
		    kCFAllocatorDefault, _cancelSocket, 0);
		if (_cancelSource == NULL)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		CFRunLoopAddSource(_runLoop, _cancelSource, _runLoopMode);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_cancelSource != NULL) {
		CFRunLoopSourceInvalidate(_cancelSource);
		CFRelease(_cancelSource);
	}

	if (_cancelSocket != NULL) {
		CFSocketInvalidate(_cancelSocket);
		CFRelease(_cancelSocket);
	}

	if (_runLoop != NULL)
		CFRelease(_runLoop);
	if (_runLoopMode != NULL)
		CFRelease(_runLoopMode);

	[_mapTable release];

	[super dealloc];
}

- (void)of_updateObject: (id)object
	 fileDescriptor: (int)fd
	       addTypes: (CFOptionFlags)addTypes
	    removeTypes: (CFOptionFlags)removeTypes
{
	/*
	 * This method destroys the old CFSocket and CFRunLoopSource and creates
	 * new ones. While this might sound inefficient, there is unfortunately
	 * no other way, as using CFSocket{Enable,Disable}CallBacks from a
	 * callback does not work as expected.
	 */

	void *pool = objc_autoreleasePoolPush();
	CFSocketContext context = {
		.version = 0,
	};
	CFOptionFlags types = 0;
	struct MapTableEntry *oldEntry, *newEntry;

	if ((oldEntry = [_mapTable objectForKey: object]) != NULL)
		types = oldEntry->types;

	types = (types | addTypes) & ~removeTypes;

	if (types == 0) {
		[_mapTable removeObjectForKey: object];
		objc_autoreleasePoolPop(pool);
		return;
	}

	newEntry = OFAllocZeroedMemory(1, sizeof(*newEntry));
	@try {
		CFOptionFlags flags;

		context.info = [OFPair pairWithFirstObject: object
					      secondObject: self];
		context.retain = (const void *(*)(const void *))objc_retain;
		context.release = (void (*)(const void *))objc_release;

		if ((newEntry->socket = CFSocketCreateWithNative(
		    kCFAllocatorDefault, fd, types, callback,
		    &context)) == NULL)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: 0];

		flags = CFSocketGetSocketFlags(newEntry->socket);
		flags &= ~kCFSocketCloseOnInvalidate;
		CFSocketSetSocketFlags(newEntry->socket, flags);

		if ((newEntry->source = CFSocketCreateRunLoopSource(
		    kCFAllocatorDefault, newEntry->socket, 0)) == NULL)
			@throw [OFObserveKernelEventsFailedException
			    exceptionWithObserver: self
					    errNo: 0];

		CFRunLoopAddSource(_runLoop, newEntry->source, _runLoopMode);

		newEntry->types = types;

		[_mapTable setObject: newEntry forKey: object];
	} @catch (id e) {
		freeMapTableEntry(newEntry);
	}

	objc_autoreleasePoolPop(pool);
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[self of_updateObject: object
	       fileDescriptor: [object fileDescriptorForReading]
		     addTypes: kCFSocketReadCallBack
		  removeTypes: 0];

	[super addObjectForReading: object];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
	[self of_updateObject: object
	       fileDescriptor: [object fileDescriptorForWriting]
		     addTypes: kCFSocketWriteCallBack
		  removeTypes: 0];

	[super addObjectForWriting: object];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
	[self of_updateObject: object
	       fileDescriptor: [object fileDescriptorForReading]
		     addTypes: 0
		  removeTypes: kCFSocketReadCallBack];

	[super removeObjectForReading: object];
}

- (void)removeObjectForWriting: (id< OFReadyForWritingObserving>)object
{
	[self of_updateObject: object
	       fileDescriptor: [object fileDescriptorForWriting]
		     addTypes: 0
		  removeTypes: kCFSocketWriteCallBack];

	[super removeObjectForWriting: object];
}

- (void)observeForTimeInterval: (OFTimeInterval)timeInterval
{
	if ([self processReadBuffers])
		return;

	CFRunLoopRunInMode(_runLoopMode, timeInterval, true);
}
@end
