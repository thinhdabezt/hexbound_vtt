# 🌐 Multiplayer Roadmap - Real-time Collaboration

Mục tiêu: Hỗ trợ **nhiều người chơi online** với độ trễ <100ms, đồng bộ hoàn hảo.

---

## Milestone M1: Authentication & Session Management

### Current State
- Không có user authentication
- Token ID được generate ngẫu nhiên mỗi session

### Tasks
- [ ] **User Model (Backend)**:
  ```csharp
  public class User {
      public Guid Id { get; set; }
      public string Username { get; set; }
      public string PasswordHash { get; set; }
      public DateTime CreatedAt { get; set; }
  }
  ```

- [ ] **JWT Authentication Flow**:
  1. POST `/api/auth/register` - Đăng ký
  2. POST `/api/auth/login` - Đăng nhập, trả về JWT
  3. SignalR Client gửi JWT trong handshake

- [ ] **Frontend Login Screen**: Simple email/password form

---

## Milestone M2: Campaign & Room System

### Tasks
- [ ] **Campaign Model**:
  ```csharp
  public class Campaign {
      public Guid Id { get; set; }
      public string Name { get; set; }
      public Guid HostId { get; set; }
      public string JoinCode { get; set; } // 6 chars
      public List<Guid> PlayerIds { get; set; }
  }
  ```

- [ ] **Room Management (SignalR Groups)**:
  ```csharp
  public async Task JoinCampaign(string joinCode) {
      var campaign = await _db.Campaigns.FindByCode(joinCode);
      await Groups.AddToGroupAsync(Context.ConnectionId, campaign.Id.ToString());
      await Clients.Group(campaign.Id).SendAsync("PlayerJoined", username);
  }
  ```

- [ ] **Frontend Campaign Browser**: List campaigns, Create/Join buttons

---

## Milestone M3: Role-Based Permissions (DM vs Player)

### Tasks
- [ ] **Permission System**:
  | Action | DM | Player |
  |--------|:--:|:------:|
  | Move Any Token | ✅ | ❌ |
  | Move Own Token | ✅ | ✅ |
  | Start Combat | ✅ | ❌ |
  | End Turn | ✅ | Own only |
  | Reveal Fog | ✅ | ❌ |
  | Add/Remove Tokens | ✅ | ❌ |

- [ ] **Backend Validation**: Check permissions before processing actions
- [ ] **Frontend UI**: Hide DM-only controls from players

---

## Milestone M4: Player Token Ownership

### Tasks
- [ ] **Token Ownership**:
  ```csharp
  public class Token {
      public Guid Id { get; set; }
      public string Name { get; set; }
      public Guid? OwnerId { get; set; } // null = DM controlled
      public int Q { get; set; }
      public int R { get; set; }
  }
  ```

- [ ] **Move Validation**:
  ```csharp
  public async Task MoveToken(Guid tokenId, int q, int r) {
      var token = await GetToken(tokenId);
      var userId = Context.UserIdentifier;
      
      if (token.OwnerId != userId && !IsDM(userId)) {
          throw new UnauthorizedAccessException();
      }
      // ... proceed with move
  }
  ```

- [ ] **Visual Indicator**: Highlight owned tokens cho player

---

## Milestone M5: Real-time Cursor & Presence

### Tasks
- [ ] **Cursor Sharing**:
  - Broadcast mouse position mỗi 100ms (debounced)
  - Hiển thị cursor của players khác với tên bên cạnh

- [ ] **Presence Indicators**:
  - Player list panel showing online/offline
  - Typing indicator trong chat
  - "X is viewing hex (5, 3)"

- [ ] **Latency Display**: Ping indicator for each player

---

## Milestone M6: Chat & Voice Integration

### Tasks
- [ ] **Text Chat**:
  - Public channel (all players)
  - Private whisper (DM to Player)
  - `/roll 1d20+5` command integration

- [ ] **Dice Rolling UI**: Click to roll, animated result

- [ ] **Voice Chat (Optional)**:
  - WebRTC integration
  - Push-to-talk
  - Spatial audio (volume based on token distance)

---

## Milestone M7: Conflict Resolution & Latency Handling

### Tasks
- [ ] **Optimistic Updates**: 
  - Move token locally immediately
  - Rollback if server rejects

- [ ] **Server-Authoritative State**:
  - Server is single source of truth
  - Client predicts, server confirms

- [ ] **Reconnection Handling**:
  - Auto-reconnect on disconnect
  - Sync full state on reconnect
  - Queue actions during offline

---

## Milestone M8: Scalability (Redis Backplane)

### Tasks
- [ ] **SignalR Redis Backplane**:
  ```csharp
  builder.Services.AddSignalR()
      .AddStackExchangeRedis(redisConnectionString, options => {
          options.Configuration.ChannelPrefix = "HexboundVTT";
      });
  ```

- [ ] **Load Balancing**: Multiple backend instances behind nginx

- [ ] **Connection Limits**: Max 20 players per campaign

---

## Architecture Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Player A   │     │  Player B   │     │     DM      │
│  (Flutter)  │     │  (Flutter)  │     │  (Flutter)  │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │ SignalR WebSocket
                           ▼
                 ┌─────────────────────┐
                 │  ASP.NET Core API   │
                 │  (SignalR Hub)      │
                 └─────────┬───────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌───────────┐   ┌───────────┐   ┌───────────┐
    │ PostgreSQL│   │   Redis   │   │   Redis   │
    │ (Users,   │   │ (Game     │   │ (SignalR  │
    │ Campaigns)│   │  State)   │   │  Backplane│
    └───────────┘   └───────────┘   └───────────┘
```

---

## Milestones Priority

| # | Milestone | Priority | Complexity |
|---|-----------|----------|------------|
| M1 | Auth | 🔴 High | Medium |
| M2 | Rooms | 🔴 High | Medium |
| M3 | Permissions | 🔴 High | Low |
| M4 | Token Ownership | 🟡 Medium | Low |
| M5 | Presence | 🟡 Medium | Medium |
| M6 | Chat | 🟢 Low | Medium |
| M7 | Conflict Resolution | 🟡 Medium | High |
| M8 | Scalability | 🟢 Low | High |
