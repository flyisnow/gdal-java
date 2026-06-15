FROM flyisnow/gdal_python:3.10.3_20260605 AS gdal_source

FROM flyisnow/gdal_python:3.10.3_20260605 AS gdal_runtime

# Collect GDAL/JNI runtime artifacts plus transitive shared-library dependencies.
RUN set -eux; \
  libs="/usr/lib/x86_64-linux-gnu/libgdal.so.36 /usr/lib/x86_64-linux-gnu/jni/libgdalalljni.so"; \
  changed=1; \
  while [ "$changed" -eq 1 ]; do \
    changed=0; \
    for f in $libs; do \
      for dep in $(ldd "$f" | awk '/=> \/[^ ]+/ {print $3}'); do \
        dep_real="$(readlink -f "$dep")"; \
        for candidate in "$dep" "$dep_real"; do \
          case " $libs " in \
            *" $candidate "*) ;; \
            *) libs="$libs $candidate"; changed=1 ;; \
          esac; \
        done; \
      done; \
    done; \
  done; \
  mkdir -p /opt/gdal-runtime/libs \
           /opt/gdal-runtime/jni \
           /opt/gdal-runtime/java; \
  for f in $libs; do \
    case "$f" in \
      */jni/*) cp -a "$f" /opt/gdal-runtime/jni/ ;; \
      *) cp -a "$f" /opt/gdal-runtime/libs/ ;; \
    esac; \
  done; \
  cp -a /usr/share/java/gdal-3.10.3.jar /opt/gdal-runtime/java/

FROM ubuntu:24.04 AS py_builder

ENV DEBIAN_FRONTEND=noninteractive

# Build GDAL Python bindings in venv.
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    build-essential && \
  rm -rf /var/lib/apt/lists/*

COPY --from=gdal_source /usr/bin/gdal-config /usr/bin/gdal-config
COPY --from=gdal_source /usr/include/ /usr/include/
COPY --from=gdal_source /usr/lib/x86_64-linux-gnu/libgdal.so /usr/lib/x86_64-linux-gnu/libgdal.so
COPY --from=gdal_source /usr/lib/x86_64-linux-gnu/libgdal.so.36 /usr/lib/x86_64-linux-gnu/libgdal.so.36
COPY --from=gdal_source /usr/lib/x86_64-linux-gnu/libgdal.so.36.3.10.3 /usr/lib/x86_64-linux-gnu/libgdal.so.36.3.10.3

RUN \
  python3.12 -m venv /opt/py312 && \
  /opt/py312/bin/python -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
  /opt/py312/bin/python -m pip install --no-cache-dir \
    GDAL==3.10.3 \
    pandas \
    scipy \
    netCDF4 \
    xarray && \
  find /opt/py312 -type d -name __pycache__ -prune -exec rm -rf {} + && \
  rm -rf /opt/py312/lib/python3.12/site-packages/pip \
         /opt/py312/lib/python3.12/site-packages/setuptools \
         /opt/py312/lib/python3.12/site-packages/wheel \
         /var/lib/apt/lists/*

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
# Install Python runtime and JRE8 (Temurin 8).
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    graphviz \
    gv \
    python3.12 \
    python3.12-venv && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb noble main" > /etc/apt/sources.list.d/adoptium.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    temurin-8-jre && \
  apt-get purge -y --auto-remove curl gnupg && \
  rm -rf /var/lib/apt/lists/*

COPY --from=py_builder /opt/py312 /opt/py312
COPY --from=gdal_runtime /opt/gdal-runtime/libs/ /usr/lib/x86_64-linux-gnu/
COPY --from=gdal_runtime /opt/gdal-runtime/jni/ /usr/lib/x86_64-linux-gnu/jni/
COPY --from=gdal_runtime /opt/gdal-runtime/java/ /usr/share/java/
COPY --from=gdal_source /usr/bin/gdal* /usr/bin/
COPY --from=gdal_source /usr/bin/ogr* /usr/bin/
COPY --from=gdal_source /usr/share/gdal/ /usr/share/gdal/
COPY --from=gdal_source /usr/share/proj/ /usr/share/proj/

RUN ldconfig && \
  rm -rf /usr/lib/jvm/temurin-8-jre-amd64/man \
         /usr/lib/jvm/temurin-8-jre-amd64/sample 2>/dev/null || true

ENV PATH="/opt/py312/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu/jni:${LD_LIBRARY_PATH}"
ENV PROJ_LIB="/usr/share/proj"
ENV GDAL_DATA="/usr/share/gdal"

