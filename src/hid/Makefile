include ../../extra.mk

DISTCLEAN = Info.plist	\
	    ObjFWHID.oc

SHARED_LIB = ${OBJFWHID_SHARED_LIB}
STATIC_LIB = ${OBJFWHID_STATIC_LIB}
FRAMEWORK = ${OBJFWHID_FRAMEWORK}
LIB_MAJOR = ${OBJFWHID_LIB_MAJOR}
LIB_MINOR = ${OBJFWHID_LIB_MINOR}
LIB_PATCH = ${OBJFWHID_LIB_PATCH}

SRCS = OHDualSenseGamepad.m		\
       OHDualShock4Gamepad.m		\
       OHExtendedN64Controller.m	\
       OHGameController.m		\
       OHGameControllerAxis.m		\
       OHGameControllerButton.m		\
       OHGameControllerDirectionalPad.m	\
       OHGameControllerElement.m	\
       OHJoyConPair.m			\
       OHLeftJoyCon.m			\
       OHN64Controller.m		\
       OHNESGamepad.m			\
       OHRightJoyCon.m			\
       OHStadiaGamepad.m		\
       OHSwitchProController.m		\
       OHXboxGamepad.m

INCLUDES := ${SRCS:.m=.h}		\
	    OHExtendedGamepad.h		\
	    OHGameControllerProfile.h	\
	    OHGamepad.h			\
	    ObjFWHID.h

SRCS += OHEmulatedGameControllerAxis.m		\
	OHEmulatedGameControllerButton.m	\
	OHEmulatedGameControllerTriggerButton.m	\
	${USE_SRCS_EVDEV}			\
	${USE_SRCS_GCF}				\
	${USE_SRCS_NINTENDO_3DS}		\
	${USE_SRCS_NINTENDO_DS}			\
	${USE_SRCS_NINTENDO_SWITCH}		\
	${USE_SRCS_WII}				\
	${USE_SRCS_XINPUT}
SRCS_EVDEV = OHEvdevExtendedGamepad.m			\
	     OHEvdevGameController.m			\
	     OHEvdevGameControllerProfile.m
SRCS_GCF = OHGCFGameController.m	\
	   OHGCFGameControllerProfile.m
SRCS_NINTENDO_3DS = OHNintendo3DSExtendedGamepad.m	\
		    OHNintendo3DSGameController.m
SRCS_NINTENDO_DS = OHNintendoDSGamepad.m	\
		   OHNintendoDSGameController.m
SRCS_NINTENDO_SWITCH = OHNintendoSwitchExtendedGamepad.m	\
		       OHNintendoSwitchGameController.m
SRCS_WII = OHWiiClassicController.m	\
	   OHWiiGameController.m	\
	   OHWiimote.m			\
	   OHWiimoteWithNunchuk.m
SRCS_XINPUT = OHXInputGameController.m

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

CPPFLAGS += -I.					\
	    -I..				\
	    -I../..				\
	    -I../exceptions			\
	    -I../runtime			\
	    -I../bridge				\
	    -DOBJFWHID_LOCAL_INCLUDES		\
	    -DOBJFWBRIDGE_LOCAL_INCLUDES
LD = ${OBJC}
FRAMEWORK_LIBS := -F..				\
		  -F../runtime			\
		  -F../bridge			\
		  ${HID_FRAMEWORK_LIBS}		\
		  -framework ObjFW		\
		  ${RUNTIME_FRAMEWORK_LIBS}	\
		  ${LIBS}
LIBS := -L..		\
	-L../runtime	\
	-L../bridge	\
	${HID_LIBS}	\
	-lobjfw		\
	${RUNTIME_LIBS}	\
	${LIBS}
