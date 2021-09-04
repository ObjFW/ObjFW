%global libobjfw_major 0
%global libobjfw_minor 0
%global libobjfwrt_major 0
%global libobjfwrt_minor 0
%if 0%{?suse_version}
%global libobjfw_pkgname libobjfw%{libobjfw_major}
%global libobjfwrt_pkgname libobjfwrt%{libobjfwrt_major}
%else
%global libobjfw_pkgname libobjfw
%global libobjfwrt_pkgname libobjfwrt
%endif

Name:          objfw
Version:       1.1dev
Release:       1%{?dist}
Summary:       Portable, lightweight framework for the Objective-C language

%if 0%{?suse_version}
License:       QPL-1.0 or GPL-3.0 or GPL-2.0
Group:         Development/Languages/C and C++
%else
License:       QPL or GPLv3 or GPLv2
%endif
URL:           https://objfw.nil.im
Source0:       objfw-%{version}.tar.gz

BuildRequires: clang
BuildRequires: make
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfw_pkgname}-devel = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}-devel = %{version}-%{release}
Requires:      ofarc%{_isa} = %{version}-%{release}
Requires:      ofdns%{_isa} = %{version}-%{release}
Requires:      ofhash%{_isa} = %{version}-%{release}
Requires:      ofhttp%{_isa} = %{version}-%{release}

%description
ObjFW is a portable, lightweight framework for the Objective-C language. It
enables you to write an application in Objective-C that will run on any
platform supported by ObjFW without having to worry about differences between
operating systems or various frameworks you would otherwise need if you want to
be portable.

It supports all modern Objective-C features when using Clang, but is also
compatible with GCC ≥ 4.6 to allow maximum portability.

ObjFW also comes with its own lightweight and extremely fast Objective-C
runtime, which in real world use cases was found to be significantly faster
than both GNU's and Apple's runtime.

%package -n %{libobjfw_pkgname}
Summary:       ObjFW library
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n %{libobjfw_pkgname}
The %{libobjfw_pkgname} package contains the library needed by programs using
ObjFW.

%package -n %{libobjfw_pkgname}-devel
Summary:       Header files and tools for %{libobjfw_pkgname}
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}-devel = %{version}-%{release}

%description -n %{libobjfw_pkgname}-devel
The %{libobjfw_pkgname}-devel package contains the header files and tools to
develop programs using ObjFW.

%package -n %{libobjfwrt_pkgname}
Summary:       ObjFW Objective-C runtime library

%description -n %{libobjfwrt_pkgname}
The %{libobjfwrt_pkgname} package contains ObjFW's Objective-C runtime library.

%package -n %{libobjfwrt_pkgname}-devel
Summary:       Header files for %{libobjfwrt_pkgname}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n %{libobjfwrt_pkgname}-devel
The %{libobjfwrt_pkgname}-devel package contains header files for ObjFW's
Objective-C runtime library.

%package -n ofarc
Summary:       Utility for handling ZIP, Tar and LHA archives
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n ofarc
ofarc is a multi-format archive utility that allows creating, listing,
extracting and modifying ZIP, Tar and LHA archives using ObjFW's classes for
various archive types.

%package -n ofdns
Summary:       Utility for performing DNS requests on the command line
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n ofdns
ofdns is an utility for performing DNS requests on the command line using
ObjFW's DNS resolver.

%package -n ofhash
Summary:       Utility to hash files with various cryptographic hash functions
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n ofhash
ofhash is an utility to hash files with various cryptographic hash functions
(even using different algorithms at once) using ObjFW's classes for various
cryptographic hashes.

%package -n ofhttp
Summary:       Command line downloader for HTTP(S)
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n ofhttp
ofhttp is a command line downloader for HTTP and HTTPS (via ObjOpenSSL) using
ObjFW's OFHTTPClient class. It supports all features one would expect from a
modern command line downloader such as resuming of downloads, using a SOCKS5
proxy, a modern terminal-based UI, etc.

