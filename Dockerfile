FROM alpine:3.5

EXPOSE 80 443

ARG APK_CACHE_IP=172.17.0.1
ARG APK_CACHE_DOMAIN='dl-cdn.alpinelinux.org nginx.org'

ARG RUN_DEPS='pcre openssl geoip'
ARG BUILD_DEPS='pcre-dev openssl-dev geoip-dev zlib-dev g++ make coreutils tar'

ARG NGINX_VERSION=1.11.5
ARG NGINX_URL='http://nginx.org/download'
ARG NGINX_TMP=/tmp/nginx
ENV NGINX_CONF=/etc/nginx

ARG NCHAN_VERSION=1.1.7
ARG NCHAN_URL='http://api.github.com/repos/slact/nchan'
ARG NCHAN_TMP=nchan

RUN nc -z $APK_CACHE_IP 80 && echo $APK_CACHE_IP $APK_CACHE_DOMAIN >>/etc/hosts \
 ; apk --update add --no-cache $RUN_DEPS $BUILD_DEPS \
   && mkdir -p $NGINX_TMP && cd $NGINX_TMP && mkdir $NCHAN_TMP \
   && NGINX_LATEST=$(wget -qO- $NGINX_URL | egrep -o "[0-9]+\.[0-9]+\.[0-9]+" | sort -Vr | head -1) \
   && wget -qO- $NGINX_URL/nginx-${NGINX_VERSION:=$NGINX_LATEST}.tar.gz | tar xz --strip-components=1 \
   && NCHAN_LATEST=$(wget -qO- $NCHAN_URL/tags | egrep -o "[0-9]+\.[0-9]+\.[0-9]+" | sort -Vr | head -1) \
   && wget -qO- $NCHAN_URL/tarball/v${NCHAN_VERSION:=$NCHAN_LATEST} | tar xz --strip-components=1 -C $NCHAN_TMP \
   && ./configure \
     --with-ld-opt="-Wl,-s" \
     --prefix=/var/lib/nginx \
     --sbin-path=/usr/sbin/nginx \
     --conf-path=$NGINX_CONF/nginx.conf \
     --pid-path=/run/nginx.pid \
     --lock-path=/run/nginx.lock \
     --error-log-path=/dev/stderr \
     --http-log-path=/dev/stdout \
     --with-ipv6 \
     --with-pcre \
     --with-http_ssl_module \
     --with-http_stub_status_module \
     --with-http_gzip_static_module \
     --with-http_v2_module \
     --with-http_auth_request_module \
     --with-stream \
     --with-stream_ssl_module \
     --with-mail \
     --with-mail_ssl_module \
     --with-http_realip_module \
     --with-http_geoip_module \
     --without-http_scgi_module \
     --add-module=$NCHAN_TMP \
   && make -j$(nproc) install && nginx -V \
   && apk del $BUILD_DEPS && rm -rf /var/cache/apk/* $NGINX_TMP  \
   && addgroup -S nginx \
   && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx 

WORKDIR $NGINX_CONF


CMD ["nginx","-g","daemon off;"]

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf

