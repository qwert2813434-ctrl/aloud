# PITFALLS — 靜默地雷

共同點：**它們都不會噴錯**。所以先看這份，不要自己重推一遍。

### 1. `pkill -f "路徑/server.py"` 殺不掉伺服器

程序名裡只有 `server.py`，**不含路徑**。舊程序繼續佔著埠服務舊版頁面，
症狀是「我改了程式碼但完全沒生效」。

```bash
for pid in $(lsof -ti tcp:8765); do kill $pid; done   # 用埠殺
```

殺完一定要 `pgrep` 驗證。另外如果你機器上有第二支同名 `server.py`（例如同時在蓋語音輸入那支），
`pkill -f "server.py$"` 會把兩支一起殺掉。

### 2. 寫入新訊息時 `show()` 要在 `text.value = …` 之前

`show()` 內部會 stash 輸入框內容。順序反了會把你剛寫進去的值蓋成空白——
**畫面全空、主控台零錯誤**。

### 3. `.app` 裡直接放 shell script 當 executable 會被整組殺掉

用 `open` 啟動時 LaunchServices 判定「沒完成啟動」（`-1712`），連同它起的伺服器一起收走。
解法：包成 `osacompile` 的 applet，再 `nohup` 把真正的程序丟出去。

### 4. `<audio>` 播放期間銷毀 WKWebView = 聲音斷掉

面板收起來要保留 view，只是隱藏視窗。

### 5. `ctl:pause` 沒等到 `resume` 會永久卡住

對方 App 中途掛掉，你就再也不唸了，而且新訊息全部安靜排隊。
**pause 後 3 分鐘沒 resume 就自動解除**。

### 6. 暫停旗標的 TDZ

那顆 `recPause` 之類的旗標如果宣告在第一次呼叫 `pullInbox()` 之後，
開頁第一次拉佇列會靜靜炸掉（`ReferenceError` 被 fetch 的 catch 吃掉），表現是「開起來就是不動」。
→ 寫一支**開頁煙霧測試**（載入頁面、跑一次初始化、檢查有沒有未捕捉錯誤），改頁面後強制先跑它。

### 7. 選單列圖示被瀏海吃掉

⌘ 拖到右邊，配 `autosaveName` 記住位置。

### 8. 沒聲音先查這三個

網路（線上 TTS）／語音代號打錯（回空音檔）／`playbackRate` 被設成 0。
把「音檔為空」做成明確錯誤，不要靜靜略過。

### 9. 線上 TTS 偶爾一句卡十幾秒

Edge 語音端點每 7～20 句會有一句接了連線卻 9–20 秒不回音檔，畫面停在「合成中」。
另外它有一個 IPv6 位址整個連不上，走預設每句白耗 0.25–0.45 秒握手。
→ **強制 IPv4、連線與收包各設 3 秒逾時、最多重試 3 次**。實測中位數 1.07s→0.72s、最慢 10.7s→1.1s。

### 10. Edge 語音整批 403：微軟換了主機（2026-10-12）

那天起 `speech.platform.bing.com` 的合成一律在 WebSocket 握手回 `403 Invalid response status`，
`edge-tts` 7.2.8（當時最新）全世界一起壞。表面錯誤常常是 `RuntimeError: Session is closed`，看不出是 403。
不是時鐘、不是假冒的 Edge 版號（改到 150 一樣 403）。
→ 改走 Edge 155 用的新主機，舊的 client token 改當 `Ocp-Apim-Subscription-Key` 帶；聲音清單仍在舊主機。
上游修正在 edge-tts PR #491，套件出新版前在你的伺服器 import 之後覆寫：

```python
import edge_tts, edge_tts.communicate
edge_tts.communicate.WSS_URL = ("wss://api.msedgeservices.com/tts/cognitiveservices/websocket/v1"
                                "?Ocp-Apim-Subscription-Key=" + edge_tts.constants.TRUSTED_CLIENT_TOKEN)
```

教訓同第 8 條：把「合成失敗」的真正原因（狀態碼）顯示出來，別只顯示最後一層例外。
