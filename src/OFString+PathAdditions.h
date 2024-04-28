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
/**
 * @brief Whether the path is an absolute path.
 */
@property (readonly, nonatomic, getter=isAbsolutePath) bool absolutePath;

/**
 * @brief The components of the string when interpreted as a path.
 */
@property (readonly, nonatomic) OFArray OF_GENERIC(OFString *) *pathComponents;

/**
 * @brief The last path component of the string when interpreted as a path.
 */
@property (readonly, nonatomic) OFString *lastPathComponent;

/**
 * @brief The file extension of string when interpreted as a path.
 */
@property (readonly, nonatomic) OFString *pathExtension;

/**
 * @brief The directory name of the string when interpreted as a path.
 */
@property (readonly, nonatomic) OFString *stringByDeletingLastPathComponent;

/**
 * @brief The string with the file extension of the path removed.
 */
@property (readonly, nonatomic) OFString *stringByDeletingPathExtension;

/**
 * @brief The string interpreted as a path with relative sub paths resolved.
 */
@property (readonly, nonatomic) OFString *stringByStandardizingPath;

/**
 * @brief Creates a path from the specified path components.
 *
 * @param components An array of components for the path
 * @return A new autoreleased OFString
 */
+ (OFString *)pathWithComponents: (OFArray OF_GENERIC(OFString *) *)components;

/**
 * @brief Creates a new string by appending a path component.
 *
 * @param component The path component to append
 * @return A new, autoreleased OFString with the path component appended
 */
- (OFString *)stringByAppendingPathComponent: (OFString *)component;

/**
 * @brief Creates a new string by appending a path extension.
 *
 * @param extension The extension to append
 * @return A new, autoreleased OFString with the path extension appended
 */
- (OFString *)stringByAppendingPathExtension: (OFString *)extension;

- (bool)of_isDirectoryPath;
- (OFString *)of_pathToIRIPathWithPercentEncodedHost:
    (OFString *__autoreleasing _Nullable *_Nonnull)percentEncodedHost;
- (OFString *)of_IRIPathToPathWithPercentEncodedHost:
    (nullable OFString *)percentEncodedHost;
- (OFString *)of_pathComponentToIRIPathComponent;
@end

OF_ASSUME_NONNULL_END
