# Aloud — 選單列朗讀窗（給 AI 蓋的規格書）

> 這個 repo **沒有原始碼**。它是一份施工圖：把整包丟給你的 AI（Claude Code / Codex / Cursor 都行），
> 它會照著蓋出一個能跑的版本，跑在你自己的機器上、用你自己的偏好。
>
> **English:** This repo ships no source. It ships a build spec dense enough that a coding agent
> can implement the whole tool from scratch. Read `BUILD.md`.

## 只想直接用（Mac）

不想自己蓋的話，有現成的版本。打開「終端機」，貼這一行：

```
curl -fsSL https://raw.githubusercontent.com/qwert2813434-ctrl/aloud/main/install.sh | bash
```

它會裝到 `~/Applications/導讀窗/`、裝好語音套件、打開 App；有裝 Claude Code 的話順手裝「導讀器」技能
（之後跟 Claude 說「使用導讀器回覆我」它就會唸）。更新也是貼同一行，你的破音字表會保留。
第一次如果跳出要裝「開發者工具」，按安裝，裝完再貼一次。Apple 晶片、Intel 都能跑，macOS 13 以上。

App 是我自己的版本、沒有付費簽章；介意的話用下面的方法自己蓋一個。

## 蓋出來的東西長怎樣

macOS 選單列上一個小圖示。貼一段文字（或任何 App 選字右鍵、或框選畫面 OCR），它用線上神經語音唸給你聽：

- **逐句串流**：照句號切句，第一句回來就播、背景預抓後兩句 → 首字延遲 ≈0.4 秒，跟文章多長無關
- **唸到哪句亮哪句**，點任一句從那句重播
- **速率用 `playbackRate`**，0.6×–2× 即時生效，不重新合成
- **中英混排自動換聲**：拉丁字母佔比高的句子換英文語音、語速微調
- **收件匣**：別的程式（例如你的 AI 助手）可以 `POST /push` 把文字推進來排隊唸
- **回聽與略過**：上一則／下一則、略過一句、一鍵跳到最新
- 翻譯、破音字表、媒體鍵（F7/F8/F9）全域控制

我自己拿它做什麼：我有閱讀障礙，聽比看快。AI 回我的每一則、看不完的文件、別人 App 裡的字，全推進去用聽的。

## 怎麼叫 AI 蓋

把這個資料夾放進一個空專案，然後跟你的 agent 說：

```
讀 BUILD.md，照第 0 到第 7 階段依序蓋。
每階段做完先跑 ACCEPTANCE.md 對應那節的驗收，過了才准做下一階段。
遇到 PITFALLS.md 提到的症狀先查那份，別自己重推。
```

一階段一階段做、每階段都有可驗收的產出——這比一次丟一大包規格讓它爆走可靠得多。

## 你要自己準備的

| 需要 | 說明 |
|---|---|
| macOS 13+ | 選單列 App 是 Swift/AppKit；純網頁版也能跑，功能少一半 |
| Python 3.9+ | 伺服器 |
| 一個 TTS 來源 | 見 `SPEC.md` 的「配音層是可換的」——預設用免金鑰的線上語音，離線要換 |
| Xcode Command Line Tools | 只有要蓋選單列 App 才需要（`swiftc`） |

## 授權與界線

- 這份規格書 MIT，隨便用（`LICENSE`）
- 規格裡**不綁死任何一家服務**。配音／翻譯都是可替換的介面，`SPEC.md` 有列替代方案（含完全離線的走法）
- 免金鑰的線上端點是給個人自用的方便，**不保證穩定、也不代表對方授權你商用**。要出貨請換成有正式條款的 TTS API
- 現成版本（Releases 的 `aloud-mac.zip`）也是 MIT；它只含程式本身，破音字表只附三行範例
- 這份 repo 不含任何錄音、任何個人資料、任何第三方 App 的資料

## 檔案

```
BUILD.md        施工順序（給 AI 讀的主文件）
SPEC.md         契約：HTTP 端點、切句規則、狀態機、權限
PITFALLS.md     十幾天撞出來的靜默地雷，這份最值錢
ACCEPTANCE.md   每階段的驗收條件
CLAUDE.md       agent 一進 repo 先讀的東西
install.sh      現成版本的一行安裝／更新
```
