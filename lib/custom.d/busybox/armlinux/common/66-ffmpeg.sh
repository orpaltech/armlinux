#
# Install ffmpeg packages
#

MP3LAME_VERSION=3.100
MP3LAME_TAR_FILE="lame-${MP3LAME_VERSION}.tar.gz"
MP3LAME_TAR_URL="https://downloads.sourceforge.net/project/lame/lame/3.100/${MP3LAME_TAR_FILE}"
MP3LAME_BASE_DIR=${EXTRADIR}/libmp3lame
MP3LAME_SRC_DIR=${MP3LAME_BASE_DIR}/${MP3LAME_VERSION}
MP3LAME_BUILD_DIR=${MP3LAME_SRC_DIR}/${BB_BUILD_OUT}


FFMPEG_REPO_URL="https://git.ffmpeg.org/ffmpeg.git"
FFMPEG_VERSION=7.1.1
FFMPEG_BRANCH=master
FFMPEG_TAG="n${FFMPEG_VERSION}"
FFMPEG_SRC_DIR=${EXTRADIR}/ffmpeg
FFMPEG_BUILD_DIR=${FFMPEG_SRC_DIR}/${BB_BUILD_OUT}
FFMPEG_ENABLE_MP3LAME=yes


SOURCE_NAME=$(basename ${BASH_SOURCE[0]})


#
# ############ helper functions ##############
#

mp3lame_install()
{
    mkdir -p ${MP3LAME_BASE_DIR}

    if [ ! -d ${MP3LAME_SRC_DIR} ] || [ "${SND_FORCE_UPDATE}" = yes ] ; then
        echo "Download mp3lame ..."

        rm -rf ${MP3LAME_SRC_DIR}
        mkdir -p ${MP3LAME_SRC_DIR}

        local tar_path="${MP3LAME_BASE_DIR}/${MP3LAME_TAR_FILE}"
        [ ! -f ${tar_path} ] && wget -O ${tar_path} ${MP3LAME_TAR_URL}
        tar -xvf ${tar_path} --strip-components=1 -C ${MP3LAME_SRC_DIR}
        rm -f ${tar_path}

        echo "Done."
    fi

    if [ "${SND_FORCE_REBUILD}" = yes ] ; then
        rm -rf ${MP3LAME_BUILD_DIR}
    fi

    mkdir -p ${MP3LAME_BUILD_DIR}
    cd ${MP3LAME_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure mp3lame ..."

    PKG_CONFIG=${BB_PKG_CONFIG} \
    CC=${BB_GCC} CXX=${BB_CXX} NM=${BB_NM} OBJDUMP=${BB_OBJDUMP} STRIP=${BB_STRIP} RANLIB=${BB_RANLIB} AR=${BB_AR} \
    MAKEINFO=/bin/true \
        ../configure --host=${BB_PLATFORM} \
                --srcdir=${MP3LAME_SRC_DIR} \
                --prefix=/usr \
		--enable-shared --disable-static \
		--disable-decoder --disable-frontend

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make mp3lame ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy mp3lame to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."

}

ffmpeg_install()
{
    PKG_FORCE_CLEAN=${SND_FORCE_REBUILD} \
	update_src_pkg "ffmpeg" \
                    $FFMPEG_VERSION \
                    $FFMPEG_SRC_DIR \
                    $FFMPEG_REPO_URL \
                    $FFMPEG_BRANCH \
                    $FFMPEG_TAG

    if [ "${SND_FORCE_REBUILD}" = yes ] ; then
	rm -rf ${FFMPEG_BUILD_DIR}
    fi

    mkdir -p ${FFMPEG_BUILD_DIR}
    cd ${FFMPEG_BUILD_DIR}/

    echo "${SOURCE_NAME}: Configure ffmpeg ..."

    local decoders=(aac ac3_fixed ac3 alac flac mp3 pcm_s16le pcm_s24le pcm_s32le sbc vorbis wmalossless wmav1 wmav2)
    local encoders=(aac ac3_fixed ac3 alac flac pcm_s16le pcm_s24le pcm_s32le sbc vorbis wmav1 wmav2)
    local filters=(aresample)
    local muxers=(ac3 adts amr asf asf_stream flac mp3 fifo null ogg pcm_s16le pcm_s24le pcm_s32le pcm_s8 rtp rtsp sbc wav)
    local demuxers=(aac amr ac3 flac mp3 ogg pcm_s16le pcm_s24le pcm_s32le pcm_s8 rtp rtsp sbc wav)
    local parsers=(aac aac_latm ac3 amr flac mpegaudio sbc vorbis)

    local ffmpeg_args="--disable-hwaccels --disable-bsfs"
    ffmpeg_args="${ffmpeg_args} --disable-filters"
    for i in "${filters[@]}"; do
	ffmpeg_args="${ffmpeg_args} --enable-filter=${i}"
    done

    ffmpeg_args="${ffmpeg_args} --disable-parsers"
    for i in "${parsers[@]}"; do
        ffmpeg_args="${ffmpeg_args} --enable-parser=${i}"
    done

    ffmpeg_args="${ffmpeg_args} --disable-muxers"
    for i in "${muxers[@]}"; do
        ffmpeg_args="${ffmpeg_args} --enable-muxer=${i}"
    done

    ffmpeg_args="${ffmpeg_args} --disable-demuxers"
    for i in "${demuxers[@]}"; do
        ffmpeg_args="${ffmpeg_args} --enable-demuxer=${i}"
    done

    ffmpeg_args="${ffmpeg_args} --disable-decoders"
    for i in "${decoders[@]}"; do
        ffmpeg_args="${ffmpeg_args} --enable-decoder=${i}"
    done

    ffmpeg_args="${ffmpeg_args} --disable-encoders"
    for i in "${encoders[@]}"; do
        ffmpeg_args="${ffmpeg_args} --enable-encoder=${i}"
    done

    if [ "${FFMPEG_ENABLE_MP3LAME}" = yes ]; then
	ffmpeg_args="${ffmpeg_args} --enable-encoder=libmp3lame"
	ffmpeg_args="${ffmpeg_args} --enable-libmp3lame"
    fi

    MAKEINFO=/bin/true \
	../configure \
		--pkg-config=${BB_PKG_CONFIG} \
		--arch=${SOC_ARCH} \
		--target-os=linux \
		--cross-prefix=${BB_CROSS_COMPILE} \
		--enable-cross-compile \
		--prefix=/usr \
		--extra-cflags="-I${R}/usr/include" \
		--extra-ldflags="-lmp3lame -lm -L${R}/usr/lib" \
		--enable-shared	--enable-gpl --disable-doc --disable-static \
		${ffmpeg_args}

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Make ffmpeg ..."

    chrt -i 0 make -s -j${HOST_CPU_CORES}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
    echo "${SOURCE_NAME}: Deploy ffmpeg to ${R} ..."

    make  install DESTDIR=${R}
    [ $? -eq 0 ] || exit $?;

    echo "${SOURCE_NAME}: Done."
}


#
# ############ install packages ##############
#

if [ "${ENABLE_SOUND}" = yes ] ; then

    [[ ${CLEAN} =~ (^|,)sound(,|$) ]] && SND_FORCE_REBUILD=yes
    set -x
    SND_FORCE_REBUILD=${SND_FORCE_REBUILD:="no"}
    set +x

    if [ "${FFMPEG_ENABLE_MP3LAME}" = yes ]; then

	mp3lame_install
    fi

    ffmpeg_install

    echo "${SOURCE_NAME}: ffmpeg packages installed."
fi
