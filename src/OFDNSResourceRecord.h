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

#import "OFObject.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/*!
 * @class OFDNSResourceRecord OFDNSResourceRecord.h ObjFW/OFDNSResourceRecord.h
 *
 * @brief A class represenging a DNS resource record.
 */
@interface OFDNSResourceRecord: OFObject
{
	OFString *_name;
	uint16_t _type;
	uint16_t _dataClass;
	OFData *_data;
	uint32_t _TTL;
}

/**
 * @brief The domain name to which the resource record belongs.
 */
@property (readonly, nonatomic) OFString *name;

/*!
 * @brief The resource record type code.
 */
@property (readonly, nonatomic) uint16_t type;

/*!
 * @brief The class of the data.
 */
@property (readonly, nonatomic) uint16_t dataClass;

/*!
 * The data of the resource.
 */
@property (readonly, nonatomic) OFData *data;

/*!
 * @brief The number of seconds after which the resource record should be
 *	  discarded from the cache.
 */
@property (readonly, nonatomic) uint32_t TTL;

/*!
 * @brief If the resource record is an A or AAAA record, this contains the data
 *	  interpreted as an IP address.
 */
@property (readonly, nonatomic) OFString *IPAddress;

- (instancetype)initWithName: (OFString *)name
			type: (uint16_t)type
		   dataClass: (uint16_t)dataClass
			data: (OFData *)data
			 TTL: (uint32_t)TTL OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
