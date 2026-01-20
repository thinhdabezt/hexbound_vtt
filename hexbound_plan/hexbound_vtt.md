# **Project: Hexbound VTT**

Role: Technical Design Document (TDD)  
Version: 1.0.0 (Production Target)  
Architect: Flutter &.NET Expert

## ---

**1\. Tổng quan Dự án (Executive Summary)**

**Hexbound VTT** là một nền tảng Virtual Tabletop (VTT) mã nguồn mở, hiệu năng cao dành cho Dungeons & Dragons 5e, sử dụng api từ 5e-bits.github.io/docs/introduction. Khác với các đối thủ sử dụng HTML DOM nặng nề, Hexbound sử dụng **CanvasKit (Flutter)** để render đồ họa 60fps và **SignalR (MessagePack)** để đồng bộ trạng thái thời gian thực với độ trễ \<50ms.

### **Mục tiêu Cốt lõi**

1. **Immersive:** Bản đồ lục giác mượt mà, hỗ trợ Fog of War và hiệu ứng hạt (Particles).  
2. **Real-time:** Đồng bộ tức thì vị trí, thanh máu, và kết quả xúc xắc.  
3. **Automated:** Tự động tính toán Attack Roll, Saving Throw dựa trên chỉ số nhân vật (không cần tính nhẩm).

## ---

**2\. Kiến trúc Hệ thống (System Architecture)**

Chúng ta sử dụng mô hình **Hybrid Real-time Architecture**:

* **Client:** Flutter Web (CanvasKit Renderer).  
  * *Game Loop:* Flame Engine.  
  * *UI Overlay:* Flutter Widgets (BLoC State Management).  
* **Backend:** ASP.NET Core 8 Web API.  
  * *Communication:* SignalR (WebSockets) với MessagePack Protocol.  
  * *Logic:* Server-authoritative (Server quyết định kết quả, Client chỉ hiển thị).  
* **Database:**  
  * **Hot Storage (Redis):** Lưu trạng thái bàn cờ (Board State), Vị trí Token, Lượt đi.  
  * **Cold Storage (SQL Server):** Lưu User, Character Sheet, Monster Manual, Campaign Logs.

## ---

**3\. Thiết kế Cơ sở dữ liệu (Database Schema)**

D\&D 5e có cấu trúc dữ liệu rất phức tạp. Chúng ta sẽ sử dụng chiến lược **Hybrid Relational-JSON**.

* Các trường cố định (ID, Name, Level) dùng cột SQL truyền thống để Indexing nhanh.  
* Các trường động (Attributes, Spells, Inventory, Features) lưu dưới dạng **JSONB** (JSON Binary) để linh hoạt.

### **3.1 Entity Relationship Diagram (Conceptual)**

Đoạn mã

erDiagram  
    Users |

