# ffmpeg - http://ffmpeg.org/download.html
# based on image from
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
# Fork of original Unified Streaming setup
# Fixed for :
# 1) Multiarch X86/ARM64. USP live demo now runs on Macs as well
# 2) Git repos for x264 and x265, removed version options.
# 3) Updated Alpine version to 3.19
# 4) Todo:  Update FFMPEG to contemporary version (needs fixes in patches)
#
FROM    alpine:3.19

ENV     PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
        SRC=/usr/local

RUN     buildDeps="autoconf \
                   automake \
                   bash \
                   binutils \
                   bzip2 \
                   cmake \
                   curl \
                   coreutils \
                   g++ \
                   gcc \
                   git \
                   libtool \
                   make \
                   nasm \
                   openssl-dev \
                   tar \
                   yasm \
                   python3 \
                   pkgconfig \
                   zlib-dev" && \
        export MAKEFLAGS="-j$(($(grep -c ^processor /proc/cpuinfo) + 1))" && \
        apk add --update ${buildDeps} freetype-dev fontconfig-dev ttf-droid libgcc libstdc++ ca-certificates
RUN     DIR=$(mktemp -d) && cd ${DIR} && \
        echo "**** COMPILING x264 ****" && \
        git clone https://code.videolan.org/videolan/x264.git && \
 #       curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
 #       tar -jx --strip-components=1 && \
        cd x264 && \
        ./configure --prefix="${SRC}" --bindir="${SRC}/bin" --enable-pic --enable-shared --disable-cli && \
        make -j$(nproc) && \
        make install && \
        rm -rf ${DIR}
        # x265 http://www.videolan.org/developers/x265.html
 RUN    DIR=$(mktemp -d) && cd ${DIR} && \
        echo "**** COMPILING x265 ****" && \
        git clone https://bitbucket.org/multicoreware/x265_git.git && \
        cd x265_git && \
        cd build && cmake ../source && \
        make -j$(nproc) && \
        make install && \
        rm -rf ${DIR}

## ffmpeg source from github
# checkout working commit ca21cb1e36ccae2ee71d4299d477fa9284c1f551 from 12/01/2021
COPY    *.patch /root/
RUN     DIR=$(mktemp -d) && cd ${DIR} && \
        git clone https://github.com/FFmpeg/FFmpeg.git . && \
        git checkout --detach ca21cb1e36ccae2ee71d4299d477fa9284c1f551 && \
        cp /root/*.patch . && \
        git apply -v *.patch && \
        ./configure --prefix="${SRC}" \
        --extra-cflags="-I${SRC}/include" \
        --extra-ldflags="-L${SRC}/lib" \
        --bindir="${SRC}/bin" \
        --disable-doc \
        --disable-static \
        --enable-shared \
        --disable-ffplay \
        --extra-libs=-ldl \
        --enable-version3 \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libfontconfig \
        --enable-libfreetype \
        --enable-gpl \
        --enable-avresample \
        --enable-postproc \
        --enable-nonfree \
        --disable-debug \
        --enable-openssl && \
        make -j$(nproc) && \
        make install && \
        make distclean && \
        hash -r && \
        rm -rf ${DIR} && \
        cd && \
        apk del ${buildDeps} && \
        rm -rf /var/cache/apk/* /usr/local/include && \
        ffmpeg -buildconf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY entrypoint.py /usr/local/bin/entrypoint.py
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.py

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
