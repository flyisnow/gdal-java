#!/bin/bash
# GDAL Java Docker 镜像构建脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}    GDAL Java Docker 镜像构建脚本${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# 显示菜单
echo "请选择要构建的镜像版本："
echo ""
echo "  1) 基础版 JRE  (推荐，1.24 GB)"
echo "  2) 基础版 JDK  (开发用，1.4 GB)"
echo "  3) 完整版 JRE  (含气象包，1.57 GB)"
echo "  4) 完整版 JDK  (含气象包+开发，1.73 GB)"
echo "  5) 构建全部版本"
echo "  0) 退出"
echo ""
read -p "请输入选项 [0-5]: " choice

case $choice in
    1)
        echo -e "\n${YELLOW}构建: 基础版 JRE${NC}"
        docker build -t gdal-java:base -f Dockerfile .
        echo -e "${GREEN}✓ 构建完成: gdal-java:base${NC}"
        ;;
    2)
        echo -e "\n${YELLOW}构建: 基础版 JDK${NC}"
        docker build -t gdal-java:base-jdk -f Dockerfile.jdk .
        echo -e "${GREEN}✓ 构建完成: gdal-java:base-jdk${NC}"
        ;;
    3)
        echo -e "\n${YELLOW}构建: 完整版 JRE${NC}"
        docker build -t gdal-java:full -f Dockerfile.full .
        echo -e "${GREEN}✓ 构建完成: gdal-java:full${NC}"
        ;;
    4)
        echo -e "\n${YELLOW}构建: 完整版 JDK${NC}"
        docker build -t gdal-java:full-jdk -f Dockerfile.jdk.full .
        echo -e "${GREEN}✓ 构建完成: gdal-java:full-jdk${NC}"
        ;;
    5)
        echo -e "\n${YELLOW}构建全部版本...${NC}\n"

        echo -e "${YELLOW}[1/4] 构建: 基础版 JRE${NC}"
        docker build -t gdal-java:base -f Dockerfile .
        echo -e "${GREEN}✓ 完成${NC}\n"

        echo -e "${YELLOW}[2/4] 构建: 基础版 JDK${NC}"
        docker build -t gdal-java:base-jdk -f Dockerfile.jdk .
        echo -e "${GREEN}✓ 完成${NC}\n"

        echo -e "${YELLOW}[3/4] 构建: 完整版 JRE${NC}"
        docker build -t gdal-java:full -f Dockerfile.full .
        echo -e "${GREEN}✓ 完成${NC}\n"

        echo -e "${YELLOW}[4/4] 构建: 完整版 JDK${NC}"
        docker build -t gdal-java:full-jdk -f Dockerfile.jdk.full .
        echo -e "${GREEN}✓ 完成${NC}\n"

        echo -e "${GREEN}✓ 全部构建完成！${NC}"
        ;;
    0)
        echo "退出"
        exit 0
        ;;
    *)
        echo -e "${RED}无效的选项${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}==================================================${NC}"
echo "镜像列表："
docker images | grep gdal-java || echo "未找到镜像"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo "使用示例："
echo "  docker run --rm gdal-java:base python3 -c 'from osgeo import gdal; print(gdal.__version__)'"
echo "  docker run --rm gdal-java:base gdalinfo --version"
echo ""
