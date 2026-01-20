# 🚀 Optimization Roadmap - Performance & FPS

Mục tiêu: Đạt **60 FPS ổn định** trên Web (CanvasKit) với bản đồ 100x100+ ô.

---

## Milestone O1: Render Pipeline Optimization

### Vấn đề hiện tại
- `shouldRepaint()` trả về `false` nhưng widget vẫn rebuild do `setState()` gọi liên tục
- Vẽ lại toàn bộ map mỗi frame thay vì chỉ những gì thay đổi
- Debug overlay vẽ text cho MỖI ô hex -> rất chậm

### Giải pháp
- [ ] **Tách Layer**: Chia thành 3 `RepaintBoundary` riêng biệt:
  - Static Layer (Terrain - chỉ vẽ 1 lần)
  - Dynamic Layer (Tokens, Path Highlight)
  - UI Layer (Debug Text - có thể toggle off)
  
- [ ] **Cache Static Tiles**: Sử dụng `Picture.toImage()` để render terrain thành 1 ảnh duy nhất
  ```dart
  ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas canvas = Canvas(recorder);
  // Draw all hexes once
  ui.Picture picture = recorder.endRecording();
  ui.Image cachedImage = await picture.toImage(width, height);
  ```

- [ ] **Disable Debug Text**: Thêm flag `showDebugGrid` để toggle

---

## Milestone O2: Viewport Culling (Chỉ vẽ những gì nhìn thấy)

### Vấn đề hiện tại
- Vẽ tất cả (2*radius+1)^2 = 441 ô dù chỉ hiển thị ~50 ô trên màn hình

### Giải pháp
- [ ] **Lấy Visible Rect từ InteractiveViewer**:
  ```dart
  final Matrix4 transform = _transformationController.value;
  final Rect viewportRect = transform.inverted.transformRect(screenRect);
  ```

- [ ] **Tính toán Hex Range cần vẽ**:
  ```dart
  Hex topLeft = layout.pixelToHex(viewportRect.topLeft).round();
  Hex bottomRight = layout.pixelToHex(viewportRect.bottomRight).round();
  // Chỉ loop từ topLeft.q đến bottomRight.q
  ```

- [ ] **Test**: Zoom out tối đa, đo FPS trước/sau

---

## Milestone O3: FogOfWarPainter Optimization

### Vấn đề hiện tại
- `FogOfWarPainter` vẽ Path lớn (~2000x2000) mỗi frame
- Không đồng bộ với camera transform

### Giải pháp
- [ ] **Chỉ vẽ lại khi Token di chuyển** (không vẽ mỗi frame)
- [ ] **Sử dụng BlendMode thay vì Path**:
  ```dart
  // Thay vì evenOdd Path phức tạp
  canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstOver);
  // Vẽ vùng sáng
  canvas.restore();
  ```
- [ ] **Sync với InteractiveViewer transform**: Đặt trong cùng một `Transform` widget

---

## Milestone O4: SignalR & State Management

### Vấn đề hiện tại
- `setState()` gọi mỗi khi nhận event -> rebuild toàn bộ widget tree
- Không có debounce cho token move events

### Giải pháp
- [ ] **Chuyển sang Provider/Riverpod**: Tách game state ra khỏi widget
- [ ] **Selective Rebuild**: Chỉ rebuild phần cần thiết
  ```dart
  Consumer<TokenProvider>(
    builder: (context, tokens, child) => CustomPaint(...)
  )
  ```
- [ ] **Debounce Token Updates**: Gộp nhiều updates thành 1 repaint

---

## Milestone O5: Web-Specific Optimizations

### Giải pháp
- [ ] **Compile với `--release`**: `flutter build web --release`
- [ ] **Enable Tree Shaking**: Loại bỏ code không dùng
- [ ] **Lazy Loading**: Chỉ load assets khi cần
- [ ] **WebWorker cho Pathfinding**: Tính A* trong background thread

---

## Benchmark Targets

| Metric | Current | Target |
|--------|---------|--------|
| FPS (100 hexes) | ~30 | 60 |
| FPS (1000 hexes) | ~15 | 55 |
| Initial Load | ~3s | <1s |
| Memory Usage | Unknown | <200MB |
