include ../../extra.mk

DISTCLEAN = Info.plist

SHARED_LIB = ${OBJFWHID_SHARED_LIB}
STATIC_LIB = ${OBJFWHID_STATIC_LIB}
FRAMEWORK = ${OBJFWHID_FRAMEWORK}
LIB_MAJOR = ${OBJFWHID_LIB_MAJOR}
LIB_MINOR = ${OBJFWHID_LIB_MINOR}
LIB_PATCH = ${OBJFWHID_LIB_PATCH}

SRCS = OHCombinedJoyCons.m		\
       OHExtendedGamepad.m		\
       OHGameController.m		\
       OHGameControllerAxis.m		\
       OHGameControllerButton.m		\
       OHGameControllerDirectionalPad.m	\
       OHGameControllerElement.m	\
       OHGameControllerProfile.m	\
       OHGamepad.m			\
       ${USE_SRCS_EVDEV}		\
       ${USE_SRCS_NINTENDO_3DS}		\
       ${USE_SRCS_NINTENDO_DS}		\
       ${USE_SRCS_XINPUT}
SRCS_EVDEV = OHEvdevDualSense.m				\
	     OHEvdevDualShock4.m			\
	     OHEvdevExtendedGamepad.m			\
	     OHEvdevGameController.m			\
	     OHEvdevPlayStationExtendedGamepad.m	\
	     OHEvdevStadiaExtendedGamepad.m
SRCS_NINTENDO_3DS = OHNintendo3DSGameController.m	\
		    OHNintendo3DSExtendedGamepad.m
SRCS_NINTENDO_DS = OHNintendoDSGameController.m
SRCS_XINPUT = OHXInputExtendedGamepad.m	\
	      OHXInputGameController.m

INCLUDES := ${SRCS:.m=.h}	\
	    ObjFWHID.h

SRCS += OHGameControllerEmulatedAxis.m		\
	OHGameControllerEmulatedButton.m	\
	OHGameControllerEmulatedTriggerButton.m

includesubdir = ObjFWHID

include ../../buildsys.mk

install-extra:
	i=ObjFWHID.oc; \
	${INSTALL_STATUS}; \
	if ${MKDIR_P} ${DESTDIR}${libdir}/objfw-config && \
	    ${INSTALL} -m 644 $$i ${DESTDIR}${libdir}/objfw-config/$$i; then \
		${INSTALL_OK}; \
	else \
		${INSTALL_FAILED}; \
	fi

uninstall-extra:
	i=ObjFWHID.oc; \
	if test -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
		if rm -f ${DESTDIR}${libdir}/objfw-config/$$i; then \
			${DELETE_OK}; \
		else \
			${DELETE_FAILED}; \
		fi \
	fi
	rmdir ${DESTDIR}${libdir}/objfw-config >/dev/null 2>&1 || true

CPPFLAGS += -I.				\
	    -I..			\
	    -I../..			\
	    -I../exceptions		\
	    -I../runtime		\
	    -DOBJFWHID_LOCAL_INCLUDES
LD = ${OBJC}
FRAMEWORK_LIBS := -F.. -framework ObjFW ${RUNTIME_LIBS} ${LIBS}
LIBS := -L.. -lobjfw -L../runtime ${RUNTIME_LIBS} ${LIBS}
