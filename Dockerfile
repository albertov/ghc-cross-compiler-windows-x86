FROM avalverde/cross-compiler-windows-x86

WORKDIR /tmp

ENV HOST_TRIPLE=i686-w64-mingw32 \
    WINDRES=/usr/src/mxe/usr/bin/${CROSS_TRIPLE}-windres \
    GHC_VERSION=8.0.1 \
    STACK_RESOLVER=nightly-2016-07-01

RUN : "Install some deps" && apt-get install -y curl libgmp-dev

RUN : "tweak cross-compiling env" \
 && for src in /usr/src/mxe/usr/bin/${CROSS_TRIPLE}-*; do \
    ln -s ${src} $(src=${src} bash -c 'echo ${src/${CROSS_TRIPLE}/${HOST_TRIPLE}}'); \
    done \
 && echo '#!/bin/bash' >> /usr/local/bin/windres \
 && echo 'exec $WINDRES -I/usr/src/mxe/usr/i686-w64-mingw32.static/include "$@"' >> /usr/local/bin/windres \
 && chmod +x /usr/local/bin/windres \
 && ln -s /usr/src/mxe/usr/${CROSS_TRIPLE}/include/shlobj.h \
         /usr/src/mxe/usr/${CROSS_TRIPLE}/include/Shlobj.h


ENV PATH /root/.local/bin:$PATH
RUN : "Download and unpack native GHC from binary distribution" \
 && curl -L https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-x86_64-deb8-linux.tar.xz | tar xvJ \
 && cd /tmp/ghc-${GHC_VERSION} \
 && : "Configure and install native GHC from binary distribution" \
 && ./configure --prefix=/usr/local \
 && make install \
 && : "Install native stack and build tools" \
 && curl -L https://www.stackage.org/stack/linux-x86_64 \
  | tar xz --wildcards --strip-components=1 -C /usr/local/bin '*/stack' \
 && stack install --resolver=${STACK_RESOLVER} happy alex \
 && rm -rf /tmp/ghc-${GHC_VERSION}*

RUN : "Build libgmp for mingw" && cd /usr/src/mxe && make gmp

ENV GHC_PREFIX /usr/src/mxe/usr

COPY ghc.patch build.mk /tmp/
RUN : "Download source to build cross-compiler" \
 && curl -L https://www.haskell.org/ghc/dist/${GHC_VERSION}/ghc-${GHC_VERSION}-src.tar.xz \
 | tar xvJ  \
 && cd /tmp/ghc-${GHC_VERSION} \
 && : "Apply patch for cross-compiling, copy configuration file and configure" \
 && patch -p1 -i /tmp/ghc.patch \
 && cp /tmp/build.mk mk/build.mk \
 && ./configure --target=${HOST_TRIPLE} \
                --prefix=${GHC_PREFIX} \
                --with-gmp-includes=/usr/src/mxe/usr/include \
                --with-gmp-libraries=/usr/src/mxe/usr/lib \
 && : "Build cross compiler" \
 && make -j8 \
 && make install
#&& rm -rf /tmp/ghc-${GHC_VERSION}

ENV PATH=/root/.cabal/bin:$PATH
RUN : "Install cabal" \
 && stack --resolver=${STACK_RESOLVER} \
          --local-bin-path=/usr/local/bin \
          install cabal-install
COPY cabal-wrapper ${GHC_PREFIX}/bin/${HOST_TRIPLE}-cabal
CMD ["bash"]