|--o{ Campaigns : "owns"  
    Users |

|--o{ Characters : "creates"  
    Campaigns |

|--|{ CampaignCharacters : "includes"  
    Characters |

|--|{ CampaignCharacters : "joins"  
      
    Campaigns {  
        Guid Id  
        String Name  
        String JoinCode  
        Json Settings "Rules variations"  
    }  
      
    Characters {  
        Guid Id  
        String Name  
        String Class  
        Int Level  
        Json Stats "STR, DEX, CON..."  
        Json Inventory "Items list"  
        Json SpellSlots "Available slots"  
    }

    Monsters {  
        Guid Id  
        String Name  
        String CR "Challenge Rating"  
        String Type  
        Json Stats "AC, HP, Speed"  
        Json Actions "Multiattack, Breath Weapon"  
    }

### **3.2 Chi tiết Bảng & Redis Keys**

#### **A. SQL Server (Persistence)**

**Table: Monsters** (Dữ liệu tham chiếu)

* Id (PK, Guid): Unique ID.  
* Name (NVARCHAR): "Ancient Red Dragon".  
* CR (FLOAT): 24.0 (Dùng để filter quái theo độ khó).  
* Data (NVARCHAR(MAX) / JSON): Chứa toàn bộ chỉ số chi tiết.  
  JSON  
  {  
    "ac": 22,  
    "hp": "28d20 \+ 252",  
    "speed": { "walk": 40, "fly": 80 },  
    "actions":  
  }

  *Lý do:* Mỗi quái vật có số lượng Action khác nhau. Tạo bảng riêng cho Actions sẽ làm query rất chậm. Lưu JSON giúp load 1 dòng là có đủ data.

**Table: Campaigns**

* Id (PK, Guid).  
* HostId (FK \-\> Users).  
* CurrentMapState (JSON): Snapshot trạng thái cuối cùng của game để restore khi server restart.

#### **B. Redis (Real-time State)**

Redis không dùng bảng, dùng Key-Value.

* **Room State:** room:{campaign\_id}:state  
  * *Type:* Hash  
  * *Content:*  
    * turn\_order: List ID nhân vật theo thứ tự Initiative.  
    * current\_actor: ID nhân vật đang có lượt.  
    * round: Số thứ tự vòng đấu.  
* **Entity Position:** room:{campaign\_id}:entity:{entity\_id}  
  * *Type:* String (MessagePack bytes)  
  * *Content:* { x: 10, y: 5, hp\_current: 45, conditions: \["prone"\] }  
  * *Lý do:* Tách riêng từng entity để khi 1 con di chuyển, ta chỉ update 1 key nhỏ, không cần ghi đè cả room state.

## ---

**4\. Lộ trình Triển khai (Production Roadmap)**

### **🟢 Giai đoạn 1: Core Foundation (Tuần 1-3)**

*Mục tiêu: Client và Server "bắt tay" nhau.*

* **Milestone B1 (Backend Skeleton):**  
  * Project setup: .NET 8 WebAPI, EF Core, SignalR.  
  * Config **MessagePack Protocol** cho SignalR.  
  * Endpoint POST /api/auth/login (JWT Token).  
* **Milestone F1 (Frontend Shell):**  
  * Flutter Web setup với cờ \--web-renderer canvaskit.  
  * Cài đặt flame, flame\_tiled.  
  * Kết nối SignalR Client và log Connected ra console.

### **🟢 Giai đoạn 2: The "Brain" (Data & Rules) (Tuần 4-6)**

*Mục tiêu: Dữ liệu game có ý nghĩa.*

* **Milestone B2 (Data Ingestion):**  
  * Worker Service crawl API 5e-bits \-\> Lưu vào SQL Table Monsters & Spells.  
  * Xử lý JSON Parsing để tách 2d6 \+ 5 thành struct {Dice: 2, Sides: 6, Bonus: 5}.  
* **Milestone B3 (Dice Engine):**  
  * API RequestRoll(formula) \-\> Server gieo \-\> Trả về kết quả (chống cheat).  
  * Validate công thức xúc xắc (Regex/Parser).

### **🟢 Giai đoạn 3: The "Flesh" (Visuals) (Tuần 7-10)**

*Mục tiêu: Hiển thị bàn cờ đẹp.*

* **Milestone F2 (Hex Grid):**  
  * Load map .tmx từ Tiled Editor.  
  * Thuật toán PixelToHex để phát hiện click chuột chính xác trên ô lục giác.  
  * Vẽ Token nhân vật (Sprite) lên map.  
* **Milestone B4 (State Sync):**  
  * Lưu vị trí Token vào Redis.  
  * Khi F5 refresh trang, Token phải nằm đúng chỗ cũ (Load từ Redis).

### **🟢 Giai đoạn 4: Combat Loop (Tuần 11-14)**

*Mục tiêu: Chơi được game.*

* **Milestone B5 (Combat Manager):**  
  * Logic Initiative: Sắp xếp lượt đi.  
  * Logic Attack: So sánh Attack Roll vs AC \-\> Trừ HP.  
* **Milestone F3 (UI Overlay):**  
  * Vẽ Character Sheet đè lên Game (Stack Widget).  
  * Hiển thị Combat Log ("Goblin takes 5 damage") cuộn tự động.  
  * **Fog of War:** Che các vùng chưa khám phá bằng lớp phủ đen (CustomPainter).

### **🟢 Giai đoạn 5: Polish & Deploy (Tuần 15-16)**

*Mục tiêu: Ra mắt.*

* **Milestone DevOps:**  
  * Dockerize Backend & Frontend.  
  * Setup **Redis Backplane** để scale nhiều server.  
  * Load Test 500 CCU.

## ---

**5\. Tính năng Mở rộng (Expansion Ideas)**

1. **AI Dungeon Master (Narrative):**  
   * Gửi log combat (Paladin hits Goblin: 25 dmg) tới OpenAI API.  
   * Nhận về văn bản mô tả: *"Lưỡi gươm thánh quang xẻ đôi chiếc khiên gỗ mục nát..."*.  
2. **Audio Ambiance (Dynamic):**  
   * Nếu trong hang động (MapType: Cave) \-\> Thêm hiệu ứng Reverb vào Voice Chat.  
   * Nếu máu Boss \< 10% \-\> Tăng nhịp độ nhạc nền.

## ---

**6\. Quick Start Commands**

Để bắt đầu ngay lập tức với cấu trúc này:

Bash

\# 1\. Khởi tạo Solution  
mkdir HexboundVTT && cd HexboundVTT  
dotnet new sln \-n HexboundVTT

\# 2\. Tạo Backend (ASP.NET Core)  
dotnet new webapi \-n Hexbound.API \--use-controllers  
dotnet sln add Hexbound.API/Hexbound.API.csproj  
cd Hexbound.API  
dotnet add package Microsoft.AspNetCore.SignalR.Protocols.MessagePack  
dotnet add package StackExchange.Redis  
dotnet add package Microsoft.EntityFrameworkCore.SqlServer

\# 3\. Tạo Frontend (Flutter)  
cd..  
flutter create \--platforms=web hexbound\_client  
cd hexbound\_client  
flutter pub add flame flame\_tiled signalr\_netcore google\_fonts  
