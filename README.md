# LinguaMate

LinguaMate 是一個個人語言學習 App，第一階段以 **中文、English、Tagalog / Taglish** 為核心。

目標不是只做翻譯，而是把你在聊天、工作或生活中真的遇到的句子，變成可以收藏、複習和練習的教材。

## V0.1

目前已建立 Flutter 第一版 UI 骨架：

- 首頁學習 Dashboard
- 句子學習 / 三語解析
- AI 對話教練雛形
- 收藏頁
- 個人學習統計頁
- 底部五分頁導覽

目前使用示範資料，不需要 API Key 就能先跑畫面。

## 全手機開發模式

目前專案以 **iPhone + ChatGPT + GitHub** 為主要開發流程。

每次程式碼合併到 `main` 後，GitHub Actions 會自動：

1. 安裝 Flutter stable
2. 執行 `flutter pub get`
3. 執行程式碼分析與測試
4. 建置 Flutter Web release
5. 將 GitHub Pages 專案路徑設定為 `/linguamate/`
6. 產生 Web App / PWA 所需檔案與離線快取
7. 發布到 GitHub Pages

預設 Pages 網址：

`https://jiao1321-del.github.io/linguamate/`

> GitHub Free 帳號若 Repository 為 private，GitHub Pages 無法使用；可將 Repo 改為 public，或使用支援 private Pages 的 GitHub 方案。

## 技術方向

- Flutter：Web / iOS / Android 共用一套程式碼
- PWA：可從 Safari 加到 iPhone 主畫面
- GitHub Actions：自動測試、建置與發布
- GitHub Pages：Web 版託管
- Supabase：之後儲存帳號、收藏和學習紀錄
- OpenAI API：之後加入翻譯、文法解釋、AI 對話和出題

## 本機開發（非必要）

如果未來有使用電腦，也可以執行：

```bash
flutter pub get
flutter run
```

## Roadmap

請看 [ROADMAP.md](ROADMAP.md)。
