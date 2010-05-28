#!/bin/bash
#
# WARNING: This script removes the entire zfs subtree and will
# repopulate it using the requested OpenSolaris source release.
# This script should only be used when rebasing the TopGit tree
# against the latest release.  
#
trap die_int INT

RELEASE=$1
PROG=update-zfs.sh
REMOTE_DOC_FILE=man-sunosman-20090930.tar.bz2
REMOTE_DOC=http://dlc.sun.com/osol/man/downloads/current/${REMOTE_DOC_FILE}
REMOTE_SRC=ssh://anon@hg.opensolaris.org/hg/onnv/onnv-gate

die() {
	rm -Rf ${SRC}
	echo "${PROG}: $1" >&2
	exit 1
}

die_int() {
	die "Ctrl-C abort"
}

DST=`pwd`
if [ `basename $DST` != "scripts" ]; then
	die "Must be run from scripts directory"
fi

if [ ! "$RELEASE" ]; then
	die "Must specify ZFS release build, i.e. 'onnv_141'"
fi

SRC=`mktemp -d /tmp/onnv-gate.XXXXXXXXXX`
DST=`dirname $DST`

echo "----------------------------------------------------------------"
echo "Remote Source: ${REMOTE_SRC}"
echo "Remote Docs:   ${REMOTE_DOC}"
echo "Local Source:  ${SRC}"
echo "Local Dest:    ${DST}"
echo
echo "------------- Fetching OpenSolaris mercurial repo ----------------"
pushd ${SRC}
hg clone ${REMOTE_SRC} || die "Error cloning OpenSolaris mercurial repo"
pushd onnv-gate
hg update -C ${RELEASE} || die "Error unknown release ${RELEASE}"
popd
popd
echo "------------- Fetching OpenSolaris documentation ---------------"
wget -q ${REMOTE_DOC} -P ${SRC} ||
	die "Error 'wget ${REMOTE_DOC}'"

echo "------------- Unpacking OpenSolaris documentation --------------"
tar -xjf ${SRC}/${REMOTE_DOC_FILE} -C ${SRC} ||
	die "Error 'tar -xjf ${SRC}/${REMOTE_DOC_FILE} -C ${SRC}'"

SRC_LIB=${SRC}/onnv-gate/usr/src/lib
SRC_CMD=${SRC}/onnv-gate/usr/src/cmd
SRC_CM=${SRC}/onnv-gate/usr/src/common
SRC_UTS=${SRC}/onnv-gate/usr/src/uts
SRC_UCM=${SRC}/onnv-gate/usr/src/uts/common
SRC_ZLIB=${SRC}/onnv-gate/usr/src/uts/common/fs/zfs
SRC_MAN=${SRC}/man

DST_MOD=${DST}/module
DST_LIB=${DST}/lib
DST_CMD=${DST}/cmd
DST_MAN=${DST}/man

umask 022
rm -Rf ${DST}/zfs

echo "------------- Updating ZFS from OpenSolaris ${RELEASE} ---------------"
echo "* module/avl"
mkdir -p ${DST_MOD}/avl/include/sys/
cp ${SRC_CM}/avl/avl.c				${DST_MOD}/avl/
cp ${SRC_UCM}/sys/avl.h				${DST_MOD}/avl/include/sys/
cp ${SRC_UCM}/sys/avl_impl.h			${DST_MOD}/avl/include/sys/

echo "* module/nvpair"
mkdir -p ${DST_MOD}/nvpair/include/sys/
cp ${SRC_CM}/nvpair/nvpair.c			${DST_MOD}/nvpair/
cp ${SRC_CM}/nvpair/nvpair_alloc_fixed.c	${DST_MOD}/nvpair/
cp ${SRC_UCM}/sys/nvpair.h			${DST_MOD}/nvpair/include/sys/
cp ${SRC_UCM}/sys/nvpair_impl.h			${DST_MOD}/nvpair/include/sys/

