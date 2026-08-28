# ACCEPTANCE — 每階段驗收

沒過不准做下一階段。

### 1 · 伺服器
```bash
curl -s localhost:$PORT/ping                        # {"ok":true}
curl -s -X POST localhost:$PORT/tts -d '{"text":"測試一下","voice":"<你的預設語音>"}' | head -c 80
```
拿到的 base64 存成 `.mp3` 用 `afplay` 播得出來。啟動 log 第一行有 `PORT=`。

### 2 · 頁面
- 貼 300 字進去按播放，**首字 1 秒內出聲**（別用「整段播完的時間」量）
- 播到第三句時第三句是亮的；點第一句會跳回第一句
- 拖速率滑桿當下就變速，沒有等待
- 同一段重播第二次，伺服器 log 沒有新的 `/tts` 請求（快取有效）

### 3 · 收件匣
```bash
echo "第一則" | python3 push.py; echo "第二則" | python3 push.py
```
兩則**依序唸完，沒有互相蓋掉**。關掉頁面再開，剛剛那兩則**不重播**。
伺服器 log 顯示 `/events` 是長連線，不是每秒一次 `/pull`。

### 4 · 破音字
表裡放一條，推一段含該詞的文字：**耳朵聽到新唸法、畫面顯示原文**。
存檔後不重開伺服器，下一則就生效。

### 5 · 選單列 App
雙擊 `.app`：Dock 沒有圖示、選單列有。點開面板 **1 秒內**看得到頁面（不是空白轉圈）。
面板收起來聲音繼續。App 結束後 `lsof -ti tcp:$PORT` 是空的。

### 6 · 系統整合
- 在 Safari / Notes / Finder 各選一段字右鍵 →「用 Aloud 唸」，三個都要進佇列
- ⌘C 一段字 → ⌃⌥D → 唸出來
- ⌃⌥S 框一塊有中英文的畫面 → OCR 文字進佇列（第一次會要螢幕錄製權限）
- 唸的時候按 F8 暫停、F9 下一句，**前景是別的 App 也有效**

### 7 · `/ctl`
```bash
curl -X POST localhost:$PORT/ctl -d '{"cmd":"pause"}'   # 立刻停
echo "錄音中推進來的" | python3 push.py                  # 排隊，不播
curl -X POST localhost:$PORT/ctl -d '{"cmd":"resume"}'  # 接著播
```
再測一次 pause 之後**不送 resume**：3 分鐘後要自己活過來。
