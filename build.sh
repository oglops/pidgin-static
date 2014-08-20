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
git clone git@github.com:oglops/pidgin-sendscreenshot.git
../fetchurl "http://dist.schmorp.de/libev/libev-4.15.tar.gz"
# ../fetchurl "http://ftp.mozilla.org/pub/mozilla.org/js/mozjs-24.2.0.tar.bz2"
../fetchurl "http://ftp.mozilla.org/pub/mozilla.org/js/mozjs17.0.0.tar.gz"
# ../fetchurl "http://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz"
../fetchurl "https://pidgin-gnome-keyring.googlecode.com/files/pidgin-gnome-keyring-1.20_src.tar.gz"
git clone https://github.com/interskh/Recent-Contacts-Plugin-for-Pidgin.git
git clone https://github.com/tony2001/pidgin-libnotify.git


# echo "*** Building autoconf ***"
# cd $BUILD_DIR/autoconf*
# ./configure --prefix=$TARGET_DIR
# make 
# make install

echo "*** Building libev ***"
cd $BUILD_DIR/libev*
./configure --enable-shared=no --prefix=$TARGET_DIR
make 
make install
libev_pc=$TARGET_DIR/lib/pkgconfig/libev.pc
if [ ! -f $libev_pc ]; then
  echo "#### create libev.pc ####"
  mkdir -p $TARGET_DIR/lib/pkgconfig
  cat <<EOF > $libev_pc

  prefix=$TARGET_DIR
  exec_prefix=\${prefix}
  libdir=\${prefix}/lib
  includedir=\${exec_prefix}/include/libev

  Name: libev
  Description: High-performance event loop/event model
  Version: 4.03
  Libs: -L\${libdir} -lev
  Libs.private: 
  Cflags: -I\${includedir}
EOF

fi
mkdir -p $TARGET_DIR/include/libev
mv $TARGET_DIR/include/*.h $TARGET_DIR/include/libev

echo "*** Building mozjs ***"
cd $BUILD_DIR/mozjs17*
cd js/src
# ./configure --disable-shared-js --prefix=$DESTDIR
# ./configure --prefix=$TARGET_DIR
./configure
make
make install DESTDIR=$TARGET_DIR/mozjs_tmp
rsync -avI $TARGET_DIR/mozjs_tmp/* $TARGET_DIR/ --remove-source-files
# update pc file
MOZJS=$TARGET_DIR/lib/pkgconfig/mozjs-17.0.pc
sed -e "s|prefix=|prefix=$TARGET_DIR|"  $MOZJS > mozjs_tmp.pc
mv mozjs_tmp.pc $MOZJS
sed -e "s|libdir=/lib|libdir=\${prefix}/lib|"  $MOZJS > mozjs_tmp.pc
mv mozjs_tmp.pc $MOZJS
sed -e "s|includedir=/include|includedir=\${prefix}/include|"  $MOZJS > mozjs_tmp.pc
mv mozjs_tmp.pc $MOZJS
rm -rf $TARGET_DIR/mozjs_tmp


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

sed -e "s|/usr/local/include/libev|/usr/local/include/libev\n$TARGET_DIR/include/libev|" $BUILD_DIR/lwqq/cmake/FindEV.cmake > FindEV_tmp.pc
mv FindEV_tmp.pc $BUILD_DIR/lwqq/cmake/FindEV.cmake
sed -e "s|/usr/local/lib64|/usr/local/lib64 $TARGET_DIR/lib|" $BUILD_DIR/lwqq/cmake/FindEV.cmake > FindEV_tmp.pc
mv FindEV_tmp.pc $BUILD_DIR/lwqq/cmake/FindEV.cmake

cmake ..
make
make install DESTDIR=$TARGET_DIR/lwqq_tmp
rsync -av $TARGET_DIR/tmp/usr/local/* $TARGET_DIR/ --remove-source-files
sed -e "s|prefix=/usr/local|prefix=$TARGET_DIR|" $TARGET_DIR/lib/pkgconfig/lwqq.pc > xxx.pc
mv xxx.pc $TARGET_DIR/lib/pkgconfig/lwqq.pc
rm -rf TARGET_DIR/lwqq_tmp


echo "*** Building pidgin-lwqq ***"
cd $BUILD_DIR/pidgin-lwqq
git checkout -b dev origin/dev
mkdir build && cd build
cmake ..
make
make install DESTDIR=$TARGET_DIR/pidgin_tmp
rsync -avI $TARGET_DIR/pidgin_tmp/usr/local/* $TARGET_DIR/ --remove-source-files
rsync -avI $TARGET_DIR/pidgin_tmp/usr/share $TARGET_DIR/ --remove-source-files
rsync -avI $TARGET_DIR/pidgin_tmp/$TARGET_DIR/* $TARGET_DIR/ --remove-source-files
rm -rf TARGET_DIR/pidgin_tmp

echo "*** Building pidgin-sendscreenshot ***"
cd $BUILD_DIR/pidgin-sendscreenshot
git fetch
git checkout dev
./configure --prefix=$DESTDIR
make
make install


echo "*** Building pidgin-gnome-keyring ***"
cd $BUILD_DIR/pidgin-gnome-keyring*
make
# it copies gnome-keyring.so ~/.purple/plugins/
make install 

echo "*** Building Recent-Contacts-Plugin-for-Pidgin ***"
cd $BUILD_DIR/Recent-Contacts-Plugin-for-Pidgin*
cmake -D CMAKE_INSTALL_PREFIX=$TARGET_DIR .
make
make install



cd $BUILD_DIR/pidgin-libnotify*
./autogen
./configure --prefix=$DESTDIR
make
make install


# make install DESTDIR=$DESTDIR/screenshot_tmp
# rsync -avI $TARGET_DIR/screenshot_tmp$TARGET_DIR/* $TARGET_DIR/ --remove-source-files
# rsync -avI $TARGET_DIR/screenshot_tmp/var${BUILD_DIR#/usr}/* $TARGET_DIR/ --remove-source-files

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
