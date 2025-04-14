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

#include <errno.h>

#import "OFRunLoop.h"
#import "OFRunLoop+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_SOCKETS
# import "OFKernelEventObserver.h"
# import "OFDatagramSocket.h"
# import "OFSequencedPacketSocket.h"
# import "OFSequencedPacketSocket+Private.h"
# import "OFStreamSocket.h"
# import "OFStreamSocket+Private.h"
#endif
#import "OFThread.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
# import "OFCondition.h"
#endif
#import "OFSortedList.h"
#import "OFTimer.h"
#import "OFTimer+Private.h"
#import "OFDate.h"

#import "OFObserveKernelEventsFailedException.h"
#import "OFWriteFailedException.h"

#include "OFRunLoopConstants.inc"

static OFRunLoop *mainRunLoop = nil;

@interface OFRunLoopState: OFObject
#ifdef OF_HAVE_SOCKETS
    <OFKernelEventObserverDelegate>
#endif
{
@public
	OFSortedList OF_GENERIC(OFTimer *) *_timersQueue;
#ifdef OF_HAVE_THREADS
	OFMutex *_timersQueueMutex;
#endif
#ifdef OF_HAVE_SOCKETS
	OFKernelEventObserver *_kernelEventObserver;
	OFMutableDictionary *_readQueues, *_writeQueues;
#endif
#ifdef OF_HAVE_THREADS
	OFCondition *_condition;
# ifdef OF_AMIGAOS
	ULONG _execSignalMask;
# endif
#endif
#ifdef OF_AMIGAOS
	OFMutableData *_execSignals;
	OFMutableArray *_execSignalsTargets;
	OFMutableData *_execSignalsSelectors;
# ifdef OF_HAVE_THREADS
	OFMutex *_execSignalsMutex;
# endif
#endif
}

- (instancetype)init OF_UNAVAILABLE;
- (instancetype)initWithMode: (OFRunLoopMode)mode;
@end

#ifdef OF_HAVE_SOCKETS
@interface OFRunLoopQueueItem: OFObject
{
@public
	id _delegate;
}

- (bool)handleObject: (id)object;
@end

@interface OFRunLoopReadQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFStreamReadHandler _handler;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoopExactReadQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFStreamReadHandler _handler;
# endif
	void *_buffer;
	size_t _exactLength, _readLength;
}
@end

@interface OFRunLoopReadStringQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFStreamStringReadHandler _handler;
# endif
	OFStringEncoding _encoding;
}
@end

@interface OFRunLoopReadLineQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFStreamStringReadHandler _handler;
# endif
	OFStringEncoding _encoding;
}
@end

@interface OFRunLoopWriteDataQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFStreamDataWrittenHandler _handler;
# endif
	OFData *_data;
	size_t _writtenLength;
}
@end

@interface OFRunLoopWriteStringQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFStreamStringWrittenHandler _handler;
# endif
	OFString *_string;
	OFStringEncoding _encoding;
	size_t _writtenLength;
}
@end

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
@interface OFRunLoopConnectQueueItem: OFRunLoopQueueItem
@end
# endif

@interface OFRunLoopAcceptQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	id _handler;
# endif
}
@end

@interface OFRunLoopDatagramReceiveQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFDatagramSocketPacketReceivedHandler _handler;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoopDatagramSendQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFDatagramSocketDataSentHandler _handler;
# endif
	OFData *_data;
	OFSocketAddress _receiver;
}
@end

@interface OFRunLoopPacketReceiveQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFSequencedPacketSocketPacketReceivedHandler _handler;
# endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoopPacketSendQueueItem: OFRunLoopQueueItem
{
@public
# ifdef OF_HAVE_BLOCKS
	OFSequencedPacketSocketDataSentHandler _handler;
# endif
	OFData *_data;
}
@end

# ifdef OF_HAVE_SCTP
@interface OFRunLoopSCTPReceiveQueueItem: OFRunLoopQueueItem
{
@public
#  ifdef OF_HAVE_BLOCKS
	OFSCTPSocketMessageReceivedHandler _handler;
#  endif
	void *_buffer;
	size_t _length;
}
@end

@interface OFRunLoopSCTPSendQueueItem: OFRunLoopQueueItem
{
@public
#  ifdef OF_HAVE_BLOCKS
	OFSCTPSocketDataSentHandler _handler;
#  endif
	OFData *_data;
	OFSCTPMessageInfo _info;
}
@end
# endif
#endif

