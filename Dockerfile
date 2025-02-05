FROM debian:10 AS builder

RUN apt-get update && apt-get install --yes --no-install-recommends \
    build-essential fakeroot devscripts equivs wget \
    libxml2-dev libusb-1.0-0-dev pkg-config \
    qtbase5-dev qttools5-dev-tools libavformat-dev libswscale-dev libnotify-dev

WORKDIR /build

RUN wget -qO- https://github.com/codestation/vitamtp/archive/refs/heads/master.tar.gz \
    | gunzip | tar xvf -
RUN wget -qO- https://github.com/codestation/qcma/archive/refs/heads/master.tar.gz \
    | gunzip | tar xvf -

# Build and install the vitamtp package
RUN cd /build/vitamtp-master \
    && ./autogen.sh \
    && ./configure --prefix=/usr \
    && make \
    && make install

# Fake the libvitamtp-dev package so qcma package passes the check while building
RUN echo "Package: libvitamtp-dev\nVersion: 2.5.9\nArchitecture: all" > libvitamtp-dev \
    && equivs-build libvitamtp-dev \
    && dpkg -i libvitamtp-dev_*.deb

# Build and install the qcma package
RUN cd /build/qcma-master \
    && lrelease -qt=qt5 common/resources/translations/*.ts \
    && qmake -qt=qt5 qcma.pro PREFIX="/usr" \
    && make \
    && make install

# Start from fresh with only the necessary runtime to reduce image size
FROM debian:10 AS packer

COPY --from=builder /usr/bin/qcma* /usr/bin/
COPY --from=builder /usr/lib/libvitamtp.so.5 /usr/lib/

# `libqt5widgets5` and `libqt5gui5` are only required by the GUI qcma,
# so if we're building a CLI docker image, we can remove those to save space
RUN apt-get update && apt-get install --yes --no-install-recommends \
    libxml2 libusb-1.0-0 \
    libqt5core5a libqt5network5 libqt5sql5 libqt5sql5-mysql libqt5widgets5 libqt5gui5 \
    libnotify-bin libavformat58 libswscale5 \
    && rm -rf /var/lib/apt/lists/*

# CMD ["/usr/bin/qcma_cli"]

# Copy some files to prepare for building the AppImage
WORKDIR /build
COPY --from=builder /build/qcma-master/gui/resources/images/qcma.png /build/qcma.png
COPY --from=builder /build/qcma-master/gui/resources/qcma.desktop /build/qcma.desktop

RUN apt-get update && apt-get install --yes --no-install-recommends \
    wget ca-certificates file desktop-file-utils libfuse2 qt5-default \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/linuxdeploy/linuxdeploy/releases/download/2.0.0-alpha-1-20241106/linuxdeploy-x86_64.AppImage
RUN wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/2.0.0-alpha-1-20250119/linuxdeploy-plugin-qt-x86_64.AppImage
RUN wget https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/1-alpha-20230713-1/linuxdeploy-plugin-appimage-x86_64.AppImage
RUN chmod +x linuxdeploy*.AppImage

RUN export APPIMAGE_EXTRACT_AND_RUN=1 \
    && ./linuxdeploy-x86_64.AppImage --appdir AppDir \
    --executable /usr/bin/qcma \
    --icon-file ./qcma.png \
    --desktop-file ./qcma.desktop \
    --plugin qt \
    --output appimage

FROM scratch AS export
COPY --from=packer /build/Qcma*.AppImage /