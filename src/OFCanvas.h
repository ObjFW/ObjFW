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
 * @protocol OFCanvas OFCanvas.h ObjFW/ObjFW.h
 *
 * @brief A protocol for a canvas that can be drawn to.
 *
 * To what it is drawn is implementation specific - it could be to an
 * @ref OFImage or to an OpenGL context, for example. @ref OFCanvas is an
 * implementation drawing to an @ref OFImage in software and always available.
 */
@protocol OFCanvas <OFObject>
/**
 * @brief The background color of the canvas.
 */
@property (retain, nonatomic) OFColor *backgroundColor;

/**
 * @brief Clears the specified rectangle with the background color.
 *
 * @param rect The rectangle to clear
 * @throw OFInvalidArgumentException The specified rectangle is not integral
 */
- (void)clearRect: (OFRect)rect;
@end

/**
 * @class OFCanvas OFCanvas.h ObjFW/ObjFW.h
 *
 * @brief An implementation of @ref OFCanvas-p "<OFCanvas>" that draws to an
 *	  @ref OFImage.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFCanvas: OFObject <OFCanvas>
{
	OFMutableImage *_destinationImage;
	size_t _width;
	OFRect _rect;
	void *_pixels;
	OFPixelFormat _pixelFormat;
	OFColor *_backgroundColor;
}

/**
 * @brief Creates a new canvas with the specified destination image.
 *
 * @param image The image to draw to
 * @return A new OFCanvas
 */
+ (instancetype)canvasWithDestinationImage: (OFMutableImage *)image;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated canvas with the specified
 *	  destination image.
 *
 * @param image The image to draw to
 * @return An initialized OFCanvas
 */
- (instancetype)initWithDestinationImage: (OFMutableImage *)image;
@end

OF_ASSUME_NONNULL_END
