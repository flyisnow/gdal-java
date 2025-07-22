FROM flyisnow/gdal:jdk8_v3

RUN apt update && apt install -y graphviz gv autoconf && cd / && wget https://github.com/jemalloc/jemalloc/archive/refs/tags/5.3.0.tar.gz \
  &&tar xf 5.3.0.tar.gz && cd jemalloc-5.3.0 \
&& ./autogen.sh \
&& ./configure --enable-prof \
&& make -j \
&& make install \
&& cd / \
&& rm -rf 5.3.0.tar.gz \
&& rm -rf jemalloc-5.3.0 
