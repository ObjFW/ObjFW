%global libobjfw_major 0
%global libobjfw_minor 0
%global libobjfwrt_major 0
%global libobjfwrt_minor 0
%global libobjfwtls_major 0
%global libobjfwtls_minor 0
%if 0%{?suse_version}
%global libobjfw_pkgname libobjfw%{libobjfw_major}
%global libobjfwrt_pkgname libobjfwrt%{libobjfwrt_major}
%global libobjfwtls_pkgname libobjfwtls%{libobjfwtls_major}
%else
%global libobjfw_pkgname libobjfw
%global libobjfwrt_pkgname libobjfwrt
%global libobjfwtls_pkgname libobjfwtls
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

BuildRequires: autoconf
BuildRequires: automake
BuildRequires: clang
BuildRequires: make
BuildRequires: pkgconfig(gnutls)
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
Summary:       Header files, libraries and tools for %{libobjfw_pkgname}
Requires:      %{libobjfw_pkgname}%{_isa} = %{version}-%{release}
Requires:      %{libobjfwrt_pkgname}-devel = %{version}-%{release}

%description -n %{libobjfw_pkgname}-devel
The %{libobjfw_pkgname}-devel package contains the header files, libraries and
tools to develop programs using ObjFW.

%package -n %{libobjfwrt_pkgname}
Summary:       ObjFW Objective-C runtime library

%description -n %{libobjfwrt_pkgname}
The %{libobjfwrt_pkgname} package contains ObjFW's Objective-C runtime library.

%package -n %{libobjfwrt_pkgname}-devel
Summary:       Header files and libraries for %{libobjfwrt_pkgname}
Requires:      %{libobjfwrt_pkgname}%{_isa} = %{version}-%{release}

%description -n %{libobjfwrt_pkgname}-devel
The %{libobjfwrt_pkgname}-devel package contains header files and libraries for
ObjFW's Objective-C runtime library.

%package -n %{libobjfwtls_pkgname}
Summary:       TLS support for ObjFW
Requires:      gnutls%{_isa} >= 3.0.5

%description -n %{libobjfwtls_pkgname}
The %{libobjfwtls_pkgname} package contains TLS support for ObjFW

%package -n %{libobjfwtls_pkgname}-devel
Summary:       Header files and libraries for %{libobjfwtls_pkgname}
Requires:      %{libobjfwtls_pkgname}%{_isa} = %{version}-%{release}

%description -n %{libobjfwtls_pkgname}-devel
The %{libobjfwtls_pkgname}-devel package contains header files and libraries
for TLS support for ObjFW.

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
Requires:      %{libobjfwtls_pkgname}%{_isa} = %{version}-%{release}

%description -n ofhttp
ofhttp is a command line downloader for HTTP and HTTPS using ObjFW's
OFHTTPClient class. It supports all features one would expect from a modern
command line downloader such as resuming of downloads, using a SOCKS5 proxy, a
modern terminal-based UI, etc.

%prep
%autosetup
./autogen.sh

%build
%configure OBJC=clang --disable-rpath
%make_build

%install
%make_install

%check
make -C tests run

%if 0%{?suse_version}
%post -n %{libobjfw_pkgname} -p /sbin/ldconfig
%postun -n %{libobjfw_pkgname} -p /sbin/ldconfig
%post -n %{libobjfwrt_pkgname} -p /sbin/ldconfig
%postun -n %{libobjfwrt_pkgname} -p /sbin/ldconfig
%endif

%files
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL

%files -n %{libobjfw_pkgname}
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_libdir}/libobjfw.so.%{libobjfw_major}
%{_libdir}/libobjfw.so.%{libobjfw_major}.%{libobjfw_minor}.0

%files -n %{libobjfw_pkgname}-devel
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_bindir}/objfw-compile
%{_bindir}/objfw-config
%{_bindir}/objfw-embed
%{_bindir}/objfw-new
%{_includedir}/ObjFW
%{_libdir}/libobjfw.so

%files -n %{libobjfwrt_pkgname}
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_libdir}/libobjfwrt.so.%{libobjfwrt_major}
%{_libdir}/libobjfwrt.so.%{libobjfwrt_major}.%{libobjfwrt_minor}.0

%files -n %{libobjfwrt_pkgname}-devel
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_includedir}/ObjFWRT
%{_libdir}/libobjfwrt.so

%files -n %{libobjfwtls_pkgname}
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_libdir}/libobjfwtls.so.%{libobjfwtls_major}
%{_libdir}/libobjfwtls.so.%{libobjfwtls_major}.%{libobjfwtls_minor}.0

%files -n %{libobjfwtls_pkgname}-devel
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_includedir}/ObjFWTLS
%{_libdir}/libobjfwtls.so

%files -n ofarc
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_bindir}/ofarc
%{_datadir}/ofarc

%files -n ofdns
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_bindir}/ofdns
%{_datadir}/ofdns

%files -n ofhash
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_bindir}/ofhash
%{_datadir}/ofhash

%files -n ofhttp
%license LICENSE.GPLv2
%license LICENSE.GPLv3
%license LICENSE.QPL
%{_bindir}/ofhttp
%{_datadir}/ofhttp
