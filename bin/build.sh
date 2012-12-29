#!/bin/bash -x
PREFIX=$PWD
CONFIG=$PREFIX/cosm_proxy.conf

##TODO: add Android NDK wrapping

SRC=${SRC:-$PWD/src}

rm -rf ${SRC}
mkdir -p ${SRC} && cd ${SRC}

PCRE_VER=${PCRE_VER:-8.32}
PCRE_SRC=${SRC}/pcre

LUA_SRC=${SRC}/lua
LUA_VER=${LUA_VER-5.1.5}

NGX_SRC=${SRC}/nginx
NGX_TAG=${NGX_TAG:-release-1.2.6}

NGX_KIT_TAG=${NGX_KIT_TAG:-v0.2.17}
NGX_LUA_TAG=${LUA_NGX_TAG:-v0.7.11}

#git clone https://github.com/LuaDist/lua \
#  && cd $LUA_SRC && git checkout $LUA_TAG -b build \
#  && cmake

curl -L http://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VER}/pcre-${PCRE_VER}.tar.bz2 \
  | (mkdir $PCRE_SRC; tar xj -C $PCRE_SRC) \
  #&& (cd $PCRE_SRC/pcre-${PCRE_VER} && ./configure --prefix=$PREFIX) \
  #&& make -C $PCRE_SRC/pcre-${PCRE_VER} -j3 \
  #&& make -C $PCRE_SRC/pcre-${PCRE_VER} -j3 install


curl http://www.lua.org/ftp/lua-${LUA_VER}.tar.gz \
  | (mkdir $LUA_SRC; tar xz -C $LUA_SRC) \
  && make -C $LUA_SRC/lua-${LUA_VER} -j3 generic \
  && make -C $LUA_SRC/lua-${LUA_VER} -j3 install INSTALL_TOP=${PREFIX}

export LUA_LIB=${PREFIX}/lib
export LUA_INC=${PREFIX}/include

git clone https://github.com/git-mirror/nginx \
  && cd $NGX_SRC && git checkout $NGX_TAG -b build \
  && (git clone https://github.com/simpl/ngx_devel_kit \
    && cd ngx_devel_kit && git checkout $NGX_KIT_TAG -b build) \
  && (git clone https://github.com/chaoslawful/lua-nginx-module \
    && cd lua-nginx-module && git checkout $NGX_LUA_TAG -b build) \
  && ./auto/configure \
        --prefix=$PREFIX \
        --conf-path=$CONFIG \
        --sbin-path=$PREFIX/bin/nginx \
        --http-log-path=$PREFIX/log/access.log \
        --error-log-path=$PREFIX/log/error.log \
        --pid-path=$PREFIX/run/.pid \
        --lock-path=$PREFIX/run/.lock \
        --http-client-body-temp-path=$PREFIX/tmp/body \
        --http-proxy-temp-path=$PREFIX/tmp/proxy \
        --with-pcre=$PCRE_SRC/pcre-${PCRE_VER} \
        --with-ipv6 \
        --with-http_ssl_module \
        --add-module=ngx_devel_kit \
        --add-module=lua-nginx-module \
        --without-http_fastcgi_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --without-http_charset_module \
        --without-http_upstream_ip_hash_module

if [ $? -eq 0 ]
then
  [ `uname` = Darwin ] && \
    sed "s/\-arch\ x86_64\ \-arch\ i386/-arch `uname -m`/" objs/Makefile \
      > objs/Makefile.new && mv objs/Makefile.new objs/Makefile

  make -C $NGX_SRC -j3 \
    && cp objs/nginx $PREFIX/bin/ \
    && mkdir -p $PREFIX/{log,run,tmp}
fi
