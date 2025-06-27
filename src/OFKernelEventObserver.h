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

#import "OFObject.h"
#ifdef OF_HAVE_SOCKETS
# import "OFSocket.h"
#endif
#import "OFRunLoop.h"

#ifdef OF_AMIGAOS
# include <exec/types.h>
# include <exec/tasks.h>
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFMutableArray OF_GENERIC(ObjectType);
@class OFDate;
@class OFMutableData;

/**
 * @protocol OFKernelEventObserverDelegate OFKernelEventObserver.h ObjFW/ObjFW.h
 *
 * @brief A protocol that needs to be implemented by delegates for
 *	  OFKernelEventObserver.
 */
@protocol OFKernelEventObserverDelegate <OFObject>
@optional
/**
 * @brief This callback is called when an object did get ready for reading.
 *
 * @note If the object is a subclass of @ref OFStream and
 *	 @ref OFStream#tryReadLine or @ref OFStream#tryReadUntilDelimiter:
 *	 has been called on the stream, this callback will not be called again
 *	 until new data has been received, even though there is still data in
 *	 the cache. The reason for this is to prevent spinning in a loop when
 *	 there is an incomplete string in the cache. Once the string has been
 *	 completed, the callback will be called again as long there is data in
 *	 the cache.
 *
 * @param object The object which did become ready for reading
 */
- (void)objectIsReadyForReading: (id)object;

/**
 * @brief This callback is called when an object did get ready for writing.
 *
 * @param object The object which did become ready for writing
 */
- (void)objectIsReadyForWriting: (id)object;

#if defined(OF_AMIGAOS) || defined(DOXYGEN)
/**
 * @brief This callback is called when an Exec Signal was received.
 *
 * @note This is only available on AmigaOS!
 */
- (void)execSignalWasReceived: (ULONG)signalMask;
#endif
@end

/**
 * @protocol OFReadyForReadingObserving OFKernelEventObserver.h ObjFW/ObjFW.h
 *
 * @brief This protocol is implemented by classes which can be observed for
 *	  readiness for reading by OFKernelEventObserver.
 */
@protocol OFReadyForReadingObserving <OFObject>
/**
 * @brief The file descriptor for reading that should be checked by the
 *	  OFKernelEventObserver.
 */
@property (readonly, nonatomic) int fileDescriptorForReading;
@end

/**
 * @protocol OFReadyForWritingObserving OFKernelEventObserver.h ObjFW/ObjFW.h
 *
 * @brief This protocol is implemented by classes which can be observed for
 *	  readiness for writing by OFKernelEventObserver.
 */
@protocol OFReadyForWritingObserving <OFObject>
/**
 * @brief The file descriptor for writing that should be checked by the
 *	  OFKernelEventObserver.
 */
@property (readonly, nonatomic) int fileDescriptorForWriting;
@end

#ifdef OF_HAVE_SOCKETS
/**
 * @class OFKernelEventObserver OFKernelEventObserver.h ObjFW/ObjFW.h
 *
 * @brief A class that can observe multiple kernel events (e.g. streams being
 *	  ready to read) at once.
 *
 * @note Currently, Win32 can only observe TCP and UDP sockets!
 */
@interface OFKernelEventObserver: OFObject
{
	OFMutableArray OF_GENERIC(id <OFReadyForReadingObserving>)
	    *_readObjects;
	OFMutableArray OF_GENERIC(id <OFReadyForWritingObserving>)
	    *_writeObjects;
	id <OFKernelEventObserverDelegate> _Nullable _delegate;
# if defined(OF_AMIGAOS)
	struct Task *_waitingTask;
	ULONG _cancelSignal;
# elif defined(OF_HAVE_PIPE)
	int _cancelFD[2];
# else
	OFSocketHandle _cancelFD[2];
	struct sockaddr_in _cancelAddr;
# endif
# ifdef OF_AMIGAOS
	ULONG _execSignalMask;
# endif
	OF_RESERVE_IVARS(OFKernelEventObserver, 4)
}

/**
 * @brief The delegate for the OFKernelEventObserver.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFKernelEventObserverDelegate> delegate;

# if defined(OF_AMIGAOS) || defined(DOXYGEN)
/**
 * @brief A mask of Exec Signals to wait for.
 *
 * @note This is only available on AmigaOS!
 */
