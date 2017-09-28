#!/bin/sh

# ==============================================================================
#   機能
#     ファイルアーカイブを作成する
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
HOSTNAME=`hostname`

SETUP_FIL_LIST_OPTIONS=""
SETUP_FIL_OPTIONS=""

# システム環境 依存変数

# プログラム内部変数
HOST_DIR="${HOSTNAME}"
ARC_TYPE="DIR"							#初期状態が「空文字以外」でなければならない変数
TAR_NUMERIC_ID=""						#初期状態が「空文字」でなければならない変数
PKG_GROUPS=""							#初期状態が「空文字」でなければならない変数
HOST=""									#初期状態が「空文字」でなければならない変数

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
FILE_LIST_TMP="${SCRIPT_TMP_DIR}/file_list.tmp"

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p -m 0700 "${SCRIPT_TMP_DIR}"
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
		    setup_fil_list_archive.sh [OPTIONS ...] FILE_LIST
		
		ARGUMENTS:
		    FILE_LIST : Specify an input file list.
		
		OPTIONS:
		    --setup_fil_list_options="SETUP_FIL_LIST_OPTIONS ..."
		       Specify options which execute setup_fil_list.sh command with.
		       See also "setup_fil_list.sh --help" for the further information on each
		       option.
		    --setup_fil_options="SETUP_FIL_OPTIONS ..."
		       Specify options which execute setup_fil.sh command with.
		       See also "setup_fil.sh --help" for the further information on each
		       option.
		    --hd=HOST_DIR
		       Specify host directory.
		    -t ARC_TYPE
		       ARC_TYPE : {DIR|TAR}
		    -n
		       Use --numeric-owner option with tar command.
		    -g "PKG_GROUPS ..."
		       Specify package group field value in FILE_LIST.
		    -h HOST
		       Specify host field value in FILE_LIST.
		    --help
		       Display this help and exit.
	EOF
}

. cmd_v_function.sh

. setup_fil_list_function.sh

FIL_LIST_INSTALL() {
	rm -f "${FILE_LIST_TMP}"
	touch "${FILE_LIST_TMP}"
	FILE_LIST_TMP_MAKE
	DIRS="$(cat "${FILE_LIST_TMP}" \
		| awk -F '\t' -v FIELD_FILE_NAME="${TMP_FIELD_FILE_NAME}" '{print $FIELD_FILE_NAME}' \
		| sed 's#/[^/]\+$##' \
		| sort | uniq \
		| sed "s#^/#${host_dir_root}/#" \
	)"
	mkdir -p ${DIRS}
	(set -x; setup_fil_list.sh install \
		${SETUP_FIL_LIST_OPTIONS} \
		--setup_fil_options="${SETUP_FIL_OPTIONS} --hd=\"${HOST_DIR}\" -r \"${host_dir_root}\"" \
		"$(realpath "${FILE_LIST}")" \
		-h ${HOST} ${PKG_GROUP:+-g "${PKG_GROUP}"})
}

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o t:ng:h: -l setup_fil_list_options:,setup_fil_options:,hd:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE ${ACTION};exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	--setup_fil_list_options)	SETUP_FIL_LIST_OPTIONS="$2" ; shift 2;;
	--setup_fil_options)	SETUP_FIL_OPTIONS="$2" ; shift 2;;
	--hd)	HOST_DIR="$2" ; shift 2;;
	-t)
		case "$2" in
		DIR|TAR)	ARC_TYPE="$2" ; shift 2;;
		*)
			echo "-E Argument to \"${opt}\" is invalid -- \"$2\"" 1>&2
			USAGE ${ACTION};exit 1
			;;
		esac
		;;
	-n)	TAR_NUMERIC_ID=TRUE ; shift 1;;
	-g)	PKG_GROUPS="$2" ; shift 2;;
	-h)	HOST="$2" ; shift 2;;
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
	echo "-E Missing FILE_LIST argument" 1>&2
	USAGE;exit 1
else
	FILE_LIST="$1"
	# ファイルリストのチェック
	if [ ! -f "${FILE_LIST}" ];then
		echo "-E FILE_LIST not a file -- \"${FILE_LIST}\"" 1>&2
		USAGE;exit 1
	fi
fi

# 作業開始前処理
PRE_PROCESS

#####################
# メインループ 開始 #
#####################

FILE_LIST_FIELD_SEARCH

echo
host_dir_root="${SCRIPT_TMP_DIR}/${HOST_DIR}"
rm -fr "${host_dir_root}"
mkdir -m 0700 "${host_dir_root}"
if [ ! "${PKG_GROUPS}" = "" ];then
	for PKG_GROUP in ${PKG_GROUPS} ; do
		FIL_LIST_INSTALL
	done
else
	PKG_GROUP=""
	FIL_LIST_INSTALL
fi
case ${ARC_TYPE} in
DIR)
	if [ -e "${PWD}/${HOST_DIR}" ];then
		rm -fri "${PWD}/${HOST_DIR}"
	fi
	cp -prd "${SCRIPT_TMP_DIR}/${HOST_DIR}" "${PWD}/${HOST_DIR}"
	sh -c "cd \"${PWD}\" && find \"${HOST_DIR}\" -print0 | sort -z | xargs -0 -r ls -ald"
	;;
TAR)
	tar cvf "${SCRIPT_TMP_DIR}/${HOST_DIR}.tar" ${TAR_NUMERIC_ID:+--numeric-owner} -C "${SCRIPT_TMP_DIR}" "${HOST_DIR}" > /dev/null
	chmod 0600 "${SCRIPT_TMP_DIR}/${HOST_DIR}.tar"
	gzip "${SCRIPT_TMP_DIR}/${HOST_DIR}.tar"
	if [ -f "${PWD}/${HOST_DIR}.tar.gz" ];then
		rm -fi "${PWD}/${HOST_DIR}.tar.gz"
	fi
	mv "${SCRIPT_TMP_DIR}/${HOST_DIR}.tar.gz" "${PWD}/${HOST_DIR}.tar.gz"
	gzip -dc "${PWD}/${HOST_DIR}.tar.gz" | LANG=C tar tvf - | sort -k6,6
	;;
esac

#####################
# メインループ 終了 #
#####################

# 作業終了後処理
POST_PROCESS;exit 0

