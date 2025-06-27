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

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFConstantString;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/**
 * @brief A name for a notification.
 */
typedef OFConstantString *OFNotificationName;

/**
 * @class OFNotification OFNotification.h ObjFW/ObjFW.h
 *
 * @brief A class to represent a notification for or from
 *	  @ref OFNotificationCenter.
 */
@interface OFNotification: OFObject <OFCopying>
{
	OFNotificationName _name;
	id _Nullable _object;
	OFDictionary *_Nullable _userInfo;
	OF_RESERVE_IVARS(OFNotification, 4)
}

/**
 * @brief The name of the notification.
 */
@property (readonly, nonatomic) OFNotificationName name;

/**
 * @brief The object of the notification. This is commonly the sender of the
 *	  notification.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id object;

/**
 * @brief Additional information about the notification.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFDictionary *userInfo;

/**
 * @brief Creates a new notification with the specified name and object.
 *
 * @param name The name for the notification
 * @param object The object for the notification. This is commonly the sender
 *		 of the notification.
 * @return A new, autoreleased OFNotification
 */
+ (instancetype)notificationWithName: (OFNotificationName)name
			      object: (nullable id)object;

/**
 * @brief Creates a new notification with the specified name, object and
 *	  additional information.
 *
 * @param name The name for the notification
 * @param object The object for the notification. This is commonly the sender
 *		 of the notification.
 * @param userInfo Additional information for the notification
 * @return A new, autoreleased OFNotification
 */
+ (instancetype)notificationWithName: (OFNotificationName)name
			      object: (nullable id)object
			    userInfo: (nullable OFDictionary *)userInfo;

/**
 * @brief Initializes an already allocated notification with the specified
 *	  name and object.
 *
 * @param name The name for the notification
 * @param object The object for the notification. This is commonly the sender
 *		 of the notification.
 * @return An initialized OFNotification
 */
- (instancetype)initWithName: (OFNotificationName)name
		      object: (nullable id)object;

/**
 * @brief Initializes an already allocated notification with the specified
 *	  name, object and additional information.
 *
 * @param name The name for the notification
 * @param object The object for the notification. This is commonly the sender
 *		 of the notification.
 * @param userInfo Additional information for the notification
 * @return An initialized OFNotification
 */
- (instancetype)initWithName: (OFNotificationName)name
		      object: (nullable id)object
		    userInfo: (nullable OFDictionary *)userInfo
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
