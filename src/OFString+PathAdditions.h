/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_PathAdditions_reference;
#ifdef __cplusplus
}
#endif

@interface OFString (PathAdditions)
/*!
 * @brief Whether the path is an absolute path.
 */
@property (readonly, nonatomic, getter=isAbsolutePath) bool absolutePath;

/*!
 * @brief The components of the string when interpreted as a path.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *pathComponents;

/*!
 * @brief The last path component of the string when interpreted as a path.
 */
@property (readonly, nonatomic) OFString *lastPathComponent;

/*!
 * @brief The file extension of string when interpreted as a path.
 */
@property (readonly, nonatomic) OFString *pathExtension;

/*!
 * @brief The directory name of the string when interpreted as a path.
 */
@property (readonly, nonatomic) OFString *stringByDeletingLastPathComponent;

/*!
 * @brief The string with the file extension of the path removed.
 */
@property (readonly, nonatomic) OFString *stringByDeletingPathExtension;

/*!
 * @brief The string interpreted as a path with relative sub paths resolved.
 */
@property (readonly, nonatomic) OFString *stringByStandardizingPath;

/*!
 * @brief Creates a path from the specified path components.
 *
 * @param components An array of components for the path
 * @return A new autoreleased OFString
 */
+ (OFString *)pathWithComponents: (OFArray OF_GENERIC(OFString *) *)components;

/*!
 * @brief Creates a new string by appending a path component.
 *
 * @param component The path component to append
 * @return A new, autoreleased OFString with the path component appended
 */
- (OFString *)stringByAppendingPathComponent: (OFString *)component;
@end

OF_ASSUME_NONNULL_END
