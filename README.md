# 💎 Sell Ores Script Hub (Fluent UI)

Script Hub hiện đại, mượt mà và đầy đủ tính năng nhất dành cho tựa game **[💎] Sell Ores ⛏️** trên Roblox.  
- **Place ID:** `122572082932179`
- **Nhóm phát triển game:** The Ore Drillers
- **Giao diện:** Fluent UI (Phong cách Windows 11 Fluent Design)
- **Tương thích:** Hầu hết các Executor PC & Mobile hiện nay (Solara, Wave, Delta, Codex, Hydrogen, Arceus X, Fluxus, v.v.).

---

## 🚀 Cách Sử Dụng (Quick Start - Chỉ 1 dòng lệnh)

Nếu Executor của bạn bị giới hạn số dòng dán (dưới 50 dòng), bạn chỉ cần dán đúng **1 dòng** dưới đây:

### 1. Chạy Script Hub Chính (Sell Ores Hub v7.5 Ultimate PRO):
```lua
loadstring(game:HttpGet("https://paste.rs/QRl1T"))()
```

### 2. Công Cụ Soi Chi Tiết Nút Auto Roll & Remote Roll (AutoRoll Deep Spy):
```lua
loadstring(game:HttpGet("https://paste.rs/NepCy"))()
```

### 3. Công Cụ Soi & Test Nút Apply Gems (Decompile & Test Remote):
```lua
loadstring(game:HttpGet("https://paste.rs/u01uF"))()
```

### 4. Công Cụ Soi Chi Tiết Cơ Chế Apply Gems & Activate Ore (Deep Spy):
```lua
loadstring(game:HttpGet("https://paste.rs/Ztv68"))()
```

### 2. Công Cụ Quét Toàn Bộ Tên Quặng Trong Game:
```lua
loadstring(game:HttpGet("https://paste.rs/z9fUO"))()
```

### 3. Chạy Trình Quét Nhanh (Scanner):
```lua
loadstring(game:HttpGet("https://paste.rs/0cz9A"))()
```

> **Phím tắt ẩn/hiện Menu Fluent:** `RightControl` (hoặc đổi trong tab **Settings**).

---

## ✨ Danh Sách Tính Năng

### 1. 💎 Auto Ores (Tự động hóa khoáng sản)
- **Auto Roll:** Tự động Roll quặng liên tục kèm thanh trượt điều chỉnh tốc độ (Delay).
- **Auto Buy Rolled Ores:** Tự động mua/nhận quặng sau khi roll ra.
- **Auto Place Ores:** Tự động đặt quặng vào các slot mỏ trống trong căn cứ.
- **Auto Sell:** Tự động bán quặng liên tục (hỗ trợ cả Remote Call và tự động kích hoạt Sell Zone / Prompt).

### 2. 🤖 Base & Drones (Nâng cấp)
- **Auto Upgrade Drones:** Tự động nâng cấp Drone thu hoạch khi đủ tiền.
- **Auto Expand Slots:** Tự động mua mở khóa thêm các vị trí slot mỏ mới.
- **1-Click Quick Upgrade:** Nâng cấp nhanh toàn bộ các trạm có thể nâng cấp.

### 3. 📍 Teleports (Dịch chuyển tức thời)
- Dịch chuyển về **Căn cứ cá nhân (My Plot)**.
- Dịch chuyển đến **Khu vực Bán (Sell Zone)**.
- Dịch chuyển đến **Máy Roll Quặng (Roll Station)**.
- Dịch chuyển đến bất kỳ người chơi nào trong server qua menu Dropdown tự động cập nhật.

### 4. 🏃 Player & Movement
- **WalkSpeed (Tốc độ chạy):** Chỉnh tốc độ từ 16 đến 200, có cơ chế Heartbeat chống server reset tốc độ.
- **JumpPower (Nhảy cao):** Chỉnh lực nhảy từ 50 đến 350.
- **Infinite Jump:** Nhảy vô hạn trên không trung.
- **Noclip:** Đi xuyên mọi vật cản và tường.
- **Fly Mode:** Bay tự do bằng các phím `W, A, S, D` + `Space` (bay lên) + `LeftShift` (hạ xuống).
- **Anti-AFK 24/7:** Tự động bắt sự kiện `Idled` của Roblox để treo máy không bị văng sau 20 phút.

### 5. 👁️ Visuals (ESP)
- **Player ESP:** Hiển thị khung Highlight phát sáng xuyên tường của tất cả người chơi khác.

### 6. 🎁 Misc & Codes (Mã quà tặng & Tiện ích)
- **Auto Redeem Codes:** Nút 1-click tự động nhập danh sách mã code: `RELEASE`, `EXPANSION`, `ORES`, `UPDATE1`...
- **FPS Booster / Low GFX:** Tắt bóng đổ, khử hiệu ứng hạt giúp máy treo nhiều tài khoản mượt mà, tiết kiệm RAM/CPU.
- **Server Hop / Rejoin:** Đổi server mới hoặc vào lại server hiện tại.

### 7. 🔍 Inspector (Trình soi Remote & Debug)
- Xem thông tin các RemoteEvent / RemoteFunction đang kết nối.
- Nút **Re-Scan** để tự động dò lại hệ thống nếu vừa chuyển khu vực.

---

## 🛠️ Công Cụ Phụ Trợ: `scanner.lua`
Nếu game vừa có bản cập nhật lớn làm thay đổi cấu trúc:
- Bạn chỉ cần chạy script [`scanner.lua`](./scanner.lua).
- Script sẽ quét sạch toàn bộ Remote, ProximityPrompt, Vùng bán và Plot, in chi tiết ra Console (nhấn **F9**) và tự động copy vào Clipboard để dễ dàng kiểm tra.
