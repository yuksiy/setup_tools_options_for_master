#!/bin/sh

# ==============================================================================
#   機能
#     パッケージリスト(ローカル)を作成する (Debian)
#   構文
#     USAGE 参照
#
#   Copyright (c) 2011-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_NAME="`basename $0`"
PID=$$

######################################################################
# 変数定義
######################################################################
# ユーザ変数
METHOD="http"
REMOTEHOST="ftp.jp.debian.org"
ROOTDIR="debian"
DIST="stable"
SECTIONS="main contrib non-free"
ARCH="amd64"
CUT_DIRS_NUM=3

# システム環境 依存変数

# プログラム内部変数

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    setup_pkg_list_local_make_debian.sh [OPTIONS ...] PKG_LIST
		
		ARGUMENTS:
		    PKG_LIST : Specify an output package list.
		
		OPTIONS:
		    -d DIST
		       Specify the distribution of Debian.
		    -a ARCH
		       Specify the architecture of Debian.
		    --help
		       Display this help and exit.
	EOF
}

. cmd_v_function.sh

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o d:a: -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE ${ACTION};exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-d)	DIST="$2" ; shift 2;;
	-a)	ARCH="$2" ; shift 2;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing PKG_LIST argument" 1>&2
	USAGE;exit 1
else
	PKG_LIST=$1
	# パッケージリスト格納ディレクトリのチェック
	PKG_LIST_DIR=`dirname "${PKG_LIST}"`
	if [ ! -d "${PKG_LIST_DIR}" ];then
		echo "-E \"${PKG_LIST_DIR}\" not a directory" 1>&2
		USAGE;exit 1
	fi
	# パッケージリストのチェック
	if [ -e "${PKG_LIST}" ];then
		echo "-E PKG_LIST already exists -- \"${PKG_LIST}\"" 1>&2
		USAGE;exit 1
	fi
fi

# 作業開始前処理
PRE_PROCESS

cd "${SCRIPT_TMP_DIR}"

# Release ファイルのダウンロード
uri="${METHOD}://${REMOTEHOST}/${ROOTDIR}/dists/${DIST}/Release"
CMD_V "LANG=C wget -N -x -nH --cut-dirs=${CUT_DIRS_NUM} ${uri}"
if [ $? -ne 0 ];then
	echo "-E Command has ended unsuccessfully." 1>&2
	POST_PROCESS;exit 1
fi

# Packages ファイルのダウンロード
for section in ${SECTIONS} ; do
	uri="${METHOD}://${REMOTEHOST}/${ROOTDIR}/dists/${DIST}/${section}/binary-${ARCH}/Packages.gz"
	CMD_V "LANG=C wget -N -x -nH --cut-dirs=${CUT_DIRS_NUM} ${uri}"
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
done

# Packages ファイルの展開
for file in `find . -name '*.gz' | sort` ; do
	CMD_V "gzip -d ${file}"
	if [ $? -ne 0 ];then
		echo "-E Command has ended unsuccessfully." 1>&2
		POST_PROCESS;exit 1
	fi
done

cd "${OLDPWD}"

# Release ファイルのVersion フィールドの表示
echo
echo -n "-I Version field of Release file: "
(cd "${SCRIPT_TMP_DIR}"; cat Release) \
	| sed -n 's#^Version: \(.*\)$#\1#p'

# パッケージリストの作成
cat <<- EOF >> "${PKG_LIST}"
	# pkg_group	pkg_name
	
EOF
echo
for priority in required important standard ; do
	echo "-I Now processing: priority=${priority}"
	for section in ${SECTIONS} ; do
		(cd "${SCRIPT_TMP_DIR}"; cat ${section}/binary-${ARCH}/Packages) \
			| grep-dctrl -n -s Package -F Priority -e "${priority}" \
			| awk -v priority=${priority} '{printf("%s\t%s\n",priority,$0)}'
	done | LANG=C sort | uniq >> "${PKG_LIST}"
	echo >> "${PKG_LIST}"
done

# 作業終了後処理
POST_PROCESS;exit 0

