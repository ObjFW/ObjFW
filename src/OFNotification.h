/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFConstantString;
@class OFDictionary OF_GENERIC(KeyType, ObjectType);

/**
 * @brief A name for a notification.
 */
typedef OFConstantString *OFNotificationName;

/**
 * @class OFNotification OFNotification.h ObjFW/OFNotification.h
 *
 * @brief A class to represent a notification for or from
 *	  @ref OFNotificationCenter.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFNotification: OFObject <OFCopying>
{
	OFNotificationName _name;
	id _Nullable _object;
	OFDictionary *_Nullable _userInfo;
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