%prep
%autosetup

%build
%configure --disable-rpath
%make_build

%install
%make_install

%if 0%{?suse_version}
%post -n %{libobjfw_pkgname} -p /sbin/ldconfig
%postun -n %{libobjfw_pkgname} -p /sbin/ldconfig
%post -n %{libobjfwrt_pkgname} -p /sbin/ldconfig
%postun -n %{libobjfwrt_pkgname} -p /sbin/ldconfig
%endif

%files
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n %{libobjfw_pkgname}
%{_libdir}/libobjfw.so.%{libobjfw_major}
%{_libdir}/libobjfw.so.%{libobjfw_major}.%{libobjfw_minor}.0
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n %{libobjfw_pkgname}-devel
%{_libdir}/libobjfw.so
%{_includedir}/ObjFW/OFASPrintF.h
%{_includedir}/ObjFW/OFAcceptFailedException.h
%{_includedir}/ObjFW/OFAllocFailedException.h
%{_includedir}/ObjFW/OFAlreadyConnectedException.h
%{_includedir}/ObjFW/OFApplication.h
%{_includedir}/ObjFW/OFArray.h
%{_includedir}/ObjFW/OFAtomic.h
%{_includedir}/ObjFW/OFBase64.h
%{_includedir}/ObjFW/OFBindFailedException.h
%{_includedir}/ObjFW/OFBlock.h
%{_includedir}/ObjFW/OFCRC16.h
%{_includedir}/ObjFW/OFCRC32.h
%{_includedir}/ObjFW/OFChangeCurrentDirectoryPathFailedException.h
%{_includedir}/ObjFW/OFCharacterSet.h
%{_includedir}/ObjFW/OFChecksumMismatchException.h
%{_includedir}/ObjFW/OFCollection.h
%{_includedir}/ObjFW/OFColor.h
%{_includedir}/ObjFW/OFCondition.h
%{_includedir}/ObjFW/OFConditionBroadcastFailedException.h
%{_includedir}/ObjFW/OFConditionSignalFailedException.h
%{_includedir}/ObjFW/OFConditionStillWaitingException.h
%{_includedir}/ObjFW/OFConditionWaitFailedException.h
%{_includedir}/ObjFW/OFConnectionFailedException.h
%{_includedir}/ObjFW/OFConstantString.h
%{_includedir}/ObjFW/OFCopyItemFailedException.h
%{_includedir}/ObjFW/OFCountedSet.h
%{_includedir}/ObjFW/OFCreateDirectoryFailedException.h
%{_includedir}/ObjFW/OFCreateSymbolicLinkFailedException.h
%{_includedir}/ObjFW/OFCryptographicHash.h
%{_includedir}/ObjFW/OFDNSQuery.h
%{_includedir}/ObjFW/OFDNSQueryFailedException.h
%{_includedir}/ObjFW/OFDNSResolver.h
%{_includedir}/ObjFW/OFDNSResourceRecord.h
%{_includedir}/ObjFW/OFDNSResponse.h
%{_includedir}/ObjFW/OFData+CryptographicHashing.h
%{_includedir}/ObjFW/OFData+MessagePackParsing.h
%{_includedir}/ObjFW/OFData.h
%{_includedir}/ObjFW/OFDatagramSocket.h
%{_includedir}/ObjFW/OFDate.h
%{_includedir}/ObjFW/OFDictionary.h
%{_includedir}/ObjFW/OFEnumerationMutationException.h
%{_includedir}/ObjFW/OFEnumerator.h
%{_includedir}/ObjFW/OFException.h
%{_includedir}/ObjFW/OFFile.h
%{_includedir}/ObjFW/OFFileManager.h
%{_includedir}/ObjFW/OFGZIPStream.h
%{_includedir}/ObjFW/OFGetCurrentDirectoryPathFailedException.h
%{_includedir}/ObjFW/OFGetOptionFailedException.h
%{_includedir}/ObjFW/OFHMAC.h
%{_includedir}/ObjFW/OFHTTPClient.h
%{_includedir}/ObjFW/OFHTTPCookie.h
%{_includedir}/ObjFW/OFHTTPCookieManager.h
%{_includedir}/ObjFW/OFHTTPRequest.h
%{_includedir}/ObjFW/OFHTTPRequestFailedException.h
%{_includedir}/ObjFW/OFHTTPResponse.h
%{_includedir}/ObjFW/OFHTTPServer.h
%{_includedir}/ObjFW/OFHashAlreadyCalculatedException.h
%{_includedir}/ObjFW/OFHuffmanTree.h
%{_includedir}/ObjFW/OFINICategory.h
%{_includedir}/ObjFW/OFINIFile.h
%{_includedir}/ObjFW/OFIPXSocket.h
%{_includedir}/ObjFW/OFInflate64Stream.h
%{_includedir}/ObjFW/OFInflateStream.h
%{_includedir}/ObjFW/OFInitializationFailedException.h
%{_includedir}/ObjFW/OFInvalidArgumentException.h
%{_includedir}/ObjFW/OFInvalidEncodingException.h
%{_includedir}/ObjFW/OFInvalidFormatException.h
%{_includedir}/ObjFW/OFInvalidJSONException.h
%{_includedir}/ObjFW/OFInvalidServerReplyException.h
%{_includedir}/ObjFW/OFInvocation.h
%{_includedir}/ObjFW/OFJSONRepresentation.h
%{_includedir}/ObjFW/OFKernelEventObserver.h
%{_includedir}/ObjFW/OFKeyValueCoding.h
%{_includedir}/ObjFW/OFLHAArchive.h
%{_includedir}/ObjFW/OFLHAArchiveEntry.h
%{_includedir}/ObjFW/OFLinkFailedException.h
%{_includedir}/ObjFW/OFList.h
%{_includedir}/ObjFW/OFListenFailedException.h
%{_includedir}/ObjFW/OFLoadPluginFailedException.h
%{_includedir}/ObjFW/OFLocale.h
%{_includedir}/ObjFW/OFLockFailedException.h
%{_includedir}/ObjFW/OFLocking.h
%{_includedir}/ObjFW/OFMD5Hash.h
%{_includedir}/ObjFW/OFMalformedXMLException.h
%{_includedir}/ObjFW/OFMapTable.h
%{_includedir}/ObjFW/OFMemoryNotPartOfObjectException.h
%{_includedir}/ObjFW/OFMessagePackExtension.h
%{_includedir}/ObjFW/OFMessagePackRepresentation.h
%{_includedir}/ObjFW/OFMethodSignature.h
%{_includedir}/ObjFW/OFMoveItemFailedException.h
%{_includedir}/ObjFW/OFMutableArray.h
%{_includedir}/ObjFW/OFMutableData.h
%{_includedir}/ObjFW/OFMutableDictionary.h
%{_includedir}/ObjFW/OFMutableLHAArchiveEntry.h
%{_includedir}/ObjFW/OFMutablePair.h
%{_includedir}/ObjFW/OFMutableSet.h
%{_includedir}/ObjFW/OFMutableString.h
%{_includedir}/ObjFW/OFMutableTarArchiveEntry.h
%{_includedir}/ObjFW/OFMutableTriple.h
%{_includedir}/ObjFW/OFMutableURL.h
%{_includedir}/ObjFW/OFMutableZIPArchiveEntry.h
%{_includedir}/ObjFW/OFMutex.h
%{_includedir}/ObjFW/OFNotImplementedException.h
%{_includedir}/ObjFW/OFNotOpenException.h
%{_includedir}/ObjFW/OFNull.h
%{_includedir}/ObjFW/OFNumber.h
%{_includedir}/ObjFW/OFObject+KeyValueCoding.h
%{_includedir}/ObjFW/OFObject+Serialization.h
%{_includedir}/ObjFW/OFObject.h
%{_includedir}/ObjFW/OFObserveFailedException.h
%{_includedir}/ObjFW/OFOnce.h
%{_includedir}/ObjFW/OFOpenItemFailedException.h
%{_includedir}/ObjFW/OFOptionsParser.h
%{_includedir}/ObjFW/OFOutOfMemoryException.h
%{_includedir}/ObjFW/OFOutOfRangeException.h
%{_includedir}/ObjFW/OFPBKDF2.h
%{_includedir}/ObjFW/OFPair.h
%{_includedir}/ObjFW/OFPlainCondition.h
%{_includedir}/ObjFW/OFPlainMutex.h
%{_includedir}/ObjFW/OFPlainThread.h
%{_includedir}/ObjFW/OFPlugin.h
%{_includedir}/ObjFW/OFRIPEMD160Hash.h
%{_includedir}/ObjFW/OFReadFailedException.h
%{_includedir}/ObjFW/OFReadOrWriteFailedException.h
%{_includedir}/ObjFW/OFRecursiveMutex.h
%{_includedir}/ObjFW/OFRemoveItemFailedException.h
%{_includedir}/ObjFW/OFResolveHostFailedException.h
%{_includedir}/ObjFW/OFRetrieveItemAttributesFailedException.h
%{_includedir}/ObjFW/OFRunLoop.h
%{_includedir}/ObjFW/OFSHA1Hash.h
%{_includedir}/ObjFW/OFSHA224Hash.h
%{_includedir}/ObjFW/OFSHA224Or256Hash.h
%{_includedir}/ObjFW/OFSHA256Hash.h
%{_includedir}/ObjFW/OFSHA384Hash.h
%{_includedir}/ObjFW/OFSHA384Or512Hash.h
%{_includedir}/ObjFW/OFSHA512Hash.h
%{_includedir}/ObjFW/OFSPXSocket.h
%{_includedir}/ObjFW/OFSPXStreamSocket.h
%{_includedir}/ObjFW/OFScrypt.h
%{_includedir}/ObjFW/OFSecureData.h
%{_includedir}/ObjFW/OFSeekFailedException.h
%{_includedir}/ObjFW/OFSeekableStream.h
%{_includedir}/ObjFW/OFSequencedPacketSocket.h
%{_includedir}/ObjFW/OFSerialization.h
%{_includedir}/ObjFW/OFSet.h
%{_includedir}/ObjFW/OFSetItemAttributesFailedException.h
%{_includedir}/ObjFW/OFSetOptionFailedException.h
%{_includedir}/ObjFW/OFSettings.h
%{_includedir}/ObjFW/OFSocket.h
%{_includedir}/ObjFW/OFSortedList.h
%{_includedir}/ObjFW/OFStdIOStream.h
%{_includedir}/ObjFW/OFStillLockedException.h
%{_includedir}/ObjFW/OFStrPTime.h
%{_includedir}/ObjFW/OFStream.h
%{_includedir}/ObjFW/OFStreamSocket.h
%{_includedir}/ObjFW/OFString+CryptographicHashing.h
%{_includedir}/ObjFW/OFString+JSONParsing.h
%{_includedir}/ObjFW/OFString+PathAdditions.h
%{_includedir}/ObjFW/OFString+PropertyListParsing.h
%{_includedir}/ObjFW/OFString+Serialization.h
%{_includedir}/ObjFW/OFString+URLEncoding.h
%{_includedir}/ObjFW/OFString+XMLEscaping.h
%{_includedir}/ObjFW/OFString+XMLUnescaping.h
%{_includedir}/ObjFW/OFString.h
%{_includedir}/ObjFW/OFSystemInfo.h
%{_includedir}/ObjFW/OFTCPSocket.h
%{_includedir}/ObjFW/OFTLSKey.h
%{_includedir}/ObjFW/OFTLSSocket.h
%{_includedir}/ObjFW/OFTarArchive.h
%{_includedir}/ObjFW/OFTarArchiveEntry.h
%{_includedir}/ObjFW/OFThread.h
%{_includedir}/ObjFW/OFThreadJoinFailedException.h
%{_includedir}/ObjFW/OFThreadPool.h
%{_includedir}/ObjFW/OFThreadStartFailedException.h
%{_includedir}/ObjFW/OFThreadStillRunningException.h
%{_includedir}/ObjFW/OFTimer.h
%{_includedir}/ObjFW/OFTriple.h
%{_includedir}/ObjFW/OFTruncatedDataException.h
%{_includedir}/ObjFW/OFUDPSocket.h
%{_includedir}/ObjFW/OFURL.h
%{_includedir}/ObjFW/OFURLHandler.h
%{_includedir}/ObjFW/OFUnboundNamespaceException.h
%{_includedir}/ObjFW/OFUnboundPrefixException.h
%{_includedir}/ObjFW/OFUndefinedKeyException.h
%{_includedir}/ObjFW/OFUnknownXMLEntityException.h
%{_includedir}/ObjFW/OFUnlockFailedException.h
%{_includedir}/ObjFW/OFUnsupportedProtocolException.h
%{_includedir}/ObjFW/OFUnsupportedVersionException.h
%{_includedir}/ObjFW/OFValue.h
%{_includedir}/ObjFW/OFWriteFailedException.h
%{_includedir}/ObjFW/OFXMLAttribute.h
%{_includedir}/ObjFW/OFXMLCDATA.h
%{_includedir}/ObjFW/OFXMLCharacters.h
%{_includedir}/ObjFW/OFXMLComment.h
%{_includedir}/ObjFW/OFXMLElement+Serialization.h
%{_includedir}/ObjFW/OFXMLElement.h
%{_includedir}/ObjFW/OFXMLElementBuilder.h
%{_includedir}/ObjFW/OFXMLNode.h
%{_includedir}/ObjFW/OFXMLParser.h
%{_includedir}/ObjFW/OFXMLProcessingInstruction.h
%{_includedir}/ObjFW/OFZIPArchive.h
%{_includedir}/ObjFW/OFZIPArchiveEntry.h
%{_includedir}/ObjFW/ObjFW.h
%{_includedir}/ObjFW/macros.h
%{_includedir}/ObjFW/objfw-defs.h
%{_includedir}/ObjFW/platform.h
%{_includedir}/ObjFW/platform/GCC4.7/OFAtomic.h
%{_includedir}/ObjFW/platform/GCC4/OFAtomic.h
%{_includedir}/ObjFW/platform/PowerPC/OFAtomic.h
%{_includedir}/ObjFW/platform/macOS/OFAtomic.h
%{_includedir}/ObjFW/platform/x86/OFAtomic.h
%{_bindir}/objfw-compile
%{_bindir}/objfw-config
%{_bindir}/objfw-new
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n %{libobjfwrt_pkgname}
%{_libdir}/libobjfwrt.so.%{libobjfwrt_major}
%{_libdir}/libobjfwrt.so.%{libobjfwrt_major}.%{libobjfwrt_minor}.0
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n %{libobjfwrt_pkgname}-devel
%{_libdir}/libobjfwrt.so
%{_includedir}/ObjFWRT/ObjFWRT.h
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n ofarc
%{_bindir}/ofarc
%{_datadir}/ofarc/lang/de.json
%{_datadir}/ofarc/lang/languages.json
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n ofdns
%{_bindir}/ofdns
%{_datadir}/ofdns/lang/de.json
%{_datadir}/ofdns/lang/languages.json
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n ofhash
%{_bindir}/ofhash
%{_datadir}/ofhash/lang/de.json
%{_datadir}/ofhash/lang/languages.json
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2

%files -n ofhttp
%{_bindir}/ofhttp
%{_datadir}/ofhttp/lang/de.json
%{_datadir}/ofhttp/lang/languages.json
%license LICENSE.QPL
%license LICENSE.GPLv3
%license LICENSE.GPLv2
