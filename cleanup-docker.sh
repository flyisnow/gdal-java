#!/bin/bash

# Docker磁盘清理脚本
# 用于清理Docker未使用的镜像、容器、缓存等资源

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的信息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示磁盘使用情况
show_disk_usage() {
    echo ""
    echo "=========================================="
    echo "磁盘使用情况"
    echo "=========================================="
    df -h | grep -E '(Filesystem|/workspaces|overlay)'
    echo ""
    echo "=========================================="
    echo "Docker磁盘占用"
    echo "=========================================="
    docker system df
    echo ""
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

Docker磁盘清理脚本

选项:
  -a, --all           清理所有未使用的资源（危险：会删除所有未使用的镜像）
  -s, --safe          安全模式（默认）：只清理悬空镜像和构建缓存
  -f, --force         强制清理，不询问确认
  -c, --cache-only    只清理构建缓存
  -i, --images-only   只清理未使用的镜像
  -h, --help          显示此帮助信息

示例:
  $0                  # 安全模式清理（默认）
  $0 -s               # 安全模式清理
  $0 -a               # 清理所有未使用资源
  $0 -a -f            # 强制清理所有未使用资源
  $0 -c               # 只清理构建缓存

EOF
}

# 清理函数
cleanup_safe() {
    info "开始安全清理（只清理悬空资源和构建缓存）..."

    # 清理停止的容器
    info "清理停止的容器..."
    docker container prune -f || warn "没有需要清理的容器"

    # 清理悬空镜像（dangling images）
    info "清理悬空镜像..."
    docker image prune -f || warn "没有悬空镜像需要清理"

    # 清理构建缓存
    info "清理构建缓存..."
    docker builder prune -f || warn "没有构建缓存需要清理"

    # 清理未使用的网络
    info "清理未使用的网络..."
    docker network prune -f || warn "没有未使用的网络"

    # 清理未使用的volumes
    info "清理未使用的卷..."
    docker volume prune -f || warn "没有未使用的卷"
}

cleanup_all() {
    info "开始深度清理（清理所有未使用的资源）..."

    # 清理所有未使用的资源
    info "执行 docker system prune --all --volumes..."
    docker system prune --all --volumes -f
}

cleanup_cache_only() {
    info "只清理构建缓存..."
    docker builder prune -f || warn "没有构建缓存需要清理"
}

cleanup_images_only() {
    info "清理未使用的镜像..."
    docker image prune -a -f || warn "没有未使用的镜像需要清理"
}

# 确认操作
confirm() {
    if [ "$FORCE" = true ]; then
        return 0
    fi

    read -p "确定要继续吗？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "操作已取消"
        exit 1
    fi
}

# 主函数
main() {
    # 默认参数
    MODE="safe"
    FORCE=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                MODE="all"
                shift
                ;;
            -s|--safe)
                MODE="safe"
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -c|--cache-only)
                MODE="cache"
                shift
                ;;
            -i|--images-only)
                MODE="images"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo ""
    info "Docker磁盘清理脚本"
    echo ""

    # 显示清理前状态
    info "清理前状态："
    show_disk_usage

    # 根据模式执行清理
    case $MODE in
        safe)
            warn "安全模式：将清理悬空镜像、停止的容器、构建缓存、未使用的网络和卷"
            confirm
            cleanup_safe
            ;;
        all)
            error "危险模式：将清理所有未使用的Docker资源（包括所有未使用的镜像）"
            confirm
            cleanup_all
            ;;
        cache)
            info "只清理构建缓存"
            confirm
            cleanup_cache_only
            ;;
        images)
            warn "将清理所有未使用的镜像"
            confirm
            cleanup_images_only
            ;;
    esac

    # 显示清理后状态
    info "清理完成！"
    info "清理后状态："
    show_disk_usage

    info "如需更彻底的清理，可以运行："
    echo "  $0 --all          # 清理所有未使用资源"
    echo "  docker system df  # 查看Docker磁盘使用情况"
}

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    error "Docker未运行或无权限访问"
    exit 1
fi

# 执行主函数
main "$@"
