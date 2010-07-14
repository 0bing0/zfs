AC_DEFUN([ZFS_AC_LICENSE], [
	AC_MSG_CHECKING([zfs author])
	AC_MSG_RESULT([$ZFS_META_AUTHOR])

	AC_MSG_CHECKING([zfs license])
	AC_MSG_RESULT([$ZFS_META_LICENSE])
])

AC_DEFUN([ZFS_AC_DEBUG], [
	AC_MSG_CHECKING([whether debugging is enabled])
	AC_ARG_ENABLE([debug],
		[AS_HELP_STRING([--enable-debug],
		[Enable generic debug support @<:@default=no@:>@])],
		[],
		[enable_debug=no])

	AS_IF([test "x$enable_debug" = xyes],
	[
		KERNELCPPFLAGS="${KERNELCPPFLAGS} -DDEBUG -Werror"
		HOSTCFLAGS="${HOSTCFLAGS} -DDEBUG -Werror"
		DEBUG_CFLAGS="-DDEBUG -Werror -fstack-check"
	],
	[
		KERNELCPPFLAGS="${KERNELCPPFLAGS} -DNDEBUG "
		HOSTCFLAGS="${HOSTCFLAGS} -DNDEBUG "
		DEBUG_CFLAGS="-DNDEBUG"
	])

	AC_SUBST(DEBUG_CFLAGS)
	AC_MSG_RESULT([$enable_debug])
])

AC_DEFUN([ZFS_AC_CONFIG_SCRIPT], [
	cat >.script-config <<EOF
KERNELSRC=${LINUX}
KERNELBUILD=${LINUX_OBJ}
KERNELSRCVER=${LINUX_VERSION}
KERNELMOD=/lib/modules/\${KERNELSRCVER}/kernel

SPLSRC=${SPL}
SPLBUILD=${SPL_OBJ}
SPLSRCVER=${SPL_VERSION}

TOPDIR=${TOPDIR}
BUILDDIR=${BUILDDIR}
LIBDIR=${LIBDIR}
CMDDIR=${CMDDIR}
MODDIR=${MODDIR}
SCRIPTDIR=${SCRIPTDIR}
ETCDIR=\${TOPDIR}/etc
DEVDIR=\${TOPDIR}/dev
ZPOOLDIR=\${TOPDIR}/scripts/zpool-config
ZPIOSDIR=\${TOPDIR}/scripts/zpios-test
ZPIOSPROFILEDIR=\${TOPDIR}/scripts/zpios-profile

ZDB=\${CMDDIR}/zdb/zdb
ZFS=\${CMDDIR}/zfs/zfs
ZINJECT=\${CMDDIR}/zinject/zinject
ZPOOL=\${CMDDIR}/zpool/zpool
ZPOOL_ID=\${CMDDIR}/zpool_id/zpool_id
ZTEST=\${CMDDIR}/ztest/ztest
ZPIOS=\${CMDDIR}/zpios/zpios

COMMON_SH=\${SCRIPTDIR}/common.sh
ZFS_SH=\${SCRIPTDIR}/zfs.sh
ZPOOL_CREATE_SH=\${SCRIPTDIR}/zpool-create.sh
ZPIOS_SH=\${SCRIPTDIR}/zpios.sh
ZPIOS_SURVEY_SH=\${SCRIPTDIR}/zpios-survey.sh

INTREE=1
LDMOD=/sbin/insmod

KERNEL_MODULES=(                                      \\
        \${KERNELMOD}/lib/zlib_deflate/zlib_deflate.ko \\
)

SPL_MODULES=(                                         \\
        \${SPLBUILD}/spl/spl.ko                        \\
)

ZFS_MODULES=(                                         \\
        \${MODDIR}/avl/zavl.ko                         \\
        \${MODDIR}/nvpair/znvpair.ko                   \\
        \${MODDIR}/unicode/zunicode.ko                 \\
        \${MODDIR}/zcommon/zcommon.ko                  \\
        \${MODDIR}/zfs/zfs.ko                          \\
)

ZPIOS_MODULES=(                                       \\
        \${MODDIR}/zpios/zpios.ko                      \\
)

MODULES=(                                             \\
        \${KERNEL_MODULES[[*]]}                          \\
        \${SPL_MODULES[[*]]}                             \\
        \${ZFS_MODULES[[*]]}                             \\
)
EOF
])

AC_DEFUN([ZFS_AC_CONFIG], [
	TOPDIR=`readlink -f ${srcdir}`
	BUILDDIR=$TOPDIR
	LIBDIR=$TOPDIR/lib
	CMDDIR=$TOPDIR/cmd
	MODDIR=$TOPDIR/module
	SCRIPTDIR=$TOPDIR/scripts
	TARGET_ASM_DIR=asm-generic

	AC_SUBST(TOPDIR)
	AC_SUBST(BUILDDIR)
	AC_SUBST(LIBDIR)
	AC_SUBST(CMDDIR)
	AC_SUBST(MODDIR)
	AC_SUBST(SCRIPTDIR)
	AC_SUBST(TARGET_ASM_DIR)

	ZFS_CONFIG=all
	AC_ARG_WITH([config],
		AS_HELP_STRING([--with-config=CONFIG],
		[Config file 'kernel|user|all|srpm']),
		[ZFS_CONFIG="$withval"])

	AC_MSG_CHECKING([zfs config])
	AC_MSG_RESULT([$ZFS_CONFIG]);
	AC_SUBST(ZFS_CONFIG)

	case "$ZFS_CONFIG" in
		kernel) ZFS_AC_CONFIG_KERNEL ;;
		user)	ZFS_AC_CONFIG_USER   ;;
		all)    ZFS_AC_CONFIG_KERNEL
			ZFS_AC_CONFIG_USER   ;;
		srpm)                        ;;
		*)
		AC_MSG_RESULT([Error!])
		AC_MSG_ERROR([Bad value "$ZFS_CONFIG" for --with-config,
		              user kernel|user|all|srpm]) ;;
	esac

	AM_CONDITIONAL([CONFIG_USER],
	               [test "$ZFS_CONFIG" = user] ||
	               [test "$ZFS_CONFIG" = all])
	AM_CONDITIONAL([CONFIG_KERNEL],
	               [test "$ZFS_CONFIG" = kernel] ||
	               [test "$ZFS_CONFIG" = all])

	ZFS_AC_CONFIG_SCRIPT
])
