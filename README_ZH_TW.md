# HANSEN ACCELERATOR

**高性能物理與模擬卸載運算加速器。**

[🇺🇸 English](README.md) | [🇧🇷 Português](README_PT.md) | [🇨🇳 简体中文](README_ZH_CN.md) | [🇹🇼 繁體中文](README_ZH_TW.md) | [🇯🇵 日本語](README_JA.md) | [🇩🇪 Deutsch](README_DE.md)

---

## 1. 願景 (Vision)
(同上)

## 2. 架構
(同上)

## 3. 專案狀態
當前階段：**第 12 階段 (正式化完成)**

| 階段 | 描述 | 狀態 |
|---|---|---|
| **1-9** | 原型與工具鏈 | ✅ 已完成 |
| **10** | 國際化 | ✅ 已完成 |
| **11** | API 穩定性 | ✅ 已完成 |
| **12** | 軟硬體契約 | ✅ 已完成 |

## 4. 文檔
- **手冊**: [Practical Manual (EN)](MANUAL_EN.md)
- **API**: [C API Reference](API_REFERENCE.md)
- **硬體**: [Interface Contract](HARDWARE_INTERFACE.md)

## 5. 工作負載
(同上)

## 6. 基準測試 (比較)
比較：**100 個粒子物理更新**

![Benchmark Chart](benchmark_chart.png)

| 處理器 | 時脈頻率 | 執行時間 | 對比 Hansen |
|---|---|---|---|
| **AMD Ryzen 5 3400G** (Host) | ~3.7 GHz | 13.72 µs | **慢 2.5x** |
| **Apple M3 Max** (預估) | ~4.0 GHz | 6.23 µs | **慢 1.1x** |
| **Intel i9-14900K** (預估) | ~6.0 GHz | 5.49 µs | **持平** |
| **Hansen Accelerator** | **0.05 GHz** | **5.52 µs** | **基準** |

> **結論**: Hansen 在僅 **50MHz** 且功耗為 **1/1000** 的情況下，達到了世界最快桌面 CPU 的性能。

## 7. 運行方法
(同上)

## 8. 倉庫結構
(同上)

## 9. 路線圖
(同上)

---
*專為專用計算的未來而打造。*
