/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

const OFFileAttributeKey OFFileSize = @"OFFileSize";
const OFFileAttributeKey OFFileType = @"OFFileType";
const OFFileAttributeKey OFFilePOSIXPermissions = @"OFFilePOSIXPermissions";
const OFFileAttributeKey OFFileOwnerAccountID = @"OFFileOwnerAccountID";
const OFFileAttributeKey OFFileGroupOwnerAccountID =
    @"OFFileGroupOwnerAccountID";
const OFFileAttributeKey OFFileOwnerAccountName = @"OFFileOwnerAccountName";
const OFFileAttributeKey OFFileGroupOwnerAccountName =
    @"OFFileGroupOwnerAccountName";
const OFFileAttributeKey OFFileLastAccessDate = @"OFFileLastAccessDate";
const OFFileAttributeKey OFFileModificationDate = @"OFFileModificationDate";
const OFFileAttributeKey OFFileStatusChangeDate = @"OFFileStatusChangeDate";
const OFFileAttributeKey OFFileCreationDate = @"OFFileCreationDate";
const OFFileAttributeKey OFFileSymbolicLinkDestination =
    @"OFFileSymbolicLinkDestination";

const OFFileAttributeType OFFileTypeRegular = @"OFFileTypeRegular";
const OFFileAttributeType OFFileTypeDirectory = @"OFFileTypeDirectory";
const OFFileAttributeType OFFileTypeSymbolicLink = @"OFFileTypeSymbolicLink";
const OFFileAttributeType OFFileTypeFIFO = @"OFFileTypeFIFO";
const OFFileAttributeType OFFileTypeCharacterSpecial =
    @"OFFileTypeCharacterSpecial";
const OFFileAttributeType OFFileTypeBlockSpecial = @"OFFileTypeBlockSpecial";
const OFFileAttributeType OFFileTypeSocket = @"OFFileTypeSocket";
const OFFileAttributeType OFFileTypeUnknown = @"OFFileTypeUnknown";
