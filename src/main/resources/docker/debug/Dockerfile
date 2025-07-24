# 第一阶段：构建环境
FROM registry-1.docker.io/flyisnow/gdal:v0724 AS builder

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 下载并构建 jemalloc
RUN wget https://github.com/jemalloc/jemalloc/archive/refs/tags/5.3.0.tar.gz && \
    tar zxvf 5.3.0.tar.gz && \
    cd jemalloc-5.3.0/ && \
    ./autogen.sh && \
    ./configure --enable-prof --prefix=/usr/local/jemalloc && \
    make -j$(nproc) && \
    make install DESTDIR=/tmp/jemalloc-install && \
    cd .. && \
    rm -rf jemalloc-5.3.0 5.3.0.tar.gz

# 第二阶段：最终镜像
FROM registry-1.docker.io/flyisnow/gdal:v0724

# 安装中文字体和语言包
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        graphviz gv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置中文环境
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 从构建阶段复制 jemalloc
COPY --from=builder /tmp/jemalloc-install/usr/local/jemalloc /usr/local/jemalloc

# 配置动态链接库路径
ENV LD_LIBRARY_PATH=/usr/local/jemalloc/lib:$LD_LIBRARY_PATH \
    PATH=/usr/local/jemalloc/bin:$PATH

# 验证安装
RUN echo "/usr/local/jemalloc/lib" > /etc/ld.so.conf.d/jemalloc.conf && \
    ldconfig && \
    jemalloc-config --version