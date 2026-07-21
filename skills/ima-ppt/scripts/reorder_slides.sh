#!/bin/bash
# reorder_slides.sh — PPT slide 文件重编号工具
#
# 用法：
#   insert <dir> <pos>     在 pos 位置插入空位（原 pos 及之后的文件后移 1 位）
#   delete <dir> <pos>     删除 pos 位置的文件（原 pos+1 及之后的文件前移 1 位）
#   move <dir> <from> <to> 将 from 位置的文件移动到 to 位置

set -e

ACTION="$1"
DIR="$2"

fmt() { printf "slide_%02d.html" "$1"; }

# 获取当前最大编号
max_slide() {
    ls "$DIR"/slide_*.html 2>/dev/null | sed 's/.*slide_\([0-9]*\)\.html/\1/' | sort -n | tail -1
}

case "$ACTION" in
    insert)
        POS="$3"
        N=$(max_slide)
        if [ -z "$N" ]; then echo "Error: no slides found in $DIR"; exit 1; fi
        # 从最后一个开始倒序重命名，为 POS 腾出空位
        for i in $(seq "$N" -1 "$POS"); do
            src="$DIR/$(fmt $i)"
            dst="$DIR/$(fmt $((i + 1)))"
            if [ -f "$src" ]; then
                mv "$src" "$dst"
            fi
        done
        echo "Done: position $POS is now free (slides renumbered $POS..$((N+1)))"
        echo "Next: write your new slide to $DIR/$(fmt $POS)"
        ;;

    delete)
        POS="$3"
        N=$(max_slide)
        TARGET="$DIR/$(fmt $POS)"
        if [ ! -f "$TARGET" ]; then echo "Error: $TARGET does not exist"; exit 1; fi
        rm "$TARGET"
        # 从 POS+1 开始正序重命名，填补空位
        for i in $(seq $((POS + 1)) "$N"); do
            src="$DIR/$(fmt $i)"
            dst="$DIR/$(fmt $((i - 1)))"
            if [ -f "$src" ]; then
                mv "$src" "$dst"
            fi
        done
        echo "Done: deleted position $POS, renumbered $((POS+1))..$N → $POS..$((N-1))"
        ;;

    move)
        FROM="$3"
        TO="$4"
        N=$(max_slide)
        SRC="$DIR/$(fmt $FROM)"
        if [ ! -f "$SRC" ]; then echo "Error: $SRC does not exist"; exit 1; fi
        # 先把源文件移到临时位置
        TMP="$DIR/slide_tmp-move.html"
        mv "$SRC" "$TMP"
        if [ "$FROM" -gt "$TO" ]; then
            # 向前移：TO..FROM-1 的位置需要后移
            for i in $(seq $((FROM - 1)) -1 "$TO"); do
                src="$DIR/$(fmt $i)"
                dst="$DIR/$(fmt $((i + 1)))"
                if [ -f "$src" ]; then mv "$src" "$dst"; fi
            done
        else
            # 向后移：FROM+1..TO 的位置需要前移
            for i in $(seq $((FROM + 1)) "$TO"); do
                src="$DIR/$(fmt $i)"
                dst="$DIR/$(fmt $((i - 1)))"
                if [ -f "$src" ]; then mv "$src" "$dst"; fi
            done
        fi
        mv "$TMP" "$DIR/$(fmt $TO)"
        echo "Done: moved slide $FROM → $TO"
        ;;

    *)
        echo "Usage: $0 {insert|delete|move} <dir> <args...>"
        echo "  insert <dir> <pos>        Make room at position <pos>"
        echo "  delete <dir> <pos>        Delete slide at <pos> and renumber"
        echo "  move   <dir> <from> <to>  Move slide from <from> to <to>"
        exit 1
        ;;
esac

# 打印当前状态
echo ""
echo "Current slides:"
ls -1 "$DIR"/slide_*.html 2>/dev/null | sort | while read f; do
    echo "  $(basename $f)"
done
