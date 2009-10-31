PROG_NOINST = gen_tables${PROG_SUFFIX}
SRCS = main.o			\
       UpperLowerGenerator.m	\
       CaseFoldingGenerator.m

.PHONY: run
run: all UnicodeData.txt CaseFolding.txt
	rm -f libobjfw.so.0 libobjfw.so.0.1 libobjfw.dll libobjfw.dylib
	if test -f ../src/libobjfw.so; then \
		ln -s ../src/libobjfw.so libobjfw.so.0; \
		ln -s ../src/libobjfw.so libobjfw.so.0.1; \
	elif test -f ../src/libobjfw.so.0.1; then \
		ln -s ../src/libobjfw.so.0.1 libobjfw.so.0.1; \
	fi
	if test -f ../src/libobjfw.dll; then \
		ln ../src/libobjfw.dll libobjfw.dll; \
	fi
	if test -f ../src/libobjfw.dylib; then \
		ln -s ../src/libobjfw.dylib libobjfw.dylib; \
	fi
	echo "Generating tables..."
	LD_LIBRARY_PATH=.$${LD_LIBRARY_PATH+:}$$LD_LIBRARY_PATH \
	DYLD_LIBRARY_PATH=.$${DYLD_LIBRARY_PATH+:}$$DYLD_LIBRARY_PATH \
	${TEST_LAUNCHER} ./${PROG_NOINST}; EXIT=$$?; \
	rm -f libobjfw.so.0 libobjfw.so.0.1 libobjfw.dll libobjfw.dylib; \
	exit $$EXIT

UnicodeData.txt:
	wget http://unicode.org/Public/UNIDATA/UnicodeData.txt

CaseFolding.txt:
	wget http://www.unicode.org/Public/UNIDATA/CaseFolding.txt

include ../buildsys.mk

CPPFLAGS += -I../src -I..
LIBS := -L../src -lobjfw ${LIBS}
