# Docker 镜像优化说明

## 镜像大小对比

| 版本 | 磁盘大小 | 压缩大小 | 优化幅度 | 说明 |
|------|---------|---------|---------|------|
| 原始版本 (gdal:0612) | 1.29 GB | 352 MB | - | 使用 JDK + graphviz/gv |
| **优化版本 (Dockerfile)** | **1.11 GB** | **285 MB** | **-67 MB (-19%)** | 使用 JRE，保留 graphviz/gv ⭐ |
| 开发版本 (Dockerfile.jdk) | 1.27 GB | 347 MB | -5 MB (-1.4%) | 保留 JDK 支持编译 |

## 主要优化项

### 1. 使用 JRE 替代 JDK (-93 MB)
**Dockerfile（推荐）：**
- 安装 `temurin-8-jre` 而不是 `temurin-8-jdk`
- JRE 105MB vs JDK 198MB
- **适用场景**：运行时环境，不需要编译 Java 代码

**Dockerfile.jdk（开发用）：**
- 保留 JDK 但删除开发组件：
  - 删除 `src.zip`（51 MB）
  - 删除 `sample` 目录（1.8 MB）
  - 删除 `man` 文档（2 MB）
- **适用场景**：需要在容器内编译 Java 代码

### 2. 保留 graphviz 和 gv 包
- 用户需要使用这两个工具
- 占用约 30+ MB，但为必需组件

### 3. 清理构建工具
- 安装 JDK/JRE 后立即清理 `curl` 和 `gnupg`
- 使用 `apt-get purge -y --auto-remove` 彻底删除
- 节省约 10 MB

### 4. 优化 Python 包
- 删除运行时不需要的 `pip`、`setuptools`、`wheel`（~11 MB）
- 清理 `__pycache__` 目录
- **注意**：不能删除 .py 源文件，Python 包依赖源文件运行

### 5. 设置必要的环境变量
- `ENV PROJ_LIB="/usr/share/proj"` - 修复 PROJ 数据库访问
- `ENV GDAL_DATA="/usr/share/gdal"` - 设置 GDAL 数据目录
- **重要**：这些环境变量对 OSR 空间参考系统至关重要

## 问题修复

### 问题1: java.lang.UnsatisfiedLinkError for OSR
**症状：** `import org.gdal.osr.SpatialReference` 运行时报错
```
java.lang.UnsatisfiedLinkError: org.gdal.osr.osrJNI.new_SpatialReference_SWIG_1()J
```

**原因：** JNI 库（libgdalalljni.so）存在且包含 OSR 符号，但 PROJ 找不到其数据库文件 `proj.db`

**解决方案：** 添加环境变量
```dockerfile
ENV PROJ_LIB="/usr/share/proj"
ENV GDAL_DATA="/usr/share/gdal"
```

### 问题2: graphviz 和 gv 缺失
**症状：** 容器中找不到 `dot` 和 `gv` 命令

**原因：** 优化时误删了这两个包

**解决方案：** 在 apt-get install 中添加
```dockerfile
RUN apt-get install -y --no-install-recommends \
    graphviz \
    gv \
    ...
```

## 使用建议

### 生产环境（推荐 Dockerfile）
```bash
# 构建运行时镜像（最小体积）
docker build -f Dockerfile -t gdal:runtime .

# 运行预编译的 Java 应用
docker run -v ./app.jar:/app/app.jar gdal:runtime java -jar /app/app.jar

# 运行 Python 脚本
docker run -v ./script.py:/app/script.py gdal:runtime python3.12 /app/script.py
```

### 开发环境（使用 Dockerfile.jdk）
```bash
# 构建开发镜像（包含 javac）
docker build -f Dockerfile.jdk -t gdal:dev .

# 在容器内编译 Java 代码
docker run -v ./src:/app gdal:dev bash -c "
  cd /app &&
  javac -cp /usr/share/java/gdal-3.10.3.jar *.java &&
  java -cp .:/usr/share/java/gdal-3.10.3.jar Main
"
```

## 测试验证

所有优化版本都经过以下测试：

✅ **Java GDAL 测试**
- 加载 189 个 GDAL 驱动
- JNI 库正常工作
- 版本：GDAL 3.10.3

✅ **Java OSR 测试**
- `new SpatialReference()` 成功
- `ImportFromEPSG(4326)` 成功
- `ExportToWkt()` 正常输出 WKT 格式

✅ **Python GDAL 测试**  
- osgeo.gdal、osgeo.ogr 和 osgeo.osr 正常导入
- 所有科学计算包可用（pandas, numpy, scipy, netCDF4, xarray）
- Python 3.12 环境正常

✅ **工具测试**
- graphviz: `dot` 命令可用
- gv: `gv` 命令可用

## 构建命令

```bash
# 优化版（JRE，最小体积，推荐）
docker build --no-cache -f Dockerfile -t gdal:final .

# 开发版（JDK，支持编译）
docker build --no-cache -f Dockerfile.jdk -t gdal:dev .
```

## 完整测试用例

```bash
# 测试 Java GDAL + OSR
docker run --rm -v ./TestOSR.java:/test/TestOSR.java gdal:dev bash -c "
  cd /test &&
  javac -cp /usr/share/java/gdal-3.10.3.jar TestOSR.java &&
  java -cp .:/usr/share/java/gdal-3.10.3.jar TestOSR
"

# 测试 Python
docker run --rm gdal:final python3.12 -c "
from osgeo import gdal, osr
print(f'GDAL {gdal.VersionInfo()}, OSR working')
"
```

