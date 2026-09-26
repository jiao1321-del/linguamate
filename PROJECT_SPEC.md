# LinguaMate Product Spec

## 產品定位

LinguaMate 是私人語言學習助手，把真實生活中遇到的句子轉成自己的教材。

## 初始語言

- Traditional Chinese
- English
- Tagalog / Taglish

## 核心流程

輸入句子 → 三語解析 → 收藏 → 複習 → AI 對話應用

## V0.1 導覽

1. 首頁
2. 學習
3. AI
4. 收藏
5. 我的

## 後續資料模型

### learning_items

- id
- source_text
- source_language
- zh_text
- en_text
- tl_text
- explanation
- mastery_level
- created_at

### review_logs

- id
- learning_item_id
- result
- reviewed_at
- next_review_at
