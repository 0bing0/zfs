#!/bin/bash
#
# Sun Fire x4550 (Thumper) Raid-10 Configuration (3x16 mirror)
#

DEVICES=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000`)
DEVICES_02=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000\:02`)
DEVICES_03=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000\:03`)
DEVICES_04=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000\:04`)
DEVICES_41=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000\:41`)
DEVICES_42=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000\:42`)
DEVICES_43=(`ls /dev/disk/by-path/* | grep -v part | grep pci-0000\:43`)

M_IDX=0
MIRRORS=()

zpool_create() {

	D_IDX=0
	while [ ${D_IDX} -lt ${#DEVICES_02[@]} ]; do
		MIRROR1=`readlink -f ${DEVICES_02[${D_IDX}]}`
		MIRROR2=`readlink -f ${DEVICES_03[${D_IDX}]}`
		MIRROR3=`readlink -f ${DEVICES_04[${D_IDX}]}`
		MIRRORS[${M_IDX}]="mirror ${MIRROR1} ${MIRROR2} ${MIRROR3}"
		let D_IDX=D_IDX+1
		let M_IDX=M_IDX+1
	done

	D_IDX=0
	while [ ${D_IDX} -lt ${#DEVICES_03[@]} ]; do
		MIRROR1=`readlink -f ${DEVICES_41[${D_IDX}]}`
		MIRROR2=`readlink -f ${DEVICES_42[${D_IDX}]}`
		MIRROR3=`readlink -f ${DEVICES_43[${D_IDX}]}`
		MIRRORS[${M_IDX}]="mirror ${MIRROR1} ${MIRROR2} ${MIRROR3}"
		let D_IDX=D_IDX+1
		let M_IDX=M_IDX+1
	done

	msg ${ZPOOL} create -f ${ZPOOL_NAME} ${MIRRORS[*]}
	${ZPOOL} create -f ${ZPOOL_NAME} ${MIRRORS[*]} || exit 1
}

zpool_destroy() {
	msg ${ZPOOL} destroy ${ZPOOL_NAME}
	${ZPOOL} destroy ${ZPOOL_NAME}
}
