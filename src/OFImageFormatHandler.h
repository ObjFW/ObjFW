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
#import "OFImage.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFImageFormatHandler OFImageFormatHandler.h ObjFW/ObjFW.h
 *
 * @brief A handler for an image format.
 */
@interface OFImageFormatHandler: OFObject
{
	OFImageFormat _imageFormat;
	OF_RESERVE_IVARS(OFImageFormatHandler, 4)
}

/**
 * @brief The image format this OFImageFormatHandler handles.
 */
@property (readonly, nonatomic) OFImageFormat imageFormat;

/**
 * @brief Registers the specified class as the handler for the specified image
 *	  format.
 *
 * If the same class is specified for multiple image formats, one instance of
 * it is created per image format.
 *
 * @param class_ The class to register as the handler for the specified image
 *		 format
 * @param imageFormat The image format for which to register the handler
 * @return Whether the class was successfully registered. If a handler for the
 *	   same image format is already registered, registration fails.
 */
+ (bool)registerClass: (Class)class_ forImageFormat: (OFImageFormat)imageFormat;

/**
 * @brief Returns the handler for the specified image format.
 *
 * @return The handler for the specified image format
 * @throw OFNotImplementedException The specified image format it not supported
 */
+ (OFImageFormatHandler *)handlerForImageFormat: (OFImageFormat)imageFormat;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes the handler for the specified image format.
 *
 * @param imageFormat The image format to initialize for
 * @return An initialized image format handler
 */
- (instancetype)initWithImageFormat: (OFImageFormat)imageFormat;

/**
 * @brief Creates a new image from the specified stream.
 *
 * @param stream The stream to create the image from
 * @return A new image
 * @throw OFInvalidFormatExcepetion The stream's format was invalid
 * @throw OFTruncatedDataException The stream ended before all required data
 *				   was read
 * @throw OFOutOfRangeException The image read from the stream is too big for
 *				an OFImage
 * @throw OFReadFailedException Reading from the stream failed
 * @throw OFSeekFailedException Seeking the stream failed
 */
- (OFMutableImage *)readImageFromStream: (OFSeekableStream *)stream;

/**
 * @brief Writes the specified image to the specified stream with the specified
 *	  options.
 *
 * @param image The image to write to the stream
 * @param stream The stream to write the image to
 * @param options Additional format-specific options to write the image to
 *		  the stream
 * @throw OFWriteFailedException Writing to the stream failed
 * @throw OFSeekFailedException Seeking the stream failed
 */
- (void)writeImage: (OFImage *)image
	  toStream: (OFSeekableStream *)stream
	   options: (nullable OFDictionary OF_GENERIC(OFString *, id) *)options;
@end

OF_ASSUME_NONNULL_END
