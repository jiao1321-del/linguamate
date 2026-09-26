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

## 技術方向

- Flutter：iOS / Android 共用一套程式碼
- Supabase：之後儲存帳號、收藏和學習紀錄
- OpenAI API：之後加入翻譯、文法解釋、AI 對話和出題
- GitHub：版本管理

## 在電腦啟動

這個 Repository 目前先放 App 原始碼。第一次下載後，在專案資料夾執行：

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` 會補齊 Android、iOS、Web 等 Flutter 平台檔案，不會覆蓋目前的 `lib/` 程式碼。

## Roadmap

請看 [ROADMAP.md](ROADMAP.md)。
