/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFURL.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFMutableURL OFMutableURL.h ObjFW/OFMutableURL.h
 *
 * @brief A class for parsing URLs and accessing parts of it.
 */
@interface OFMutableURL: OFURL
/*!
 * The scheme part of the URL.
 */
@property (readwrite, nonatomic, copy) OFString *scheme;

/*!
 * The host part of the URL.
 */
@property (readwrite, nonatomic, copy) OFString *host;

/*!
 * The port part of the URL.
 */
@property (readwrite, nonatomic) uint16_t port;

/*!
 * The user part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, copy) OFString *user;

/*!
 * The password part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, copy) OFString *password;

/*!
 * The path part of the URL.
 */
@property (readwrite, nonatomic, copy) OFString *path;

/*!
 * The parameters part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, copy)
    OFString *parameters;

/*!
 * The query part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, copy) OFString *query;

/*!
 * The fragment part of the URL.
 */
@property OF_NULLABLE_PROPERTY (readwrite, nonatomic, copy) OFString *fragment;

/*!
 * @brief Creates a new mutable URL.
 *
 * @return A new, autoreleased OFMutableURL
 */
+ (instancetype)URL;

/*!
 * @brief Initializes an already allocated OFMutableURL.
 *
 * @return An initialized OFMutableURL
 */
- init;

/*!
 * @brief Converts the mutable URL to an immutable URL.
 */
- (void)makeImmutable;
@end

OF_ASSUME_NONNULL_END
