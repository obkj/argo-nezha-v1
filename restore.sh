#!/bin/bash

# 定义变量
GH_PROXY=""
TEMP_DIR="/tmp/restore_temp"
# 设置默认值
WORK_DIR=${WORK_DIR:-"/dashboard"}  # 默认 WORK_DIR 为 /dashboard

# 确保环境变量已设置
[ -z "$GH_PAT" ] && { echo -e "\033[31m\033[01m错误: GH_PAT 未设置\033[0m"; exit 1; }
[ -z "$GH_BACKUP_USER" ] && { echo -e "\033[31m\033[01m错误: GH_BACKUP_USER 未设置\033[0m"; exit 1; }
[ -z "$GH_REPO" ] && { echo -e "\033[31m\033[01m错误: GH_REPO 未设置\033[0m"; exit 1; }
[ -z "$WORK_DIR" ] && { echo -e "\033[31m\033[01m错误: WORK_DIR 未设置\033[0m"; exit 1; }
[ ! -e "$WORK_DIR/backup.sh" ] && { echo -e "\033[31m\033[01m错误: backup.sh 不存在\033[0m"; exit 1; }

# 定义日志函数
info() { echo -e "\033[32m\033[01m[INFO] $*\033[0m"; }   # 绿色
error() { echo -e "\033[31m\033[01m[ERROR] $*\033[0m"; exit 1; } # 红色
hint() { echo -e "\033[33m\033[01m[HINT] $*\033[0m"; }   # 黄色

# 清理临时目录
cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}
trap "cleanup; echo -e '\n'; exit" INT QUIT TERM EXIT

# 创建临时目录
mkdir -p "$TEMP_DIR"


# 获取 GitHub 上的 README.md 内容
ONLINE=$(wget -qO- --header="Authorization: token $GH_PAT" "${GH_PROXY}https://raw.githubusercontent.com/$GH_BACKUP_USER/$GH_REPO/main/README.md" | sed "/^$/d" | head -n 1)
[ -z "$ONLINE" ] && error "无法连接到 GitHub 或 README.md 为空！"

# 如果 README.md 包含 backup 关键词，触发备份
if grep -qi 'backup' <<< "$ONLINE"; then
    { "$WORK_DIR/backup.sh" || error "执行 backup.sh 失败"; }
    exit 0
fi

# 检查是否需要恢复
[ "$ONLINE" = "$(cat $WORK_DIR/dbfile)" ] && { info "本地已是最新备份，退出。"; exit 0; }
[[ "$ONLINE" =~ tar\.gz$ ]] && FILE="$ONLINE" || error "README.md 内容不是有效的 tar.gz 文件名！"

# 下载备份文件
DOWNLOAD_URL="https://raw.githubusercontent.com/$GH_BACKUP_USER/$GH_REPO/main/$FILE"
wget --header="Authorization: token $GH_PAT" --header='Accept: application/vnd.github.v3.raw' -O "$TEMP_DIR/backup.tar.gz" "${GH_PROXY}${DOWNLOAD_URL}" || error "无法下载备份文件 $FILE！"

# 解压备份文件
if [ -e "$TEMP_DIR/backup.tar.gz" ]; then
    echo "↓↓↓↓↓↓↓↓↓↓ 还原文件列表 ↓↓↓↓↓↓↓↓↓↓"
    tar xzvf "$TEMP_DIR/backup.tar.gz" -C "$TEMP_DIR" data/
    echo -e "↑↑↑↑↑↑↑↑↑↑ 还原文件列表 ↑↑↑↑↑↑↑↑↑↑\n"

    # 复制到工作目录
    cp -rf "$TEMP_DIR/data/"* "$WORK_DIR/data/" || error "无法复制备份文件到 $WORK_DIR/data/！"
    
    # 更新本地记录
    echo "$ONLINE" > "$WORK_DIR/dbfile"
    info "成功还原备份文件 $FILE 到 $WORK_DIR/data/"
    
    # 清理临时目录
    cleanup
else
    error "下载的备份文件 $TEMP_DIR/backup.tar.gz 不存在！"
fi