FROM registry-1.docker.io/flyisnow/gdal-ubuntu-full:v0723
# FROM registry-1.docker.io/flyisnow/gdal-ubuntu-full:3.10-compress
## 删除proj中的其它国家的座标
RUN cd /usr/local/share/proj && \
    rm -f at_* ar_* si_* cz_* mx_* br_* au_* eur_* fi_* hu_* lv_* se_* nl_* is_* pt_*  && \
    rm -f us_* ca_* de_* fr_* uk_* es_* be_* dk_* jp_* za_* nz_* no_* sk_*  nc_*

# 安装中文字体和语言包
RUN apt-get update && \
    apt-get install -y \
    locales \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    ttf-wqy-zenhei \
    language-pack-zh-hans \
    && rm -rf /var/lib/apt/lists/*

# 生成并设置中文语言环境
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8

# 设置默认语言环境 置时区和语言环境
ENV LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8  TZ=Asia/Shanghai LANG=C.UTF-8 LC_ALL=C.UTF-8



    