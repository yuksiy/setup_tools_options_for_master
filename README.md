# setup_tools_options_for_master

## 概要

システムセットアップツール マスター オプション

本ツールを使用する際の想定ディレクトリ構造に関しては、以下のファイルを参照してください。

* [README.md](https://github.com/yuksiy/setup_tools/blob/master/README.md)

## 使用方法

### setup_fil_list_archive.sh

ファイルリスト中のパッケージグループフィールドの値が
指定された「パッケージグループ名」のいずれかであり、
ホストフィールドの値が「1」である設定ファイルを、
ローカルホストの「ホスト名」ディレクトリから抽出してファイルアーカイブ(TAR形式)を作成します。

    $ cd ${HOME}/VCS/setup
    $ sudo -E setup_fil_list_archive.sh \
        --setup_fil_list_options="-C ${HOME}/.setup_fil_list.OS名.conf -v 0" \
        --setup_fil_options="-C ${HOME}/.setup_fil.OS名.conf --pause-per-dest-file=yes" \
        --hd=ホスト名 \
        -t TAR \
        -g "パッケージグループ ..." \
        -h ホストフィールド名 \
        ./OS名/list/file_list_remote.txt

### setup_pkg_list_local_make_debian.sh

Debian GNU/Linux の指定されたディストリビューション名、指定されたアーキテクチャ名の
プライオリティが「required, important, standard」であるパッケージのリストを作成します。

    $ setup_pkg_list_local_make_debian.sh \
        -d ディストリビューション名(例：stable) \
        -a アーキテクチャ名(例：amd64) \
        pkg_list_local.txt

以下の用語に関しては、リンク先を参照してください。

* [ディストリビューション](https://www.debian.org/releases/)
* [アーキテクチャ](https://www.debian.org/ports/)
* [プライオリティ](https://www.debian.org/doc/manuals/debian-faq/ch-pkg_basics.en.html#s-priority)

### パッケージリスト, ファイルリストの書式

これらのファイルの書式に関しては、以下のファイルを参照してください。

* [README_pkg_list.md](https://github.com/yuksiy/setup_tools/blob/master/README_pkg_list.md)
* [README_file_list.md](https://github.com/yuksiy/setup_tools/blob/master/README_file_list.md)

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* realpath
* wget
* dctrl-tools
* [common_sh](https://github.com/yuksiy/common_sh)
* [setup_tools](https://github.com/yuksiy/setup_tools)

## インストール

ソースからインストールする場合:

    (Linux の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/setup_tools_options_for_master>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/setup_tools_options_for_master/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2011-2017 Yukio Shiiya
