FROM docker.io/imartemy1524/mpv:4.0

WORKDIR /tmp
# install python 3.10 to run python scripts
ENV PATH /usr/local/bin:$PATH
ENV LANG C.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install wget libssl-dev libncurses5-dev libsqlite3-dev libreadline-dev libtk8.6 libgdm-dev libdb4o-cil-dev libpcap-dev cmake gcc autoconf \
  automake \
  build-essential \
  cmake \
  nvidia-opencl-dev \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libmp3lame-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  meson \
  ninja-build \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev \
  nasm \
  libunistring-dev \
  libaom-dev \
  libx265-dev \
  libx264-dev \
  libnuma-dev \
  libfdk-aac-dev \
  libc6 \
  libc6-dev \
  unzip \
  libnuma1 -y
#RUN wget http://archive.ubuntu.com/ubuntu/pool/universe/d/db4o/libdb4o8.0-cil_8.0.184.15484+dfsg2-3_all.deb && apt install ./libdb4o8.0-cil_8.0.184.15484+dfsg2-3_all.deb -y
#RUN wget http://archive.ubuntu.com/ubuntu/pool/universe/d/db4o/libdb4o-cil-dev_8.0.184.15484+dfsg2-3_all.deb
#RUN apt install ./libdb4o-cil-dev_8.0.184.15484+dfsg2-3_all.deb -y
#region build python

# runtime dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libbluetooth-dev \
		tk-dev \
		uuid-dev \
	; \
	rm -rf /var/lib/apt/lists/*

ENV GPG_KEY A035C8C19219BA821ECEA86B64E628F8D684696D
ENV PYTHON_VERSION 3.10.13

RUN set -eux; \
	\
	wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
	wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"; \
	GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"; \
	gpg --batch --verify python.tar.xz.asc python.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" python.tar.xz.asc; \
	mkdir -p /usr/src/python; \
	tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
	rm python.tar.xz; \
	\
	cd /usr/src/python; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-lto \
		--with-system-expat \
		--without-ensurepip \
	; \
	nproc="$(nproc)"; \
	EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"; \
	LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"; \
	make -j "$nproc" \
		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
		"LDFLAGS=${LDFLAGS:-}" \
		"PROFILE_TASK=${PROFILE_TASK:-}" \
	; \
# https://github.com/docker-library/python/issues/784
# prevent accidental usage of a system installed libpython of the same version
	rm python; \
	make -j "$nproc" \
		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
		"LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
		"PROFILE_TASK=${PROFILE_TASK:-}" \
		python \
	; \
	make install; \
	\
# enable GDB to load debugging data: https://github.com/docker-library/python/pull/701
	bin="$(readlink -ve /usr/local/bin/python3)"; \
	dir="$(dirname "$bin")"; \
	mkdir -p "/usr/share/gdb/auto-load/$dir"; \
	cp -vL Tools/gdb/libpython.py "/usr/share/gdb/auto-load/$bin-gdb.py"; \
	\
	cd /; \
	rm -rf /usr/src/python; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
		\) -exec rm -rf '{}' + \
	; \
	\
	ldconfig; \
	\
	python3 --version

RUN set -eux; \
	for src in idle3 pydoc3 python3 python3-config; do \
		dst="$(echo "$src" | tr -d 3)"; \
		[ -s "/usr/local/bin/$src" ]; \
		[ ! -e "/usr/local/bin/$dst" ]; \
		ln -svT "$src" "/usr/local/bin/$dst"; \
	done

RUN python -m ensurepip --upgrade
RUN python -m pip install --upgrade pip


RUN git clone --depth=1 https://gitlab.com/AOMediaCodec/SVT-AV1.git
RUN wget http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 && tar xfj nasm-2.14.02.tar.bz2
RUN cd nasm-2.14.02/ && ./configure --prefix=/usr/local/ && make && make install
RUN cd SVT-AV1 && cd Build && cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && make -j $(nproc) && make install



RUN mkdir -p ~/ffmpeg_sources ~/bin && \
  cd ~/ffmpeg_sources && \
  wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
  tar xjvf ffmpeg-snapshot.tar.bz2 && \
  cd ffmpeg && \
  PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
    --prefix="$HOME/ffmpeg_build" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I$HOME/ffmpeg_build/include" \
    --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --bindir="$HOME/bin" \
    --enable-gpl \
    --enable-gnutls \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree && \
  PATH="$HOME/bin:$PATH" make -j $CPUS && \
  make install && \
  hash -r

# install ffmpeg-nvidia adapter
RUN mkdir ~/nv && cd ~/nv && \
  git clone https://github.com/FFmpeg/nv-codec-headers.git && \
  cd nv-codec-headers && make install

# compile ffmpeg with cuda
RUN cd ~/nv && \
  git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/ && \
  cd ffmpeg && \
  ./configure \
    --enable-nonfree \
    --enable-cuda-nvcc \
    --enable-libnpp \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64 \
    --disable-static \
    --enable-libsvtav1 \
    --enable-gnutls \
    --enable-shared && \
  make -j $CPUS && \
  make install


COPY ./config /root/.config/mpv
WORKDIR /home
COPY ./run.py /home/run.py
RUN chmod +x /home/run.py
RUN ln /home/run.py /usr/local/bin/anime4k -s

RUN mkdir /home/out



#RUN git clone --depth=1 https://code.videolan.org/videolan/dav1d.git && \
#    cd dav1d && \
#    mkdir build && cd build && \
#    ~/.local/bin/meson .. && \
#    ninja && ninja install
#
#RUN git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
#RUN apt-get install build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev -y
#RUN apt install dav1d libx264-dev libx265-dev libnuma-dev libvpx-dev libfdk-aac-dev libopus-dev libaom-dev libass-dev libvorbis-dev libvpx-dev libx265-dev libx264-dev -y
#RUN wget http://archive.ubuntu.com/ubuntu/pool/main/l/lame/libmp3lame0_3.100-3build2_amd64.deb && apt install ./libmp3lame0_3.100-3build2_amd64.deb -y
#RUN #wget
#RUN apt install libmp3lame-dev -y
#
#RUN cd ffmpeg && ./configure --enable-nonfree --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --disable-static --enable-shared --enable-libsvtav1 --enable-libdav1d --enable-nonfree  --enable-libx265 --enable-libx264 --enable-libmp3lame --enable-libvorbis --enable-libaom --enable-gpl
#RUN cd ffmpeg && make -j 32
#RUN cd ffmpeg && make install
#RUN ln -s /home/ffmpeg/ffmpeg /usr/bin/ffmpeg
ENTRYPOINT ["anime4k"]


