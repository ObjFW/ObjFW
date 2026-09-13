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

#import "OFObject.h"
#import "OFNotification.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableDictionary OF_GENERIC(KeyType, ObjectType);

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when a notification has been posted.
 *
 * @param notification The notification that has been posted
 */
typedef void (^OFNotificationCenterBlock)(OFNotification *notification);
#endif

/**
 * @class OFNotificationCenter OFNotificationCenter.h ObjFW/ObjFW.h
 *
 * @brief A class to send and register for notifications.
 */
#ifndef OF_NOTIFICATION_CENTER_M
OF_SUBCLASSING_RESTRICTED
#endif
@interface OFNotificationCenter: OFObject
{
	OFMutableDictionary *_handles;
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic) OFNotificationCenter *defaultCenter;
#endif

/**
 * @brief Returns the default notification center.
 */
+ (OFNotificationCenter *)defaultCenter;

/**
 * @brief Adds an observer for the specified notification and object.
 *
 * @param observer The object that should receive notifications
 * @param selector The selector to call on the observer on notifications. The
 *		   method must take exactly one object of type
 *		   @ref OFNotification.
 * @param name The name of the notification to observe
 * @param object The object that should be sending the notification, or `nil`
 *		 if the object should be ignored to determine what
 *		 notifications to deliver
 */
- (void)addObserver: (id)observer
	   selector: (SEL)selector
	       name: (OFNotificationName)name
	     object: (nullable id)object;

/**
 * @brief Removes an observer. All parameters must match those used with
 *	  @ref addObserver:selector:name:object:.
 *
 * @param observer The observer that was specified when adding the observer
 * @param selector The selector that was specified when adding the observer
 * @param name The name that was specified when adding the observer
 * @param object The object that was specified when adding the observer
 */
- (void)removeObserver: (id)observer
	      selector: (SEL)selector
		  name: (OFNotificationName)name
		object: (nullable id)object;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Adds an observer for the specified notification and object.
 *
 * To remove the observer again, use @ref removeObserver:.
 *
 * @param name The name of the notification to observe
 * @param object The object that should be sending the notification, or `nil`
 *		 if the object should be ignored to determine what
 *		 notifications to deliver
 * @param block The block to handle notifications
 * @return An opaque object to remove the observer again
 */
- (id)addObserverForName: (OFNotificationName)name
		  object: (nullable id)object
	      usingBlock: (OFNotificationCenterBlock)block;

/**
 * @brief Removes an observer. The specified observer must be one returned by
 *	  @ref addObserverForName:object:usingBlock:.
 *
 * @param observer The object that was returned when adding the observer
 */
- (void)removeObserver: (id)observer;
#endif

/**
 * @brief Posts the specified notification.
 *
 * @param notification The notification to post
 */
- (void)postNotification: (OFNotification *)notification;

/**
 * @brief Posts a notification with the specified name and object.
 *
 * @param name The name for the notification
 * @param object The object for the notification
 */
- (void)postNotificationName: (OFNotificationName)name
		      object: (nullable id)object;

/**
 * @brief Posts a notification with the specified name, object and additional
 *	  information.
 *
 * @param name The name for the notification
 * @param object The object for the notification
 * @param userInfo Additional information for the notification
 */
- (void)postNotificationName: (OFNotificationName)name
		      object: (nullable id)object
		    userInfo: (nullable OFDictionary *)userInfo;
@end

OF_ASSUME_NONNULL_END