@implementation OFRunLoopState
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithMode: (OFRunLoopMode)mode
{
	self = [super init];

	@try {
		_timersQueue = [[OFSortedList alloc] init];
#ifdef OF_HAVE_THREADS
		_timersQueueMutex = [[OFMutex alloc] init];
#endif

#ifdef OF_HAVE_SOCKETS
		_readQueues = [[OFMutableDictionary alloc] init];
		_writeQueues = [[OFMutableDictionary alloc] init];

		if ([OFKernelEventObserver handlesForeignEvents]) {
			_kernelEventObserver = [[OFKernelEventObserver alloc]
			    initWithRunLoopMode: mode];
			_kernelEventObserver.delegate = self;
		}
#endif
#if defined(OF_HAVE_THREADS)
		_condition = [[OFCondition alloc] init];
#endif
#ifdef OF_AMIGAOS
		_execSignals = [[OFMutableData alloc]
		    initWithItemSize: sizeof(ULONG)];
		_execSignalsTargets = [[OFMutableArray alloc] init];
		_execSignalsSelectors = [[OFMutableData alloc]
		    initWithItemSize: sizeof(SEL)];
# ifdef OF_HAVE_THREADS
		_execSignalsMutex = [[OFMutex alloc] init];
# endif
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_timersQueue);
#ifdef OF_HAVE_THREADS
	objc_release(_timersQueueMutex);
#endif
#ifdef OF_HAVE_SOCKETS
	objc_release(_kernelEventObserver);
	objc_release(_readQueues);
	objc_release(_writeQueues);
#endif
#ifdef OF_HAVE_THREADS
	objc_release(_condition);
#endif
#ifdef OF_AMIGAOS
	objc_release(_execSignals);
	objc_release(_execSignalsTargets);
	objc_release(_execSignalsSelectors);
# ifdef OF_HAVE_THREADS
	objc_release(_execSignalsMutex);
# endif
#endif

	[super dealloc];
}

#ifdef OF_HAVE_SOCKETS
- (void)objectIsReadyForReading: (id)object
{
	/*
	 * Retain the queue so that it doesn't disappear from us because the
	 * handler called -[cancelAsyncRequests].
	 */
	OFList OF_GENERIC(OF_KINDOF(OFRunLoopReadQueueItem *)) *queue =
	    objc_retain([_readQueues objectForKey: object]);

	OFAssert(queue != nil);

	@try {
		if (![queue.firstObject handleObject: object]) {
			OFListItem listItem = queue.firstListItem;

			/*
			 * The handler might have called -[cancelAsyncRequests]
			 * so that our queue is now empty, in which case we
			 * should do nothing.
			 */
			if (listItem != NULL) {
				/*
				 * Make sure we keep the target until after we
				 * are done removing the object. The reason for
				 * this is that the target might call
				 * -[cancelAsyncRequests] in its dealloc.
				 */
				objc_retainAutorelease(
				    OFListItemObject(listItem));

				[queue removeListItem: listItem];

				if (queue.count == 0) {
					[_kernelEventObserver
					    removeObjectForReading: object];
					[_readQueues
					    removeObjectForKey: object];
				}
			}
		}
	} @finally {
		objc_release(queue);
	}
}

- (void)objectIsReadyForWriting: (id)object
{
	/*
	 * Retain the queue so that it doesn't disappear from us because the
	 * handler called -[cancelAsyncRequests].
	 */
	OFList *queue = objc_retain([_writeQueues objectForKey: object]);

	OFAssert(queue != nil);

	@try {
		if (![queue.firstObject handleObject: object]) {
			OFListItem listItem = queue.firstListItem;

			/*
			 * The handler might have called -[cancelAsyncRequests]
			 * so that our queue is now empty, in which case we
			 * should do nothing.
			 */
			if (listItem != NULL) {
				/*
				 * Make sure we keep the target until after we
				 * are done removing the object. The reason for
				 * this is that the target might call
				 * -[cancelAsyncRequests] in its dealloc.
				 */
				objc_retainAutorelease(
				    OFListItemObject(listItem));

				[queue removeListItem: listItem];

				if (queue.count == 0) {
					[_kernelEventObserver
					    removeObjectForWriting: object];
					[_writeQueues
					    removeObjectForKey: object];
				}
			}
		}
	} @finally {
		objc_release(queue);
	}
}
#endif

#ifdef OF_AMIGAOS
- (void)execSignalWasReceived: (ULONG)signalMask
{
	void *pool = objc_autoreleasePoolPush();
	OFData *signals;
	OFArray *targets;
	OFData *selectors;
	const ULONG *signalsItems;
	const id *targetsObjects;
	const SEL *selectorsItems;
	size_t count;

# ifdef OF_HAVE_THREADS
	[_execSignalsMutex lock];
	@try {
# endif
		/*
		 * Create copies, so that signal handlers are allowed to modify
		 * signals.
		 */
		signals = objc_autorelease([_execSignals copy]);
		targets = objc_autorelease([_execSignalsTargets copy]);
		selectors = objc_autorelease([_execSignalsSelectors copy]);
# ifdef OF_HAVE_THREADS
	} @finally {
		[_execSignalsMutex unlock];
	}
# endif

	signalsItems = signals.items;
	targetsObjects = targets.objects;
	selectorsItems = selectors.items;
	count = signals.count;

	for (size_t i = 0; i < count; i++) {
		if (signalMask & (1ul << signalsItems[i])) {
			void (*callback)(id, SEL, ULONG) =
			    (void (*)(id, SEL, ULONG))[targetsObjects[i]
			    methodForSelector: selectorsItems[i]];

			callback(targetsObjects[i], selectorsItems[i],
			    signalsItems[i]);
		}
	}

	objc_autoreleasePoolPop(pool);
}
#endif
@end

#ifdef OF_HAVE_SOCKETS
@implementation OFRunLoopQueueItem
- (bool)handleObject: (id)object
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)dealloc
{
	objc_release(_delegate);

	[super dealloc];
}
@end