@property (nonatomic) ULONG execSignalMask;
# endif

# ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) bool handlesForeignEvents;
# endif

/**
 * @brief Creates a new OFKernelEventObserver.
 *
 * @return A new, autoreleased OFKernelEventObserver
 */
+ (instancetype)observer;

/**
 * @brief Whether the kernel event observer handles foreign events.
 *
 * This is the case if the kernel event observer also handles events from a
 * foreign run loop and used by @ref OFRunLoop to determine whether the kernel
 * event observer should also be called even when there are currently no
 * sockets being observed.
 */
+ (bool)handlesForeignEvents;

/**
 * @brief Initializes the @ref OFKernelEventObserver.
 *
 * @return An initialized @ref OFKernelEventObserver
 */
- (instancetype)init;

/**
 * @brief Initializes the @ref OFKernelEventObserver.
 *
 * @note Subclasses must override this method, but it must not be called!
 *	 Instead, @ref init should be called.
 *
 * @param runLoopMode This is used by @ref OFRunLoop if the kernel event
 *		      observer being created is for a run loop mode. This can
 *		      be used by subclasses of @ref OFKernelEventObserver to
 *		      integrate @ref OFRunLoop with a foreign run loop. If the
 *		      @ref OFKernelEventObserver is not being created by
 *		      @ref OFRunLoop, it is `nil`.
 * @return An initialized @ref OFKernelEventObserver
 */
- (instancetype)initWithRunLoopMode: (nullable OFRunLoopMode)runLoopMode;

/**
 * @brief Adds an object to observe for reading.
 *
 * This is also used to observe a listening socket for incoming connections,
 * which then triggers a read event for the observed object.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent blocking even though the newly added object is ready.
 *
 * @param object The object to observe for reading
 * @throw OFObserveKernelEventsFailedException Adding the object for observing
 *					       failed
 */
- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object;

/**
 * @brief Adds an object to observe for writing.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent blocking even though the newly added object is ready.
 *
 * @param object The object to observe for writing
 * @throw OFObserveKernelEventsFailedException Adding the object for observing
 *					       failed
 */
- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object;

/**
 * @brief Removes an object to observe for reading.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent the removed object from still being observed.
 *
 * @param object The object to remove from observing for reading
 * @throw OFObserveKernelEventsFailedException Removing the object for observing
 *					       failed
 */
- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object;

/**
 * @brief Removes an object to observe for writing.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent the removed object from still being observed.
 *
 * @param object The object to remove from observing for writing
 * @throw OFObserveKernelEventsFailedException Removing the object for observing
 *					       failed
 */
- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object;

/**
 * @brief Observes all objects and blocks until an event happens on an object.
 *
 * @throw OFObserveKernelEventsFailedException Observing for kernel events
 *					       failed
 */
- (void)observe;

/**
 * @brief Observes all objects until an event happens on an object or the
 *	  timeout is reached.
 *
 * @param timeInterval The time to wait for an event, in seconds
 * @throw OFObserveKernelEventsFailedException Observing for kernel events
 *					       failed
 */
- (void)observeForTimeInterval: (OFTimeInterval)timeInterval;

/**
 * @brief Observes all objects until an event happens on an object or the
 *	  specified date is reached.
 *
 * @param date The until which to observe
 * @throw OFObserveKernelEventsFailedException Observing for kernel events
 *					       failed
 */
- (void)observeUntilDate: (OFDate *)date;

/**
 * @brief Cancels the currently blocking observe call.
 *
 * This is the only method that can and should be called from another thread
 * than the one using the observer.
 */
- (void)cancel;

/**
 * @brief This method should be called by subclasses in @ref observeUntilDate:
 *	  as the first thing to handle all sockets that currently have data in
 *	  the read buffer and should return early if @ref processReadBuffers
 *	  returned true.
 *
 * @note You should not call this manually!
 *
 * @return Whether at least one read buffer was handled
 */
- (bool)processReadBuffers;
@end
#endif

OF_ASSUME_NONNULL_END
