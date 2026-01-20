# 🎨 UI Polish Roadmap - Visual Excellence

Mục tiêu: Giao diện **premium**, **immersive** như các VTT chuyên nghiệp (Roll20, Foundry VTT).

---

## Milestone P1: Design System Foundation

### Tasks
- [ ] **Color Palette**: Tạo theme D&D fantasy
  ```dart
  static const primaryGold = Color(0xFFD4AF37);
  static const darkParchment = Color(0xFF2C2416);
  static const bloodRed = Color(0xFF8B0000);
  static const arcaneBlue = Color(0xFF1E90FF);
  ```

- [ ] **Typography**: Import Google Fonts phù hợp
  - Headers: `Cinzel` (fantasy serif)
  - Body: `Lato` hoặc `Open Sans`
  - Combat Log: `Fira Code` (monospace)

- [ ] **Custom Theme**: Tạo `ThemeData` với colors, fonts, button styles

---

## Milestone P2: Combat Overlay Enhancement

### Current Issues
- Overlay đơn giản, không có animation
- Thiếu visual feedback khi attack/damage

### Tasks
- [ ] **Glassmorphism Effect**: Semi-transparent panels với blur
  ```dart
  ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(color: Colors.black.withOpacity(0.3)),
    ),
  )
  ```

- [ ] **Combat Log Animations**: 
  - Slide-in effect cho mỗi message mới
  - Color coding: Attack (đỏ), Heal (xanh lá), Miss (xám)

- [ ] **Initiative Tracker**: 
  - Token avatars thay vì chỉ text
  - Glow effect cho current turn
  - Smooth transition khi đổi lượt

- [ ] **Damage Numbers**: Floating text "+5 DMG" bay lên từ token

---

## Milestone P3: Hex Tile Aesthetics

### Tasks
- [ ] **Multi-Tile Tileset**: Tạo tileset với nhiều loại terrain
  - Grass, Water, Stone, Forest, Lava
  - Mỗi tile có variations (tránh lặp lại)

- [ ] **Tile Transitions**: Blend giữa 2 loại terrain khác nhau

- [ ] **Grid Style Options**:
  - Solid lines (hiện tại)
  - Dotted lines
  - No grid (clean look)
  - Highlighted edges only

- [ ] **Hex Hover Effect**: Highlight nhẹ khi mouse hover (Web)

---

## Milestone P4: Token Visuals

### Current Issues
- Token chỉ là hình tròn màu cyan
- Không có distinction giữa Player/Monster/NPC

### Tasks
- [ ] **Token Sprites**: Load ảnh avatar cho mỗi token
- [ ] **Token Rings**: 
  - Player: Gold ring
  - Monster: Red ring  
  - NPC: Green ring
  - Selected: Pulsing glow

- [ ] **Health Bars**: Mini HP bar dưới mỗi token
- [ ] **Condition Icons**: Hiển thị status effects (Poisoned, Stunned, ...)
- [ ] **Token Animation**: Subtle bob/float animation

---

## Milestone P5: Fog of War Polish

### Tasks
- [ ] **Gradient Edges**: Soft fade thay vì hard circle
  ```dart
  final gradient = RadialGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.7, 1.0],
  );
  ```

- [ ] **Explored vs Hidden**: 
  - Đen hoàn toàn: Chưa khám phá
  - Xám mờ: Đã khám phá nhưng không nhìn thấy hiện tại

- [ ] **Light Sources**: Torches/Spells tạo vùng sáng riêng

---

## Milestone P6: Responsive & Accessibility

### Tasks
- [ ] **Mobile Layout**: Rearrange UI cho màn hình nhỏ
- [ ] **Touch Gestures**: Pinch zoom, long press context menu
- [ ] **Dark/Light Mode**: Toggle theme
- [ ] **Font Scaling**: Accessibility options
- [ ] **Keyboard Shortcuts**: 
  - `Space`: End turn
  - `A`: Attack mode
  - `M`: Move mode
  - `Esc`: Cancel

---

## Visual Inspiration

| Feature | Reference |
|---------|-----------|
| Combat Log | Baldur's Gate 3 |
| Initiative Tracker | D&D Beyond |
| Token Design | Foundry VTT |
| Fog of War | Divinity: Original Sin 2 |