echo "* module/unicode"
mkdir -p ${DST_MOD}/unicode/include/sys/
cp ${SRC_CM}/unicode/*.c			${DST_MOD}/unicode/
cp ${SRC_UCM}/sys/u8_textprep.h			${DST_MOD}/unicode/include/sys/
cp ${SRC_UCM}/sys/u8_textprep_data.h		${DST_MOD}/unicode/include/sys/

echo "* module/zcommon"
mkdir -p ${DST_MOD}/zcommon/include/sys/fs/
cp ${SRC_CM}/zfs/*.c				${DST_MOD}/zcommon/
cp ${SRC_CM}/zfs/*.h				${DST_MOD}/zcommon/include/
cp ${SRC_UCM}/sys/fs/zfs.h			${DST_MOD}/zcommon/include/sys/fs/

echo "* module/zfs"
mkdir -p ${DST_MOD}/zfs/include/sys/fm/fs/
cp ${SRC_UTS}/intel/zfs/spa_boot.c		${DST_MOD}/zfs/
cp ${SRC_ZLIB}/*.c				${DST_MOD}/zfs/
cp ${SRC_ZLIB}/sys/*.h				${DST_MOD}/zfs/include/sys/
cp ${SRC_UCM}/os/fm.c				${DST_MOD}/zfs/
cp ${SRC_UCM}/sys/fm/protocol.h			${DST_MOD}/zfs/include/sys/fm/
cp ${SRC_UCM}/sys/fm/util.h			${DST_MOD}/zfs/include/sys/fm/
cp ${SRC_UCM}/sys/fm/fs/zfs.h			${DST_MOD}/zfs/include/sys/fm/fs/
rm ${DST_MOD}/zfs/vdev_disk.c
rm ${DST_MOD}/zfs/zvol.c
rm ${DST_MOD}/zfs/include/sys/vdev_disk.h

echo "* lib/libavl"
# Full source available in 'module/avl'

echo "* lib/libnvpair"
mkdir -p ${DST_LIB}/libnvpair/include/
cp ${SRC_UCM}/os/nvpair_alloc_system.c		${DST_LIB}/libnvpair/
cp ${SRC_LIB}/libnvpair/libnvpair.c		${DST_LIB}/libnvpair/
cp ${SRC_LIB}/libnvpair/libnvpair.h		${DST_LIB}/libnvpair/include/

echo "* lib/libunicode"
# Full source available in 'module/unicode'

echo "* lib/libuutil"
mkdir -p ${DST_LIB}/libuutil/include/
cp ${SRC_LIB}/libuutil/common/*.c		${DST_LIB}/libuutil/
cp ${SRC_LIB}/libuutil/common/*.h		${DST_LIB}/libuutil/include/

echo "* lib/libefi"
mkdir -p ${DST_LIB}/libefi/include/sys/
cp ${SRC_LIB}/libefi/common/rdwr_efi.c		${DST_LIB}/libefi/
cp ${SRC_UCM}/sys/efi_partition.h		${DST_LIB}/libefi/include/sys/
cp ${SRC_UCM}/sys/uuid.h			${DST_LIB}/libefi/include/sys/

echo "* lib/libzpool"
mkdir -p ${DST_LIB}/libzpool/include/sys/
cp ${SRC_LIB}/libzpool/common/kernel.c		${DST_LIB}/libzpool/
cp ${SRC_LIB}/libzpool/common/taskq.c		${DST_LIB}/libzpool/
cp ${SRC_LIB}/libzpool/common/util.c		${DST_LIB}/libzpool/
cp ${SRC_LIB}/libzpool/common/sys/zfs_context.h	${DST_LIB}/libzpool/include/sys/

echo "* lib/libzfs"
mkdir -p ${DST_LIB}/libzfs/include/
cp ${SRC_LIB}/libzfs/common/*.c			${DST_LIB}/libzfs/
cp ${SRC_LIB}/libzfs/common/*.h			${DST_LIB}/libzfs/include/

echo "* cmd/zpool"
mkdir -p ${DST_CMD}/zpool
cp ${SRC_CMD}/zpool/*.c				${DST_CMD}/zpool/
cp ${SRC_CMD}/zpool/*.h				${DST_CMD}/zpool/

echo "* cmd/zfs"
mkdir -p ${DST_CMD}/zfs
cp ${SRC_CMD}/zfs/*.c				${DST_CMD}/zfs/
cp ${SRC_CMD}/zfs/*.h				${DST_CMD}/zfs/

echo "* cmd/zdb"
mkdir -p ${DST_CMD}/zdb/
cp ${SRC_CMD}/zdb/*.c				${DST_CMD}/zdb/

echo "* cmd/zinject"
mkdir -p ${DST_CMD}/zinject
cp ${SRC_CMD}/zinject/*.c			${DST_CMD}/zinject/
cp ${SRC_CMD}/zinject/*.h			${DST_CMD}/zinject/

echo "* cmd/ztest"
mkdir -p ${DST_CMD}/ztest
cp ${SRC_CMD}/ztest/*.c				${DST_CMD}/ztest/

echo "* man/"
mkdir -p ${DST_MAN}/man8
cp ${SRC_MAN}/man1m/zfs.1m			${DST_MAN}/man8/zfs.8
cp ${SRC_MAN}/man1m/zpool.1m			${DST_MAN}/man8/zpool.8
cp ${SRC_MAN}/man1m/zdb.1m			${DST_MAN}/man8/zdb.8
chmod -R 644 ${DST_MAN}/man8/*

echo "${REMOTE_SRC}/${RELEASE}" >${DST}/ZFS.RELEASE

rm -Rf ${SRC}
