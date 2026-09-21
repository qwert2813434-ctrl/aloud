#!/bin/bash
# 導讀窗（Aloud）一行安裝／更新：
#   curl -fsSL https://raw.githubusercontent.com/qwert2813434-ctrl/aloud/main/install.sh | bash
# 裝到 ~/Applications/導讀窗/，更新時保留你的破音字表。
set -e
R=qwert2813434-ctrl/aloud
DEST="${ALOUD_DIR:-$HOME/Applications/導讀窗}"

echo "▸ 檢查 Python"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install 2>/dev/null || true
  echo ""
  echo "第一次要先裝 Apple 的開發者工具（跳出來的視窗按「安裝」，約 5–10 分鐘）。"
  echo "裝好之後，再貼一次同一行指令。"
  exit 1
fi

echo "▸ 安裝語音套件"
/usr/bin/python3 -m pip install --user --quiet --disable-pip-version-check "edge-tts>=7.2" aiohttp

echo "▸ 下載導讀窗"
TMP=$(mktemp -d)
curl -fsSL "https://github.com/$R/releases/latest/download/aloud-mac.zip" -o "$TMP/a.zip"
ditto -x -k "$TMP/a.zip" "$TMP"

# 舊版開著就先關（它結束時會一併收掉伺服器）
if pgrep -x 導讀窗 >/dev/null; then osascript -e 'quit app "導讀窗"' 2>/dev/null || true; sleep 2; fi

[ -f "$DEST/破音字.txt" ] && cp "$DEST/破音字.txt" "$TMP/破音字.keep"
rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
mv "$TMP/導讀窗" "$DEST"
[ -f "$TMP/破音字.keep" ] && cp "$TMP/破音字.keep" "$DEST/破音字.txt"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true   # 註冊右鍵「用導讀窗唸」

# 有裝 Claude Code 就順手裝技能：之後說「使用導讀器回覆我」它就會唸
if [ -d "$HOME/.claude" ]; then
  mkdir -p "$HOME/.claude/skills/導讀器"
  sed "s#__DIR__#$DEST#g" "$DEST/給Claude的技能.md" > "$HOME/.claude/skills/導讀器/SKILL.md"
  echo "▸ 已裝 Claude 技能「導讀器」"
fi
rm -rf "$TMP"

open "$DEST/導讀窗.app"
echo ""
echo "✓ 裝好了。螢幕上方選單列出現波形圖示就是它（被瀏海擋住的話，按住 ⌘ 把它拖到右邊）。"
echo "  用法看：$DEST/使用說明.md"
