# 💎 Sell Ores Script Hub (Fluent UI) - v7.8 Ultimate PRO

Script Hub hiện đại, mượt mà và tự động hóa toàn diện nhất dành cho tựa game **[💎] Sell Ores ⛏️** trên Roblox.  
- **Place ID:** `122572082932179`
- **Giao diện:** Fluent UI (Phong cách Windows 11 Fluent Design)
- **Tương thích:** Tất cả các Executor PC & Mobile (Delta, Wave, Codex, Fluxus, Arceus X, Solara, v.v.).

---

## 🚀 Cách Sử Dụng (Chỉ 1 Dòng Lệnh - Tự Động Cập Nhật Vĩnh Viễn)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/shinn1603/Ores_Sell_Roblox_Script/main/main.lua"))()
```

*(Link dự phòng: `loadstring(game:HttpGet("https://dpaste.com/7BGB5UP77.txt"))()`)*

---

## 📂 Cấu Trúc Dự Án (Modular Architecture)

Dự án đã được chia thành các module chuyên biệt trong thư mục `src/`:

```
ORES_Script/
├── .gitignore
├── README.md
├── build.py                -- Script tự động đóng gói src/ thành main.lua
├── main.lua                -- File tổng hợp đã được bundle sẵn để chạy loadstring
└── src/
    ├── OresData.lua        -- 81 loại quặng và bảng alias
    ├── State.lua           -- Quản lý biến trạng thái & cài đặt mặc định
    ├── Utils.lua           -- Định vị Base, Teleport, ProximityPrompt, Quản lý Tool
    ├── AutoRoll.lua        -- Tự gạt cần, bấm START & tự đóng bảng Auto Roller
    ├── SmartFuser.lua      -- Nạp quặng thông minh 5 node & bảo vệ quặng xịn 100%
    ├── MoneyPipeline.lua   -- Đào mỏ -> Nung lò -> Bán quặng khép kín
    ├── ShowcaseBuff.lua    -- Duy trì Ore Showcase Buff x2.75 24/7 & Apply Gems
    ├── ConfigManager.lua   -- Hệ thống lưu/tải cấu hình JSON độc lập
    └── UI.lua              -- Giao diện Fluent UI & Nút tròn nổi (Floating Button)
```

---

## 🛠️ Đóng Gói Lại (Build)

Mỗi khi bạn chỉnh sửa bất kỳ file nào trong thư mục `src/`, chỉ cần chạy:
```bash
python build.py
```
File `main.lua` sẽ tự động được cập nhật lại ngay lập tức!
