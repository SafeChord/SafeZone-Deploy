#!/bin/bash
# sync-helpers.sh

# 設定 source helper 路徑（假設你放在專案根目錄下 .common/）
SRC=".common/_helpers.tpl"

# 找到所有需要同步的 templates 目錄（避免外部 chart dependency 可排除）
find . -type d -path "*/templates" | grep -Ev "deprecated|redis|bitnami" | while read dir; do
  # 複製 _helpers.tpl
  cp "$SRC" "$dir/_helpers.tpl"
  echo "Copied to $dir/_helpers.tpl"
done

echo "✅ 所有 chart 的 _helpers.tpl 已同步完成！"