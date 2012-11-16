#!/bin/sh -x
PREFIX=$PWD
CONFIG=$PREFIX/cosm_proxy.conf

##TODO: add Android NDK wrapping

git clone --depth=1 https://github.com/git-mirror/nginx src \
  && cd src && git checkout stable-1.2 \
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
        --with-ipv6 \
        --with-http_ssl_module \
        --without-http_fastcgi_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --without-http_charset_module \
        --without-http_upstream_ip_hash_module \
        --without-http_rewrite_module \
  && make -j3 && cp objs/nginx $PREFIX/bin/ && mkdir -p $PREFIX/{log,run,tmp}