@implementation OFRunLoopReadQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;

	@try {
		length = [object readIntoBuffer: _buffer length: _length];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		return _handler(object, _buffer, length, exception);
	else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadIntoBuffer:length:exception:)])
			return false;

		return [_delegate stream: object
		       didReadIntoBuffer: _buffer
				  length: length
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopExactReadQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;

	@try {
		length = [object readIntoBuffer: (char *)_buffer + _readLength
					 length: _exactLength - _readLength];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_readLength += length;

	if (_readLength != _exactLength && ![object isAtEndOfStream] &&
	    exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		if (!_handler(object, _buffer, _readLength, exception))
			return false;

		_readLength = 0;
		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadIntoBuffer:length:exception:)])
			return false;

		if (![_delegate stream: object
		     didReadIntoBuffer: _buffer
				length: _readLength
			     exception: exception])
			return false;

		_readLength = 0;
		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopReadStringQueueItem
- (bool)handleObject: (id)object
{
	OFString *string;
	id exception = nil;

	@try {
		string = [object tryReadStringWithEncoding: _encoding];
	} @catch (id e) {
		string = nil;
		exception = e;
	}

	if (string == nil && ![object isAtEndOfStream] && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		return _handler(object, string, exception);
	else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadString:exception:)])
			return false;

		return [_delegate stream: object
			   didReadString: string
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopReadLineQueueItem
- (bool)handleObject: (id)object
{
	OFString *line;
	id exception = nil;

	@try {
		line = [object tryReadLineWithEncoding: _encoding];
	} @catch (id e) {
		line = nil;
		exception = e;
	}

	if (line == nil && ![object isAtEndOfStream] && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		return _handler(object, line, exception);
	else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didReadLine:exception:)])
			return false;

		return [_delegate stream: object
			     didReadLine: line
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopWriteDataQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;
	size_t dataLength = _data.count * _data.itemSize;
	OFData *newData, *oldData;

	@try {
		const char *dataItems = _data.items;
		length = dataLength - _writtenLength;
		[object writeBuffer: dataItems + _writtenLength length: length];
	} @catch (OFWriteFailedException *e) {
		length = e.bytesWritten;

		if (e.errNo != EWOULDBLOCK && e.errNo != EAGAIN)
			exception = e;
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_writtenLength += length;
	OFEnsure(_writtenLength <= dataLength);

	if (_writtenLength != dataLength && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		newData = _handler(object, _data, _writtenLength, exception);

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		_writtenLength = 0;
		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(stream:didWriteData:bytesWritten:exception:)])
			return false;

		newData = [_delegate stream: object
			       didWriteData: _data
			       bytesWritten: _writtenLength
				  exception: exception];

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		_writtenLength = 0;
		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
# ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
# endif
	objc_release(_data);

	[super dealloc];
}
@end

@implementation OFRunLoopWriteStringQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;
	size_t cStringLength = [_string cStringLengthWithEncoding: _encoding];
	OFString *newString, *oldString;

	@try {
		const char *cString = [_string cStringWithEncoding: _encoding];
		length = cStringLength - _writtenLength;
		[object writeBuffer: cString + _writtenLength length: length];
	} @catch (OFWriteFailedException *e) {
		length = e.bytesWritten;

		if (e.errNo != EWOULDBLOCK && e.errNo != EAGAIN)
			exception = e;
	} @catch (id e) {
		length = 0;
		exception = e;
	}

	_writtenLength += length;
	OFEnsure(_writtenLength <= cStringLength);

	if (_writtenLength != cStringLength && exception == nil)
		return true;

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		newString = _handler(object, _string, _encoding, _writtenLength,
		    exception);

		if (newString == nil)
			return false;

		oldString = _string;
		_string = [newString copy];
		objc_release(oldString);

		_writtenLength = 0;
		return true;
	} else {
# endif
		if (![_delegate respondsToSelector: @selector(stream:
		    didWriteString:encoding:bytesWritten:exception:)])
			return false;

		newString = [_delegate stream: object
			       didWriteString: _string
				     encoding: _encoding
				 bytesWritten: _writtenLength
				    exception: exception];

		if (newString == nil)
			return false;

		oldString = _string;
		_string = [newString copy];
		objc_release(oldString);

		_writtenLength = 0;
		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
	objc_release(_string);
# ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
# endif

	[super dealloc];
}
@end

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
@implementation OFRunLoopConnectQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;
	int errNo;

	if ((errNo = [object of_socketError]) != 0)
		exception =
		    [_delegate of_connectionFailedExceptionForErrNo: errNo];

	if ([_delegate respondsToSelector:
	    @selector(of_socketDidConnect:exception:)]) {
		/*
		 * Make sure we only call the delegate once we removed the
		 * socket from the kernel event observer. This is necessary as
		 * otherwise we could try to connect to the next address and it
		 * would not be re-registered with the kernel event observer,
		 * which is necessary for some kernel event observers (e.g.
		 * epoll) even if the fd of the new socket is the same.
		 */
		OFRunLoop *runLoop = [OFRunLoop currentRunLoop];
		OFTimer *timer = [OFTimer
		    timerWithTimeInterval: 0
				   target: _delegate
				 selector: @selector(of_socketDidConnect:
					       exception:)
				   object: object
				   object: exception
				  repeats: false];
		[runLoop addTimer: timer forMode: runLoop.currentMode];
	}

	return false;
}
@end
# endif

