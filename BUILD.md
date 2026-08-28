# BUILD — 施工順序

你是實作者。照階段做，**每階段做完先跑 `ACCEPTANCE.md` 同編號那節**，過了才做下一階段。
契約看 `SPEC.md`，卡住先查 `PITFALLS.md`。

規模參考（我自己那版）：伺服器 ~200 行 Python、頁面 ~370 行單檔 HTML、選單列 App ~200 行 Swift。
**如果你寫超過這個量的兩倍，八成是走偏了**，停下來回看規格。

---

## 階段 0：環境

```bash
python3 -m pip install --user edge-tts      # 或你選的 TTS 套件，見 SPEC「配音層是可換的」
swiftc --version                             # 沒有就 xcode-select --install（只有階段 5 需要）
```

產出：一個空資料夾，裡面之後會有 `server.py`、`index.html`、`push.py`。

---

## 階段 1：伺服器骨架（`/ping`、`/tts`）

`ThreadingHTTPServer` 綁 `127.0.0.1`，**只服務本機**。從 8765 往上找第一個空的埠，
把 `PORT=<n>` 印到 stdout 第一行，啟動它的人負責把 stdout 導到 `/tmp/aloud.log`——
別的程式靠讀那行找到你（階段 3、7 會用到）。

`POST /tts {"text","voice"}` → `{"audio": <base64 mp3>, "sents": [[句子, 起秒, 長秒], …]}`。
配音套件要能吐句界事件就順手收下（我用的那套是 `SentenceBoundary`，單位 100 奈秒要自己換算成秒）；
吐不出來就回空陣列，頁面不靠它也能跑。

**音檔為空要當錯誤丟出來**，不要回一個空字串讓頁面靜靜不出聲。

---

## 階段 2：頁面——逐句串流播放

單檔 `index.html`，**零外部相依**（不要 CDN、不要框架）。

1. 一個 textarea 貼文字；按播放後照 `SPEC.md`「切句規則」切成句陣列
2. **一句一句打 `/tts`**：第一句回來就播，同時背景預抓後面兩句（不要等全部）
3. 播到哪句就把那句 highlight；**點任何一句從那句重播**
4. 速率滑桿改的是 `<audio>.playbackRate`，不重新合成
5. 每句各自快取（LRU 300 句），重聽不再打伺服器
6. 句與句之間留 0.2 秒氣口（`ended` 事件裡 `setTimeout(…, 200)`）

語音、語速、主題存 `localStorage`。

> 為什麼不整段合成：整段要收齊才播，文章越長等越久。切句之後首字延遲固定 ≈0.4 秒。
> 代價是句間語調銜接略差、短碎句要併進前一句（見切句規則），我認為划算。

---

## 階段 3：收件匣（`/push`、`/pull`、`/events`）

讓外部程式把文字推進來排隊唸。**佇列不是單格**——兩個來源同時推、或分頁被瀏覽器降速時，
用單格會把前一則蓋掉。

- `POST /push {"text"}` → 編號 +1，進佇列（只留最近 200 則）
- `GET /pull`（不帶 `after`）→ `{"last": n}`：頁面剛開只問「現在到哪」，**開頁前的舊訊息不補播**
- `GET /pull?after=n` → 下一則 + 還有幾則待播
- `GET /events` → SSE 長連線，有新訊息就推編號；20 秒沒事推一次當心跳。**不要輪詢**

外加一支 `push.py`：讀 `/tmp/aloud.log` 拿埠號，文字從 stdin 進，`echo "話" | python3 push.py`。
這支就是你的 AI 助手推訊息進來的入口。

---

## 階段 4：破音字表

`GET /fix` 回 `[[原詞, 唸法], …]`，讀同目錄一個純文字檔，一行一條 `重新=崇新`，
`#` 開頭是註解。**長詞先比對**（伺服器端就先照長度排好）。

只換送去配音的字串，**畫面永遠顯示原文**。頁面每一則都重抓一次 `/fix`，存檔後下一則生效。

---

## 階段 5：選單列 App（Swift）

`NSStatusItem` + 左鍵彈出 `NSPopover`/`NSPanel` 裡的 `WKWebView` 載本機頁面。
`LSUIElement=true`（不佔 Dock）。右鍵是功能選單：播放暫停／下一句／停這則／開破音字表／重新載入／結束。

- **面板沒開也要先把頁面載起來**：`WKWebView` 不進視窗不會載，先掛在一個隱藏視窗上，
  不然第一次點開要等好幾秒才有反應
- 伺服器由 App 起、App 結束時收掉；`/tmp/aloud.log` 裡已經有活著的伺服器就直接沿用
- 面板收起來聲音要照播（音訊在 WKWebView 裡，別把 view 銷毀）
- 圖示位置用 `autosaveName` 記住

打包成 `.app` 有個坑，見 `PITFALLS.md` 第 3 條，**先看再打包**。

---

## 階段 6：系統整合

1. **任何 App 右鍵「用 Aloud 唸」**：註冊 macOS Services（`NSServices` in Info.plist，
   `NSMessage` 對到一個 `@objc func` 收 `NSPasteboard`）。重建 .app 後要
   `/System/Library/CoreServices/pbs -update` 重新註冊
2. **⌃⌥D 唸剪貼簿**、**⌃⌥S 框選畫面 OCR**：全域快捷鍵用 Carbon `RegisterEventHotKey`
   （不需要輔助使用權限）。OCR 走 `/usr/sbin/screencapture -i` 存暫存檔 →
   Vision `VNRecognizeTextRequest`（繁中＋英，離線）→ 推進佇列
3. **媒體鍵 F7/F8/F9**：頁面用 Media Session API 掛 `previoustrack`/`play`/`pause`/`nexttrack`，
   任何 App 在前景都吃得到（代價：唸的時候會搶走音樂 App 的那三顆）

---

## 階段 7：`/ctl` 外部暫停

`POST /ctl {"cmd":"pause"|"resume"}` → 經 `/events` 推 `ctl:pause` / `ctl:resume` 給頁面。
給錄音類工具用：它開始錄音時叫你閉嘴，錄完叫你續播。

**一定要做逾時自動解除**：pause 之後 3 分鐘沒等到 resume 就自己 resume。
對方 App 中途掛掉的話，你會永遠卡在暫停、之後推進來的訊息全部排隊不播——
症狀是「它突然變得不會唸了」，很難聯想到這裡。（我實踩過，見 `PITFALLS.md` 第 5 條。）
