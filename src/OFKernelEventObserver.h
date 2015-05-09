/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFObject.h"

#import "socket.h"

@class OFMutableArray;
@class OFMutableDictionary;
@class OFDataArray;
#ifdef OF_HAVE_THREADS
@class OFMutex;
#endif
@class OFDate;

/*!
 * @protocol OFKernelEventObserverDelegate
 *	     OFKernelEventObserver.h ObjFW/OFKernelEventObserver.h
 *
 * @brief A protocol that needs to be implemented by delegates for
 *	  OFKernelEventObserver.
 */
@protocol OFKernelEventObserverDelegate <OFObject>
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/*!
 * @brief This callback is called when an object did get ready for reading.
 *
 * @note If the object is a subclass of @ref OFStream and
 *	 @ref OFStream::tryReadLine or @ref OFStream::tryReadTillDelimiter: has
 *	 been called on the stream, this callback will not be called again
 *	 until new data has been received, even though there is still data in
 *	 the cache. The reason for this is to prevent spinning in a loop when
 *	 there is an incomplete string in the cache. Once the string has been
 *	 completed, the callback will be called again as long there is data in
 *	 the cache.
 *
 * @param object The object which did become ready for reading
 */
- (void)objectIsReadyForReading: (id)object;

/*!
 * @brief This callback is called when an object did get ready for writing.
 *
 * @param object The object which did become ready for writing
 */
- (void)objectIsReadyForWriting: (id)object;
@end

/*!
 * @protocol OFReadyForReadingObserving
 *	     OFKernelEventObserver.h ObjFW/OFKernelEventObserver.h
 *
 * @brief This protocol is implemented by classes which can be observed for
 *	  readiness for reading by OFKernelEventObserver.
 */
@protocol OFReadyForReadingObserving <OFObject>
/*!
 * @brief Returns the file descriptor for reading that should be checked by the
 *	  OFKernelEventObserver.
 *
 * @return The file descriptor for reading that should be checked by the
 *	   OFKernelEventObserver
 */
- (int)fileDescriptorForReading;
@end

/*!
 * @protocol OFReadyForWritingObserving
 *	     OFKernelEventObserver.h ObjFW/OFKernelEventObserver.h
 *
 * @brief This protocol is implemented by classes which can be observed for
 *	  readiness for writing by OFKernelEventObserver.
 */
@protocol OFReadyForWritingObserving <OFObject>
/*!
 * @brief Returns the file descriptor for writing that should be checked by the
 *	  OFKernelEventObserver.
 *
 * @return The file descriptor for writing that should be checked by the
 *	   OFKernelEventObserver
 */
- (int)fileDescriptorForWriting;
@end

/*!
 * @class OFKernelEventObserver
 *	  OFKernelEventObserver.h ObjFW/OFKernelEventObserver.h
 *
 * @brief A class that can observe multiple kernel events (e.g. streams being
 *	  ready to read) at once.
 *
 * @note Currently, Win32 can only observe TCP and UDP sockets!
 */
@interface OFKernelEventObserver: OFObject
{
	OFMutableArray *_readObjects;
	OFMutableArray *_writeObjects;
	OFMutableArray *_queue;
	OFDataArray *_queueActions;
	id <OFKernelEventObserverDelegate> _delegate;
#ifdef OF_HAVE_PIPE
	int _cancelFD[2];
#else
	of_socket_t _cancelFD[2];
	struct sockaddr_in _cancelAddr;
#endif
#ifdef OF_HAVE_THREADS
	OFMutex *_mutex;
#endif
}

#ifdef OF_HAVE_PROPERTIES
@property (assign) id <OFKernelEventObserverDelegate> delegate;
#endif

/*!
 * @brief Creates a new OFKernelEventObserver.
 *
 * @return A new, autoreleased OFKernelEventObserver
 */
+ (instancetype)observer;

/*!
 * @brief Returns the delegate for the OFKernelEventObserver.
 *
 * @return The delegate for the OFKernelEventObserver
 */
- (id <OFKernelEventObserverDelegate>)delegate;

/*!
 * @brief Sets the delegate for the OFKernelEventObserver.
 *
 * @param delegate The delegate for the OFKernelEventObserver
 */
- (void)setDelegate: (id <OFKernelEventObserverDelegate>)delegate;

/*!
 * @brief Adds an object to observe for reading.
 *
 * This is also used to observe a listening socket for incoming connections,
 * which then triggers a read event for the observed object.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent blocking even though the newly added object is ready.
 *
 * @param object The object to observe for reading
 */
- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object;

/*!
 * @brief Adds an object to observe for writing.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent blocking even though the newly added object is ready.
 *
 * @param object The object to observe for writing
 */
- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object;

/*!
 * @brief Removes an object to observe for reading.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent the removed object from still being observed.
 *
 * @param object The object to remove from observing for reading
 */
- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object;

/*!
 * @brief Removes an object to observe for writing.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent the removed object from still being observed.
 *
 * @param object The object to remove from observing for writing
 */
- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object;

/*!
 * @brief Observes all objects and blocks until an event happens on an object.
 */
- (void)observe;

/*!
 * @brief Observes all objects until an event happens on an object or the
 *	  timeout is reached.
 *
 * @param timeInterval The time to wait for an event, in seconds
 */
- (void)observeForTimeInterval: (of_time_interval_t)timeInterval;

/*!
 * @brief Observes all objects until an event happens on an object or the
 *	  specified date is reached.
 *
 * @param date The until which to observe
 */
- (void)observeUntilDate: (OFDate*)date;

/*!
 * @brief Cancels the currently blocking observe call.
 *
 * This is automatically done when a new object is added or removed by another
 * thread, but in some circumstances, it might be desirable for a thread to
 * manually stop the observe running in another thread.
 */
- (void)cancel;
@end

@interface OFObject (OFKernelEventObserverDelegate)
    <OFKernelEventObserverDelegate>
@end
