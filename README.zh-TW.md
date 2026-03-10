# Slow Quit Apps

<p align="center">
  <img src="BuildAssets/AppIcon.png" width="128" height="128" alt="Slow Quit Apps 圖示">
</p>

<p align="center">
  <strong>防止意外按下 ⌘Q 導致應用程式退出的小工具</strong>
</p>

<p align="center">
  <a href="#功能特性">功能特性</a> •
  <a href="#安裝">安裝</a> •
  <a href="#使用方法">使用方法</a> •
  <a href="#設定">設定</a> •
  <a href="#建置">建置</a> •
  <a href="#授權條款">授權條款</a>
</p>

<p align="center">
  <a href="README.md">English</a> |
  <a href="README.zh-TW.md">繁體中文</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.ru.md">Русский</a>
</p>

---

## 功能特性

- 🛡️ **防止誤退出** - 需要長按 ⌘Q 才能退出應用程式
- ⏱️ **可調節時長** - 長按時間可在 0.3 秒到 3.0 秒之間調節
- 📋 **應用程式白名單** - 指定無需長按即可退出的應用程式
- 🌐 **多語言支援** - 支援英語、繁體中文、簡體中文、日語、俄語
- 🎨 **原生 macOS 設計** - 與系統介面無縫整合
- 💾 **設定持久化** - 設定儲存至 JSON 檔案

## 系統需求

- macOS 14.0 (Sonoma) 或更高版本
- 需要輔助使用權限

## 安裝

### 從 DMG 安裝（推薦）

1. 從 [Releases](../../releases) 下載最新版本
2. 開啟 DMG 檔案
3. 將 `SlowQuitApps.app` 拖曳到 `應用程式` 資料夾
4. 開啟應用程式並授予輔助使用權限

### 從原始碼建置

```bash
git clone https://github.com/030201xz/slow-quit-apps.git
cd slow-quit-apps
./build.sh
```

## 使用方法

### 首次設定

1. **授予輔助使用權限**
   - 開啟應用程式 → 系統設定會自動開啟
   - 前往：**隱私權與安全性 → 輔助使用**
   - 將 **SlowQuitApps** 開關開啟
   - 在設定視窗中點選 **重啟應用程式**

2. **設定選項**
   - 點選選單列圖示 → **設定**
   - 根據需要調整長按時間
   - 按需新增白名單應用程式

### 運作原理

| 操作 | 結果 |
|------|------|
| 短暫按下 ⌘Q | 無反應（退出已取消） |
| 長按 ⌘Q 達到設定時間 | 應用程式退出 |
| 提前鬆開 ⌘Q | 退出取消，進度重設 |
| 對白名單應用程式按 ⌘Q | 立即退出 |

## 設定

### 設定檔位置

設定儲存在：
```
~/Library/Application Support/SlowQuitApps/config.json
```

### 可用選項

| 設定 | 說明 | 預設值 |
|------|------|--------|
| `isEnabled` | 啟用/停用功能 | `true` |
| `holdDuration` | 長按 ⌘Q 時間（秒） | `1.0` |
| `launchAtLogin` | 開機自動啟動 | `false` |
| `showProgressAnimation` | 顯示進度環 | `true` |
| `language` | 介面語言 | `en` |
| `excludedApps` | 白名單應用程式 | 系統預設 |

### 支援的語言

| 程式碼 | 語言 |
|------|------|
| `en` | English |
| `zh-TW` | 繁體中文 |
| `zh-CN` | 简体中文 |
| `ja` | 日本語 |
| `ru` | Русский |

## 建置

### 前置需求

- Xcode 16.0+ 或 Swift 6.0+
- macOS 14.0+

### 建置指令

```bash
# 開發建置
swift build

# 發布建置（含 DMG）
./build.sh

# 建立應用程式圖示
swift scripts/generate-icon.swift
```

### 專案結構

```
slow-quit-apps/
├── Sources/SlowQuitApps/
│   ├── App/              # 應用程式入口
│   ├── Core/             # 核心功能
│   │   ├── Accessibility/  # 權限管理
│   │   └── QuitHandler/    # 退出進度 UI
│   ├── Features/         # 功能模組
│   │   └── Settings/       # 設定視窗
│   ├── Models/           # 資料模型
│   ├── State/            # 應用程式狀態管理
│   ├── Utils/            # 工具類別
│   │   └── I18n/           # 國際化
│   └── Resources/        # 語言資源檔案
├── Resources/            # 應用程式圖示、文件
└── scripts/              # 建置指令碼
```

## 疑難排解

### 重新建置後輔助使用權限重設

這是 ad-hoc 簽署導致的問題。建置指令碼包含自簽憑證機制來防止此問題。請執行：

```bash
./build.sh
```

首次執行會建立持久化簽署憑證。

### 應用程式無法攔截 ⌘Q

1. 檢查輔助使用權限是否已授予
2. 在設定中點選 **重啟應用程式**
3. 確保目標應用程式不在白名單中

## 貢獻

歡迎貢獻！請隨時提交 issues 或 pull requests。

## 授權條款

MIT 授權條款 - 詳見 [LICENSE](LICENSE)

---

<p align="center">
  用 ❤️ 為 macOS 打造
</p>
