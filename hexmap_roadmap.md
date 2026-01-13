Đây là **Lộ trình Triển khai Kỹ thuật (Technical Implementation Roadmap)** chi tiết dành riêng cho việc xây dựng và tối ưu hóa hệ thống hiển thị bản đồ lục giác (Hexmap Renderer) trong Flutter. Lộ trình này được thiết kế để đảm bảo hiệu năng đạt 60 FPS trên cả Web (CanvasKit) và Mobile, ngay cả với các bản đồ lớn (100x100 trở lên).

### ---

**🗺️ Giai đoạn 1: Lõi Toán Học & Cấu Trúc Dữ Liệu (The Mathematical Core)**

*Mục tiêu: Xây dựng nền tảng tính toán chính xác, chưa cần vẽ gì cả.*

**A. Hệ tọa độ & Lưu trữ**

1. **Thiết lập Class Hex:**  
   * Sử dụng hệ tọa độ **Cube Coordinates** (q, r, s) cho constructor để đảm bảo tính nhất quán (q \+ r \+ s \= 0).  
   * Cung cấp getter/setter dạng **Axial** (q, r) để tiện sử dụng.  
   * Implement các phép toán vector: add, subtract, scale, distance.  
2. **Chuyển đổi Không gian (Spatial Conversion):**  
   * Viết class Layout chứa thông tin về kích thước hex (size), gốc tọa độ (origin) và loại hex (Pointy-topped \- đỉnh nhọn).  
   * Hàm hexToPixel(Hex h): Trả về tọa độ tâm Offset(x, y).  
   * Hàm pixelToHex(Offset p): Trả về Hex (số thực).  
   * Hàm hexRound(FractionalHex h): Làm tròn tọa độ thực về tọa độ nguyên gần nhất (quan trọng để xử lý click chuột).  
3. **Cấu trúc Dữ liệu Bản đồ (Grid Storage):**  
   * Thay vì dùng Map\<Hex, Tile\>, hãy dùng **Mảng 1 chiều (List\<int\>)**.  
   * Viết hàm ánh xạ hash(q, r) để chuyển tọa độ 2D thành index 1D. (Ví dụ: index \= r \* width \+ (q \+ r/2) cho bản đồ chữ nhật).

**💡 Checkpoint:** Viết Unit Test: Nhập tọa độ pixel \-\> Chuyển sang Hex \-\> Chuyển ngược lại pixel. Sai số phải \< 0.001.

### ---

**🎨 Giai đoạn 2: Engine Kết xuất Cơ bản (The Rendering Engine)**

*Mục tiêu: Vẽ được lưới hex lên màn hình và di chuyển được camera.*

**B CustomPainter & Camera**

1. **Thiết lập InteractiveViewer:**  
   * Dùng widget này làm cha của CustomPaint.  
   * Cấu hình constrained: false để canvas có thể lớn vô hạn.  
   * Đặt boundaryMargin để người dùng có thể kéo bản đồ ra giữa màn hình.  
2. **HexPainter Cơ bản (Debug Mode):**  
   * Tạo CustomPainter. Trong hàm paint():  
   * Dùng canvas.drawPath để vẽ viền lục giác (chỉ để debug, chưa tối ưu).  
   * Vẽ text tọa độ (q, r) lên từng ô để kiểm tra toán học.  
3. **Xử lý Assets:**  
   * Load tileset (ảnh chứa nhiều hình hex nhỏ) vào bộ nhớ dưới dạng ui.Image.  
   * Viết hàm cắt Rect từ tileset dựa trên ID của loại đất (Cỏ \= 0, Nước \= 1).

**💡 Checkpoint:** Bạn thấy một lưới tổ ong khổng lồ, có thể zoom in/out mượt mà bằng hai ngón tay hoặc lăn chuột.

### ---

**🚀 Giai đoạn 3: Tối ưu Hóa Hiệu Năng (Optimization Pipeline)**

*Mục tiêu: Chuyển từ drawPath sang drawAtlas để chịu tải 10,000 ô.*

**Tuần 3: Batching & Culling**

1. **Triển khai drawAtlas:**  
   * Thay vòng lặp drawPath bằng một lệnh canvas.drawAtlas duy nhất.  
   * Tạo trước (Pre-calculate) danh sách RSTransform (vị trí, xoay) và Rect (vùng ảnh nguồn) cho toàn bộ bản đồ.  
   * Chỉ cập nhật danh sách này khi bản đồ thay đổi, không tính toán lại mỗi frame.  
