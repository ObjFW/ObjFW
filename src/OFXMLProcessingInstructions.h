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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFXMLProcessingInstructions \
 *	  OFXMLProcessingInstructions.h ObjFW/OFXMLProcessingInstructions.h
 *
 * @brief A class for representing XML processing instructions.
 */
@interface OFXMLProcessingInstructions: OFXMLNode
{
	OFString *_processingInstructions;
}

/*!
 * @brief Creates a new OFXMLProcessingInstructions with the specified string.
 *
 * @param string The string for the processing instructions
 * @return A new OFXMLProcessingInstructions
 */
+ (instancetype)processingInstructionsWithString: (OFString *)string;

/*!
 * @brief Initializes an already allocated OFXMLProcessingInstructions with the
 *	  specified string.
 *
 * @param string The string for the processing instructions
 * @return An initialized OFXMLProcessingInstructions
 */
- initWithString: (OFString *)string;

- initWithSerialization: (OFXMLElement *)element;
@end

OF_ASSUME_NONNULL_END
