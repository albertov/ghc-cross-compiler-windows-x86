FROM thewtex/cross-compiler-windows-x86

ENV HOST_TRIPLE i686-w64-mingw32

RUN for src in /usr/src/mxe/usr/bin/${CROSS_TRIPLE}-*; do \
     ln -s ${src} $(src=${src} bash -c 'echo ${src/${CROSS_TRIPLE}/${HOST_TRIPLE}}'); \
    done \
  && ln -s /usr/src/mxe/usr/bin/${CROSS_TRIPLE}-windres \
           /usr/src/mxe/usr/bin/windres

WORKDIR /tmp
RUN : Download and unpack native GHC from binary distribution \
  && wget http://downloads.haskell.org/~ghc/7.10.3/ghc-7.10.3b-x86_64-deb8-linux.tar.xz \
  && tar xvfJ ghc-7.10.3b-x86_64-deb8-linux.tar.xz

WORKDIR /tmp/ghc-7.10.3
RUN : Install native GHC from binary distribution \
  && ./configure --prefix=/usr/local \
  && make install \
  && rm -rf /tmp/*

WORKDIR /
ENV PATH /root/.local/bin:$PATH
RUN : Install native stack \
  && apt-get install -y curl libgmp-dev \
  && curl -L https://www.stackage.org/stack/linux-x86_64 \
   | tar xz --wildcards --strip-components=1 -C /usr/local/bin '*/stack'

CMD ["bash"]