@implementation OFRunLoopAcceptQueueItem
- (bool)handleObject: (id)object
{
	id acceptedSocket, exception = nil;

	@try {
		acceptedSocket = [object accept];
	} @catch (id e) {
		acceptedSocket = nil;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		if ([object isKindOfClass: [OFStreamSocket class]])
			return ((OFStreamSocketAcceptedHandler)
			    _handler)(object, acceptedSocket, exception);
		else if ([object isKindOfClass:
		    [OFSequencedPacketSocket class]])
			return ((OFSequencedPacketSocketAcceptedHandler)
			    _handler)(object, acceptedSocket, exception);
		else
			OFEnsure(0);
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(socket:didAcceptSocket:exception:)])
			return false;

		return [_delegate socket: object
			 didAcceptSocket: acceptedSocket
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopDatagramReceiveQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	OFSocketAddress address;
	id exception = nil;

	@try {
		length = [object receiveIntoBuffer: _buffer
					    length: _length
					    sender: &address];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		return _handler(object, _buffer, length, &address, exception);
	else {
# endif
		if (![_delegate respondsToSelector: @selector(
		    socket:didReceiveIntoBuffer:length:sender:exception:)])
			return false;

		return [_delegate socket: object
		    didReceiveIntoBuffer: _buffer
				  length: length
				  sender: &address
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopDatagramSendQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;
	OFData *newData, *oldData;

	@try {
		[object sendBuffer: _data.items
			    length: _data.count * _data.itemSize
			  receiver: &_receiver];
	} @catch (id e) {
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		newData = _handler(object, _data, &_receiver, exception);

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(socket:didSendData:receiver:exception:)])
			return false;

		newData = [_delegate socket: object
				didSendData: _data
				   receiver: &_receiver
				  exception: exception];

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
# ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
# endif
	objc_release(_data);

	[super dealloc];
}
@end

@implementation OFRunLoopPacketReceiveQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	id exception = nil;

	@try {
		length = [object receiveIntoBuffer: _buffer length: _length];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		return _handler(object, _buffer, length, exception);
	else {
# endif
		if (![_delegate respondsToSelector: @selector(
		    socket:didReceiveIntoBuffer:length:exception:)])
			return false;

		return [_delegate socket: object
		    didReceiveIntoBuffer: _buffer
				  length: length
			       exception: exception];
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopPacketSendQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;
	OFData *newData, *oldData;

	@try {
		[object sendBuffer: _data.items
			    length: _data.count * _data.itemSize];
	} @catch (id e) {
		exception = e;
	}

# ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		newData = _handler(object, _data, exception);

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		return true;
	} else {
# endif
		if (![_delegate respondsToSelector:
		    @selector(socket:didSendData:exception:)])
			return false;

		newData = [_delegate socket: object
				didSendData: _data
				  exception: exception];

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		return true;
# ifdef OF_HAVE_BLOCKS
	}
# endif
}

- (void)dealloc
{
# ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
# endif
	objc_release(_data);

	[super dealloc];
}
@end

# ifdef OF_HAVE_SCTP
@implementation OFRunLoopSCTPReceiveQueueItem
- (bool)handleObject: (id)object
{
	size_t length;
	OFSCTPMessageInfo info;
	id exception = nil;

	@try {
		length = [object receiveIntoBuffer: _buffer
					    length: _length
					      info: &info];
	} @catch (id e) {
		length = 0;
		exception = e;
	}

#  ifdef OF_HAVE_BLOCKS
	if (_handler != NULL)
		return _handler(object, _buffer, length, info, exception);
	else {
#  endif
		if (![_delegate respondsToSelector: @selector(
		    socket:didReceiveIntoBuffer:length:info:exception:)])
			return false;

		return [_delegate socket: object
		    didReceiveIntoBuffer: _buffer
				  length: length
				    info: info
			       exception: exception];
#  ifdef OF_HAVE_BLOCKS
	}
#  endif
}

# ifdef OF_HAVE_BLOCKS
- (void)dealloc
{
	objc_release(_handler);

	[super dealloc];
}
# endif
@end

@implementation OFRunLoopSCTPSendQueueItem
- (bool)handleObject: (id)object
{
	id exception = nil;
	OFData *newData, *oldData;

	@try {
		[object sendBuffer: _data.items
			    length: _data.count * _data.itemSize
			      info: _info];
	} @catch (id e) {
		exception = e;
	}

#  ifdef OF_HAVE_BLOCKS
	if (_handler != NULL) {
		newData = _handler(object, _data, _info, exception);

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		return true;
	} else {
#  endif
		if (![_delegate respondsToSelector: @selector(
		    socket:didSendData:info:exception:)])
			return false;

		newData = [_delegate socket: object
				didSendData: _data
				       info: _info
				  exception: exception];

		if (newData == nil)
			return false;

		oldData = _data;
		_data = [newData copy];
		objc_release(oldData);

		return true;
#  ifdef OF_HAVE_BLOCKS
	}
#  endif
}

- (void)dealloc
{
# ifdef OF_HAVE_BLOCKS
	objc_release(_handler);
# endif
	objc_release(_data);
	objc_release(_info);

	[super dealloc];
}
@end
# endif
#endif

@implementation OFRunLoop
@synthesize currentMode = _currentMode;

+ (OFRunLoop *)mainRunLoop
{
	return mainRunLoop;
}

+ (OFRunLoop *)currentRunLoop
{
#ifdef OF_HAVE_THREADS
	return [OFThread currentThread].runLoop;
#else
	return [self mainRunLoop];
#endif
}

+ (void)of_setMainRunLoop: (OFRunLoop *)runLoop
{
	mainRunLoop = objc_retain(runLoop);
}

static OFRunLoopState *
stateForMode(OFRunLoop *self, OFRunLoopMode mode, bool create,
    bool createObserver)
{
	OFRunLoopState *state;

#ifdef OF_HAVE_THREADS
	[self->_statesMutex lock];
	@try {
#endif
		state = [self->_states objectForKey: mode];

		if (create && state == nil) {
			state = [[OFRunLoopState alloc] initWithMode: mode];
			@try {
				[self->_states setObject: state forKey: mode];
			} @finally {
				objc_release(state);
			}
		}

#ifdef OF_HAVE_SOCKETS
		if (createObserver && state->_kernelEventObserver == nil) {
			state->_kernelEventObserver =
			    [[OFKernelEventObserver alloc]
			    initWithRunLoopMode: mode];
			state->_kernelEventObserver.delegate = state;
		}
#endif
#ifdef OF_HAVE_THREADS
	} @finally {
		[self->_statesMutex unlock];
	}
#endif

	return state;
}

#ifdef OF_HAVE_SOCKETS
# define NEW_READ(type, object, mode)					 \
	void *pool = objc_autoreleasePoolPush();			 \
	OFRunLoop *runLoop = [self currentRunLoop];			 \
	OFRunLoopState *state = stateForMode(runLoop, mode, true, true); \
	OFList *queue = [state->_readQueues objectForKey: object];	 \
	type *queueItem;						 \
									 \
	if (queue == nil) {						 \
		queue = [OFList list];					 \
		[state->_readQueues setObject: queue forKey: object];	 \
	}								 \
									 \
	if (queue.count == 0)						 \
		[state->_kernelEventObserver				 \
		    addObjectForReading: object];			 \
									 \
	queueItem = objc_autorelease([[type alloc] init]);
# define NEW_WRITE(type, object, mode)					 \
	void *pool = objc_autoreleasePoolPush();			 \
	OFRunLoop *runLoop = [self currentRunLoop];			 \
	OFRunLoopState *state = stateForMode(runLoop, mode, true, true); \
	OFList *queue = [state->_writeQueues objectForKey: object];	 \
	type *queueItem;						 \
									 \
	if (queue == nil) {						 \
		queue = [OFList list];					 \
		[state->_writeQueues setObject: queue forKey: object];	 \
	}								 \
									 \
	if (queue.count == 0)						 \
		[state->_kernelEventObserver				 \
		    addObjectForWriting: object];			 \
									 \
	queueItem = objc_autorelease([[type alloc] init]);
#define QUEUE_ITEM							 \
	[queue appendObject: queueItem];				 \
									 \
	objc_autoreleasePoolPop(pool);

+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
			  length: (size_t)length
			    mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			 handler: (OFStreamReadHandler)handler
# endif
			delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopReadQueueItem, stream, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_length = length;

	QUEUE_ITEM
}

+ (void)of_addAsyncReadForStream: (OFStream <OFReadyForReadingObserving> *)
				      stream
			  buffer: (void *)buffer
		     exactLength: (size_t)exactLength
			    mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			 handler: (OFStreamReadHandler)handler
# endif
			delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopExactReadQueueItem, stream, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_exactLength = exactLength;

	QUEUE_ITEM
}

