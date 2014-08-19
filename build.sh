#!/bin/sh

set -e
set -u

jflag=
jval=2

while getopts 'j:' OPTION
do
  case $OPTION in
  j)	jflag=1
        	jval="$OPTARG"
	        ;;
  ?)	printf "Usage: %s: [-j concurrency_level] (hint: your cores + 20%%)\n" $(basename $0) >&2
		exit 2
		;;
  esac
done
shift $(($OPTIND - 1))

if [ "$jflag" ]
then
  if [ "$jval" ]
  then
    printf "Option -j specified (%d)\n" $jval
  fi
fi

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR"

# NOTE: this is a fetchurl parameter, nothing to do with the current script
#export TARGET_DIR_DIR="$BUILD_DIR"

echo "#### pidgin build, by oglops ####"
cd $BUILD_DIR
../fetchurl "http://downloads.sourceforge.net/project/pidgin/Pidgin/2.10.9/pidgin-2.10.9.tar.bz2"
git clone https://github.com/xiehuc/pidgin-lwqq.git
git clone https://github.com/xiehuc/lwqq.git


echo "*** Building pidgin ***"
cd $BUILD_DIR/pidgin-*
./configure --disable-screensaver --disable-gtkspell --disable-vv --disable-meanwhile --disable-avahi --disable-nm --with-static-prpls="gg irc jabber msn myspace mxit novell oscar simple yahoo zephyr" --enable-static --prefix=$TARGET_DIR 
make -j $jval

# Don't fail when there are no warnings for gconf during the install
# https://pidgin.im/pipermail/commits/2014-February/024518.html
sed -i.bak '/grep -v "^Attached schema" 1>&2/s/$/ || true /' libpurple/gconf/Makefile
make install


echo "*** Building lwqq ***"
cd $BUILD_DIR/lwqq
git checkout -b dev origin/dev
mkdir build && cd build
cmake ..
make
make install DESTDIR=$TARGET_DIR/tmp
rsync -av $TARGET_DIR/tmp/usr/local/* $TARGET_DIR/ --remove-source-files


echo "*** Building pidgin-lwqq ***"
cd $BUILD_DIR/pidgin-lwqq
git checkout -b dev origin/dev
mkdir build && cd build
cmake ..
make
make install prefix=$TARGET_DIR





# # FIXME: only OS-specific
# rm -f "$TARGET_DIR/lib/*.dylib"
# rm -f "$TARGET_DIR/lib/*.so"

# # FFMpeg
# echo "*** Building FFmpeg ***"
# cd $BUILD_DIR/ffmpeg*

# # comment out the "require_pkg_config librtmp ..." line
# # this line assumes you have installed librtmp to your /usr/lib64 
# # but here i want a "static" build
# # sed -i.bak '/enabled librtmp/s/^/# /' configure

# CFLAGS="-I$TARGET_DIR/include" LDFLAGS="-L$TARGET_DIR/lib -lm" ./configure --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-cflags="-I$TARGET_DIR/include -static" --extra-ldflags="-L$TARGET_DIR/lib -lm -static" --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --disable-ffplay --disable-ffserver --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-bzlib --enable-zlib --enable-nonfree --enable-version3 --enable-libvpx --disable-devices --enable-librtmp  --extra-libs="-ldl"
# make -j $jval && make install
