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

#import "OFGameController.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class for combining two Joy-Cons into a single
 *	  @ref OFGameController.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFCombinedJoyConsGameController: OFGameController
{
	OFGameController *_leftJoyCon, *_rightJoyCon;
}

/**
 * @brief Creates a new game controller with the specified left and right
 *	  Joy-Con.
 *
 * @param leftJoyCon The left Joy-Con
 * @param rightJoyCon The right Joy-Con
 * @return A new game controller combining both Joy-Cons into a single game
 *	   controller
 */
+ (instancetype)controllerWithLeftJoyCon: (OFGameController *)leftJoyCon
			     rightJoyCon: (OFGameController *)rightJoyCon;

/**
 * @brief Initialized an already allocated combined Joy-Cons game controller
 *	  with the specified left and right Joy-Con.
 *
 * @param leftJoyCon The left Joy-Con
 * @param rightJoyCon The right Joy-Con
 * @return An initialized combined Joy-Cons game controller combining both
 *	   Joy-Cons into a single game controller
 */
- (instancetype)initWithLeftJoyCon: (OFGameController *)leftJoyCon
		       rightJoyCon: (OFGameController *)rightJoyCon;
@end

OF_ASSUME_NONNULL_END