+ (void)of_addAsyncReadStringForStream: (OFStream <OFReadyForReadingObserving
					    > *)stream
			      encoding: (OFStringEncoding)encoding
				  mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			       handler: (OFStreamStringReadHandler)handler
# endif
			      delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopReadStringQueueItem, stream, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_encoding = encoding;

	QUEUE_ITEM
}

+ (void)of_addAsyncReadLineForStream: (OFStream <OFReadyForReadingObserving> *)
					  stream
			    encoding: (OFStringEncoding)encoding
				mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			     handler: (OFStreamStringReadHandler)handler
# endif
			    delegate: (id <OFStreamDelegate>)delegate
{
	NEW_READ(OFRunLoopReadLineQueueItem, stream, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_encoding = encoding;

	QUEUE_ITEM
}

+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			     data: (OFData *)data
			     mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			  handler: (OFStreamDataWrittenHandler)handler
# endif
			 delegate: (id <OFStreamDelegate>)delegate
{
	NEW_WRITE(OFRunLoopWriteDataQueueItem, stream, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_data = [data copy];

	QUEUE_ITEM
}

+ (void)of_addAsyncWriteForStream: (OFStream <OFReadyForWritingObserving> *)
				       stream
			   string: (OFString *)string
			 encoding: (OFStringEncoding)encoding
			     mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			  handler: (OFStreamStringWrittenHandler)handler
# endif
			 delegate: (id <OFStreamDelegate>)delegate
{
	NEW_WRITE(OFRunLoopWriteStringQueueItem, stream, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_string = [string copy];
	queueItem->_encoding = encoding;

	QUEUE_ITEM
}

# if !defined(OF_WII) && !defined(OF_NINTENDO_3DS)
+ (void)of_addAsyncConnectForSocket: (id)sock
			       mode: (OFRunLoopMode)mode
			   delegate: (id <OFRunLoopConnectDelegate>)delegate
{
	NEW_WRITE(OFRunLoopConnectQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);

	QUEUE_ITEM
}
# endif

+ (void)of_addAsyncAcceptForSocket: (id)sock
			      mode: (OFRunLoopMode)mode
			   handler: (id)handler
			  delegate: (id)delegate
{
	NEW_READ(OFRunLoopAcceptQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif

	QUEUE_ITEM
}

+ (void)of_addAsyncReceiveForDatagramSocket: (OFDatagramSocket *)sock
    buffer: (void *)buffer
    length: (size_t)length
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
   handler: (OFDatagramSocketPacketReceivedHandler)handler
# endif
  delegate: (id <OFDatagramSocketDelegate>)delegate
{
	NEW_READ(OFRunLoopDatagramReceiveQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_length = length;

	QUEUE_ITEM
}

+ (void)of_addAsyncSendForDatagramSocket: (OFDatagramSocket *)sock
      data: (OFData *)data
  receiver: (const OFSocketAddress *)receiver
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
   handler: (OFDatagramSocketDataSentHandler)handler
# endif
  delegate: (id <OFDatagramSocketDelegate>)delegate
{
	NEW_WRITE(OFRunLoopDatagramSendQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_data = [data copy];
	queueItem->_receiver = *receiver;

	QUEUE_ITEM
}

+ (void)of_addAsyncReceiveForSequencedPacketSocket: (OFSequencedPacketSocket *)
							sock
    buffer: (void *)buffer
    length: (size_t)length
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
   handler: (OFSequencedPacketSocketPacketReceivedHandler)handler
# endif
  delegate: (id <OFSequencedPacketSocketDelegate>)delegate
{
	NEW_READ(OFRunLoopPacketReceiveQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_buffer = buffer;
	queueItem->_length = length;

	QUEUE_ITEM
}

+ (void)of_addAsyncSendForSequencedPacketSocket: (OFSequencedPacketSocket *)sock
      data: (OFData *)data
      mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
   handler: (OFSequencedPacketSocketDataSentHandler)handler
# endif
  delegate: (id <OFSequencedPacketSocketDelegate>)delegate
{
	NEW_WRITE(OFRunLoopPacketSendQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_data = [data copy];

	QUEUE_ITEM
}

# ifdef OF_HAVE_SCTP
+ (void)
    of_addAsyncReceiveForSCTPSocket: (OFSCTPSocket *)sock
			     buffer: (void *)buffer
			     length: (size_t)length
			       mode: (OFRunLoopMode)mode
#  ifdef OF_HAVE_BLOCKS
			    handler: (OFSCTPSocketMessageReceivedHandler)handler
#  endif
			   delegate: (id <OFSCTPSocketDelegate>)delegate
{
	NEW_READ(OFRunLoopSCTPReceiveQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
#  ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
#  endif
	queueItem->_buffer = buffer;
	queueItem->_length = length;

	QUEUE_ITEM
}

+ (void)of_addAsyncSendForSCTPSocket: (OFSCTPSocket *)sock
				data: (OFData *)data
				info: (OFSCTPMessageInfo)info
				mode: (OFRunLoopMode)mode
# ifdef OF_HAVE_BLOCKS
			     handler: (OFSCTPSocketDataSentHandler)handler
# endif
			    delegate: (id <OFSCTPSocketDelegate>)delegate
{
	NEW_WRITE(OFRunLoopSCTPSendQueueItem, sock, mode)

	queueItem->_delegate = objc_retain(delegate);
# ifdef OF_HAVE_BLOCKS
	queueItem->_handler = [handler copy];
# endif
	queueItem->_data = [data copy];
	queueItem->_info = [info copy];

	QUEUE_ITEM
}
# endif
# undef NEW_READ
# undef NEW_WRITE
# undef QUEUE_ITEM

+ (void)of_cancelAsyncRequestsForObject: (id)object mode: (OFRunLoopMode)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoop *runLoop = [self currentRunLoop];
	OFRunLoopState *state = stateForMode(runLoop, mode, false, false);
	OFList *queue;

	if (state == nil)
		return;

	if ((queue = [state->_writeQueues objectForKey: object]) != nil) {
		OFAssert(queue.count > 0);

		/*
		 * Clear the queue now, in case this has been called from a
		 * handler, as otherwise, we'd do the cleanups below twice.
		 */
		[queue removeAllObjects];

		[state->_kernelEventObserver removeObjectForWriting: object];
		[state->_writeQueues removeObjectForKey: object];
	}

	if ((queue = [state->_readQueues objectForKey: object]) != nil) {
		OFAssert(queue.count > 0);

		/*
		 * Clear the queue now, in case this has been called from a
		 * handler, as otherwise, we'd do the cleanups below twice.
		 */
		[queue removeAllObjects];

		[state->_kernelEventObserver removeObjectForReading: object];
		[state->_readQueues removeObjectForKey: object];
	}

	objc_autoreleasePoolPop(pool);
}
#endif

- (instancetype)init
{
	self = [super init];

	@try {
		OFRunLoopState *state;

		_states = [[OFMutableDictionary alloc] init];

		state = [[OFRunLoopState alloc]
		    initWithMode: OFDefaultRunLoopMode];
		@try {
			[_states setObject: state forKey: OFDefaultRunLoopMode];
		} @finally {
			objc_release(state);
		}

#ifdef OF_HAVE_THREADS
		_statesMutex = [[OFMutex alloc] init];
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_states);
#ifdef OF_HAVE_THREADS
	objc_release(_statesMutex);
#endif

	[super dealloc];
}

- (void)addTimer: (OFTimer *)timer
{
	[self addTimer: timer forMode: OFDefaultRunLoopMode];
}

- (void)addTimer: (OFTimer *)timer forMode: (OFRunLoopMode)mode
{
	OFRunLoopState *state = stateForMode(self, mode, true, false);

#ifdef OF_HAVE_THREADS
	[state->_timersQueueMutex lock];
	@try {
#endif
		[state->_timersQueue insertObject: timer];
#ifdef OF_HAVE_THREADS
	} @finally {
		[state->_timersQueueMutex unlock];
	}
#endif

	[timer of_setInRunLoop: self mode: mode];

#ifdef OF_HAVE_SOCKETS
	[state->_kernelEventObserver cancel];
#endif
#ifdef OF_HAVE_THREADS
	[state->_condition signal];
#endif
}

- (void)of_removeTimer: (OFTimer *)timer forMode: (OFRunLoopMode)mode
{
	OFRunLoopState *state = stateForMode(self, mode, false, false);

	/* {} required to avoid -Wmisleading-indentation false positive. */
	if (state == nil) {
		return;
	}

#ifdef OF_HAVE_THREADS
	[state->_timersQueueMutex lock];
	@try {
#endif
		for (OFListItem iter = state->_timersQueue.firstListItem;
		    iter != NULL; iter = OFListItemNext(iter)) {
			if ([OFListItemObject(iter) isEqual: timer]) {
				[state->_timersQueue removeListItem: iter];
				break;
			}
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		[state->_timersQueueMutex unlock];
	}
#endif
}

#ifdef OF_AMIGAOS
- (void)addExecSignal: (ULONG)signal target: (id)target selector: (SEL)selector
{
	[self addExecSignal: signal
		    forMode: OFDefaultRunLoopMode
		     target: target
		   selector: selector];
}

- (void)addExecSignal: (ULONG)signal
	      forMode: (OFRunLoopMode)mode
	       target: (id)target
	     selector: (SEL)selector
{
	OFRunLoopState *state = stateForMode(self, mode, true, false);

# ifdef OF_HAVE_THREADS
	[state->_execSignalsMutex lock];
	@try {
# endif
		[state->_execSignals addItem: &signal];
		[state->_execSignalsTargets addObject: target];
		[state->_execSignalsSelectors addItem: &selector];

# ifdef OF_HAVE_SOCKETS
		state->_kernelEventObserver.execSignalMask |= (1ul << signal);
# endif
# ifdef OF_HAVE_THREADS
		state->_execSignalMask |= (1ul << signal);
# endif
# ifdef OF_HAVE_THREADS
	} @finally {
		[state->_execSignalsMutex unlock];
	}
# endif

# ifdef OF_HAVE_SOCKETS
	[state->_kernelEventObserver cancel];
# endif
# ifdef OF_HAVE_THREADS
	[state->_condition signal];
# endif
}

- (void)removeExecSignal: (ULONG)signal
		  target: (id)target
		selector: (SEL)selector
{
	[self removeExecSignal: signal
		       forMode: OFDefaultRunLoopMode
			target: target
		      selector: selector];
}

- (void)removeExecSignal: (ULONG)signal
		 forMode: (OFRunLoopMode)mode
		  target: (id)target
		selector: (SEL)selector
{
	OFRunLoopState *state = stateForMode(self, mode, false, false);

	if (state == nil)
		return;

# ifdef OF_HAVE_THREADS
	[state->_execSignalsMutex lock];
	@try {
# endif
		const ULONG *signals = state->_execSignals.items;
		const id *targets = state->_execSignalsTargets.objects;
		const SEL *selectors = state->_execSignalsSelectors.items;
		size_t count = state->_execSignals.count;
		bool found = false;
		ULONG newMask = 0;

		for (size_t i = 0; i < count; i++) {
			if (!found && signals[i] == signal &&
			    targets[i] == target && selectors[i] == selector) {
				[state->_execSignals removeItemAtIndex: i];
				[state->_execSignalsTargets
				    removeObjectAtIndex: i];
				[state->_execSignalsSelectors
				    removeItemAtIndex: i];

				found = true;
			} else
				newMask |= (1ul << signals[i]);
		}

# ifdef OF_HAVE_SOCKETS
		state->_kernelEventObserver.execSignalMask = newMask;
# endif
# ifdef OF_HAVE_THREADS
		state->_execSignalMask = newMask;
# endif
# ifdef OF_HAVE_THREADS
	} @finally {
		[state->_execSignalsMutex unlock];
	}
# endif

# ifdef OF_HAVE_SOCKETS
	[state->_kernelEventObserver cancel];
# endif
# ifdef OF_HAVE_THREADS
	[state->_condition signal];
# endif
}
#endif

- (void)run
{
	[self runUntilDate: nil];
}

- (void)runUntilDate: (OFDate *)deadline
{
	_stop = false;

	while (!_stop &&
	    (deadline == nil || deadline.timeIntervalSinceNow >= 0))
		[self runMode: OFDefaultRunLoopMode beforeDate: deadline];
}

- (void)runMode: (OFRunLoopMode)mode beforeDate: (OFDate *)deadline
{
	void *pool = objc_autoreleasePoolPush();
	OFRunLoopMode previousMode = _currentMode;
	OFRunLoopState *state = stateForMode(self, mode, false, false);

	if (state == nil) {
		objc_autoreleasePoolPop(pool);
		return;
	}

	_currentMode = mode;
	@try {
		OFDate *nextTimer;
#if defined(OF_AMIGAOS) && defined(OF_HAVE_THREADS)
		ULONG signalMask;
#endif

		for (;;) {
			OFTimer *timer;

#ifdef OF_HAVE_THREADS
			[state->_timersQueueMutex lock];
			@try {
#endif
				OFListItem listItem =
				    state->_timersQueue.firstListItem;

				if (listItem != NULL &&
				    [OFListItemObject(listItem) fireDate]
				    .timeIntervalSinceNow <= 0) {
					timer = objc_retainAutorelease(
					    OFListItemObject(listItem));

					[state->_timersQueue
					    removeListItem: listItem];

					[timer of_setInRunLoop: nil mode: nil];
				} else
					break;
#ifdef OF_HAVE_THREADS
			} @finally {
				[state->_timersQueueMutex unlock];
			}
#endif

			if (timer.valid) {
				[timer of_reschedule];
				[timer fire];
				objc_autoreleasePoolPop(pool);
				return;
			}
		}

#ifdef OF_HAVE_THREADS
		[state->_timersQueueMutex lock];
		@try {
#endif
			nextTimer = [[state->_timersQueue
			    firstObject] fireDate];
#ifdef OF_HAVE_THREADS
		} @finally {
			[state->_timersQueueMutex unlock];
		}
#endif

		/* Watch for I/O events until the next timer is due */
		if (nextTimer != nil || deadline != nil) {
			OFTimeInterval timeout;

			if (nextTimer != nil && deadline == nil)
				timeout = nextTimer.timeIntervalSinceNow;
			else if (nextTimer == nil && deadline != nil)
				timeout = deadline.timeIntervalSinceNow;
			else
				timeout = [nextTimer earlierDate: deadline]
				    .timeIntervalSinceNow;

			if (timeout < 0) {
				timeout = 0;
			}

#ifdef OF_HAVE_SOCKETS
			if (state->_kernelEventObserver != nil) {
				[state->_kernelEventObserver
				    observeForTimeInterval: timeout];
			} else {
#endif
#ifdef OF_HAVE_THREADS
				[state->_condition lock];
# ifdef OF_AMIGAOS
				signalMask = state->_execSignalMask;
				[state->_condition
				    waitForTimeInterval: timeout
					   orExecSignal: &signalMask];
				if (signalMask != 0)
					[state
					    execSignalWasReceived: signalMask];
# else
				[state->_condition
				    waitForTimeInterval: timeout];
# endif
				[state->_condition unlock];
#else
				[OFThread sleepForTimeInterval: timeout];
#endif
#ifdef OF_HAVE_SOCKETS
			}
#endif
		} else {
			/*
			 * No more timers and no deadline: Just watch for I/O
			 * until we get an event. If a timer is added by
			 * another thread, it cancels the observe.
			 */
#ifdef OF_HAVE_SOCKETS
			if (state->_kernelEventObserver != nil)
				[state->_kernelEventObserver observe];
			else {
#endif
#ifdef OF_HAVE_THREADS
				[state->_condition lock];
# ifdef OF_AMIGAOS
				signalMask = state->_execSignalMask;
				[state->_condition
				    waitForConditionOrExecSignal: &signalMask];
				if (signalMask != 0)
					[state
					    execSignalWasReceived: signalMask];
# else
				[state->_condition wait];
# endif
				[state->_condition unlock];
#else
				[OFThread sleepForTimeInterval: 86400];
#endif
#ifdef OF_HAVE_SOCKETS
			}
#endif
		}

		objc_autoreleasePoolPop(pool);
	} @finally {
		_currentMode = previousMode;
	}
}

- (void)stop
{
	OFRunLoopState *state = stateForMode(self, OFDefaultRunLoopMode,
	    false, false);

	_stop = true;

	if (state == nil)
		return;

#ifdef OF_HAVE_SOCKETS
	[state->_kernelEventObserver cancel];
#endif
#ifdef OF_HAVE_THREADS
	[state->_condition signal];
#endif
}
@end
