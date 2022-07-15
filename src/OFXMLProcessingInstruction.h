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

#import "OFXMLNode.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFXMLProcessingInstruction \
 *	  OFXMLProcessingInstruction.h ObjFW/OFXMLProcessingInstruction.h
 *
 * @brief A class for representing an XML processing instruction.
 */
@interface OFXMLProcessingInstruction: OFXMLNode
{
	OFString *_target, *_data;
	OF_RESERVE_IVARS(OFXMLProcessingInstruction, 4)
}

/**
 * @brief The target of the processing instruction.
 */
@property (readonly, nonatomic) OFString *target;

/**
 * @brief The data of the processing instruction.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *data;

/**
 * @brief Creates a new OFXMLProcessingInstruction with the specified target
 *	  and data.
 *
 * @param target The target for the processing instruction
 * @param data The data for the processing instruction
 * @return A new OFXMLProcessingInstruction
 */
+ (instancetype)processingInstructionWithTarget: (OFString *)target
					   data: (OFString *)data;

/**
 * @brief Initializes an already allocated OFXMLProcessingInstruction with the
 *	  specified target and data.
 *
 * @param target The target for the processing instruction
 * @param data The data for the processing instruction
 * @return An initialized OFXMLProcessingInstruction
 */
- (instancetype)initWithTarget: (OFString *)target
			  data: (OFString *)data OF_DESIGNATED_INITIALIZER;

- (instancetype)initWithSerialization: (OFXMLElement *)element;
@end

OF_ASSUME_NONNULL_END
