#!/bin/bash

# Realm network forwarding manager integration for xwPF.
# xwPF is maintained at https://github.com/zywe03/realm-xwPF (MIT License).

realm_manager() {
    local entry="/usr/local/bin/xwPF.sh"
    local module_dir="/usr/local/bin/lib"
    local script_url="https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh"
    local tmp_file module rc

    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        msg "Realm 管理需要 root 权限。请使用: sudo sing-box realm"
        return 1
    fi

    if [[ -f "$entry" ]]; then
        bash "$entry" "$@"
        return $?
    fi

    if [[ $# -gt 0 && "$1" != "install" ]]; then
        msg "xwPF 尚未安装。请先运行: sing-box realm install"
        return 1
    fi

    # xwPF's installer creates /usr/local/bin/pf and writes five modules to
    # /usr/local/bin/lib. Avoid overwriting unrelated commands or files.
    if [[ -e /usr/local/bin/pf || -L /usr/local/bin/pf ]]; then
        msg "检测到 /usr/local/bin/pf 已存在。为避免覆盖现有命令，请先检查并移除冲突后再安装 xwPF。"
        return 1
    fi
    for module in core.sh rules.sh server.sh realm.sh ui.sh; do
        if [[ -e "$module_dir/$module" || -L "$module_dir/$module" ]]; then
            msg "检测到 $module_dir/$module 已存在。为避免覆盖现有文件，已停止安装 xwPF。"
            return 1
        fi
    done

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        msg "安装 xwPF 需要 curl 或 wget。"
        return 1
    fi

    tmp_file=$(mktemp) || {
        msg "无法创建 xwPF 临时下载文件。"
        return 1
    }

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 10 --max-time 90 "$script_url" -o "$tmp_file"
        rc=$?
    else
        wget -qO "$tmp_file" "$script_url"
        rc=$?
    fi
    if [[ $rc -ne 0 || ! -s "$tmp_file" ]]; then
        rm -f "$tmp_file"
        msg "下载 xwPF 失败，请检查网络后重试。"
        return 1
    fi

    bash "$tmp_file" install
    rc=$?
    rm -f "$tmp_file"
    return "$rc"
}