2. **Viewport Culling (Loại bỏ ô khuất):**  
   * Trong hàm paint, lấy canvas.getTransform() để biết camera đang nhìn vùng nào.  
   * Tính toán vùng Rect nhìn thấy được \-\> Chuyển đổi 4 góc Rect đó sang tọa độ Hex (q\_min, q\_max, r\_min, r\_max).  
   * Chỉ render các ô nằm trong khoảng index này.  
   * *Kết quả:* Dù map 1 triệu ô, nếu màn hình chỉ hiện 50 ô, ta chỉ vẽ 50 ô.  
3. **Raster Cache:**  
   * Bọc lớp nền (Background Layer) bằng widget RepaintBoundary. Điều này bảo Flutter chụp ảnh canvas lại. Khi di chuyển camera, nó chỉ di chuyển bức ảnh đó thay vì vẽ lại từng vector.

**💡 Checkpoint:** FPS giữ vững ở 60Hz trên Chrome (CanvasKit) khi zoom out toàn bộ bản đồ 100x100.

### ---

**👆 Giai đoạn 4: Tương tác & Gameplay (Interaction Layer)**

*Mục tiêu: Người dùng click vào đâu, game biết chính xác ô đó.*

**Tuần 4: Input & Pathfinding**

1. **Matrix Inversion (Nghịch đảo Ma trận):**  
   * Sử dụng TransformationController của InteractiveViewer.  
   * Khi có sự kiện onTapUp, lấy tọa độ màn hình details.localPosition.  
   * Nhân tọa độ đó với **nghịch đảo** của ma trận biến đổi (controller.value.inversed) để lấy tọa độ thế giới thực (World Coordinate).  
   * Gọi pixelToHex để lấy ô lục giác được chọn.  
2. **Highlight Selection:**  
   * Không vẽ lại cả bản đồ khi chọn ô. Dùng một CustomPainter riêng (lớp phủ \- Overlay) nằm đè lên map để vẽ viền sáng cho ô đang chọn.  
3. \**Pathfinding (A*):\*\*  
   * Cài đặt thuật toán A\* trên đồ thị Hex.  
   * Vẽ đường đi bằng một CustomPainter lớp phủ khác.

### ---

**🛠️ Giai đoạn 5: Công cụ & Mở rộng (Tools & Polish)**

*Mục tiêu: Biến tech-demo thành game thực tế.*

**Tuần 5: Tiled & Fog of War**

1. **Tiled Integration:**  
   * Sử dụng gói xml để parse file .tmx (nếu không dùng Flame).  
   * Map dữ liệu từ Tiled (Layer ID) sang mảng List\<int\> của engine.  
2. **Fog of War (Sương mù):**  
   * Sử dụng drawVertices với BlendMode.modulate.  
   * Tạo một lưới các đỉnh (vertices) phủ lên bản đồ. Đỉnh nào nhìn thấy thì màu Trắng (alpha 0), đỉnh nào khuất thì màu Đen (alpha 255).  
   * Flutter sẽ nội suy màu giữa các đỉnh, tạo hiệu ứng sương mù mượt mà (smooth lighting).

### ---

**📦 Code Snippet Quan Trọng: drawAtlas Template**

Đây là cấu trúc của hàm paint tối ưu nhất cho Hexmap trong Flutter:

Dart

class HexMapPainter extends CustomPainter {  
  final ui.Image atlas; // Ảnh chứa toàn bộ tileset  
  final List\<RSTransform\> transforms; // Vị trí các ô trên màn hình  
  final List\<Rect\> sources; // Vị trí cắt ảnh trong atlas tương ứng  
  final Rect visibleBounds; // Vùng nhìn thấy (để culling)

  HexMapPainter({  
    required this.atlas,  
    required this.transforms,  
    required this.sources,  
    required this.visibleBounds,  
  });

  @override  
  void paint(Canvas canvas, Size size) {  
    // Chỉ vẽ một lệnh duy nhất cho hàng ngàn ô  
    canvas.drawAtlas(  
      atlas,  
      transforms,  
      sources,  
      null, // colors (dùng nếu muốn tint màu)  
      BlendMode.dst,  
      visibleBounds, // Culling Rect: Flutter sẽ tự bỏ qua các ô ngoài vùng này  
      Paint(),  
    );  
  }

  @override  
  bool shouldRepaint(HexMapPainter oldDelegate) {  
    // Chỉ vẽ lại khi camera di chuyển hoặc dữ liệu map thay đổi  
    return oldDelegate.visibleBounds\!= visibleBounds;  
  }  
}

Bạn có thể bắt đầu ngay với **Giai đoạn 1**. Hãy tạo một class Hex trong Dart và viết unit test cho nó trước khi đụng vào UI. Bạn có cần tôi viết giúp class Hex chuẩn toán học không?