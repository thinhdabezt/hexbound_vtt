# ⚔️ Combat Loop Roadmap - D&D 5e Tactical Combat

Full combat system cho Hexbound VTT, dựa trên D&D 5e SRD rules.

---

## Current Status Summary

### ✅ Đã hoàn thành
- `CombatService` với `StartCombat`, `NextTurn`, `ResolveAttack`, `ApplyDamage`
- `CombatState` model (TurnOrder, CurrentTurnIndex, RoundNumber, IsActive)
- `GameHub` endpoints: `StartCombat`, `EndTurn`, `Attack`
- Frontend `CombatOverlay` widget (Log, Initiative Tracker)
- Token rendering với Flag icons

### ❌ Còn thiếu
- Token Stats (HP, AC, Speed, Initiative Modifier)
- Real Initiative Roll (D20 + Dex Modifier)
- HP Persistence & Death Handling
- Action Economy (Action, Bonus Action, Movement)
- Conditions/Status Effects
- AoE Spells & Multi-target
- Frontend Combat Controls

---

## Milestone C1: Token Stats Model

### Backend
- [ ] **Create `TokenStats` model**
  ```csharp
  public class TokenStats {
      public string TokenId { get; set; }
      public string Name { get; set; }
      public int MaxHp { get; set; }
      public int CurrentHp { get; set; }
      public int ArmorClass { get; set; }
      public int Speed { get; set; } // In hexes
      public int InitiativeModifier { get; set; }
      public List<string> Conditions { get; set; } = new();
  }
  ```
- [ ] **Store `TokenStats` in Redis** (GameStateService)
- [ ] **Sync `TokenStats` on client connect**

### Frontend
- [ ] **Create `TokenStatsProvider`** (Riverpod)
- [ ] **Display HP bar under tokens**

---

## Milestone C2: Real Initiative System

### Backend
- [ ] **Update `StartCombat`** to use `DiceService`:
  ```csharp
  var roll = _diceService.Roll("1d20");
  var initiative = roll.Total + stats.InitiativeModifier;
  ```
- [ ] **Sort `TurnOrder` by initiative value (DESC)**
- [ ] **Handle ties** (higher Dex mod wins)

### Frontend
- [ ] **Display initiative values** in tracker
- [ ] **Highlight current turn** with glow effect

---

## Milestone C3: HP Tracking & Death

### Backend
- [ ] **`ApplyDamage(tokenId, damage)`** - Update Redis
- [ ] **`ApplyHealing(tokenId, amount)`** - Cap at MaxHp
- [ ] **Death Handling**:
  - HP = 0 → Unconscious (Condition)
  - Massive damage (overkill = MaxHp) → Instant death
  - Death Saving Throws (optional)

### Frontend
- [ ] **HP bar updates in real-time** via SignalR
- [ ] **Unconscious token visual** (grayscale + prone icon)
- [ ] **Death animation** (fade out)

---

## Milestone C4: Action Economy

### Model
```csharp
public class TurnActions {
    public bool ActionUsed { get; set; }
    public bool BonusActionUsed { get; set; }
    public int MovementRemaining { get; set; }
    public bool ReactionUsed { get; set; }
}
```

### Backend
- [ ] **Track actions per turn** in CombatState
- [ ] **Reset on turn start**
- [ ] **Validate action availability** before resolving

### Frontend
- [ ] **Action bar UI** (Action | Bonus | Movement: 6)
- [ ] **Disable buttons when used**

---

## Milestone C5: Conditions & Status Effects

### Conditions List (D&D 5e SRD)
- Blinded, Charmed, Deafened, Frightened
- Grappled, Incapacitated, Invisible, Paralyzed
- Petrified, Poisoned, Prone, Restrained
- Stunned, Unconscious

### Implementation
- [ ] **Add `Conditions` to TokenStats**
- [ ] **Condition icons on tokens** (overlay badges)
- [ ] **Auto-apply effects**:
  - Stunned → Skip turn
  - Prone → Half movement to stand

---

## Milestone C6: Movement & Pathfinding Integration

### Backend
- [ ] **Validate movement distance** (Speed - used)
- [ ] **Difficult terrain** (costs 2 movement)
- [ ] **Opportunity Attacks** (leaving enemy hex range)

### Frontend
- [ ] **Show movement range** (highlighted hexes)
- [ ] **Path preview** with remaining movement
- [ ] **Block invalid moves**

---

## Milestone C7: Attack Flow Refinement

### Backend
- [ ] **Fetch target AC from TokenStats**
- [ ] **Calculate damage from weapon/spell**
- [ ] **Critical Hit (Nat 20)** - Double damage dice
- [ ] **Critical Miss (Nat 1)** - Auto miss

### Frontend
- [ ] **Attack target selection** (click enemy token)
- [ ] **Roll animation** (D20 visual)
- [ ] **Damage numbers** floating text

---

## Milestone C8: Spells & AoE

### Backend
- [ ] **Spell Data** from 5e API (range, area, save DC)
- [ ] **AoE targeting** (cone, sphere, line)
- [ ] **Saving Throws** (DC vs Dex/Con/Wis)
- [ ] **Spell Slots tracking**

### Frontend
- [ ] **AoE template preview** (highlight affected hexes)
- [ ] **Spell selection UI**

---

## Priority Order

| Milestone | Priority | Effort | Dependencies |
|-----------|----------|--------|--------------|
| C1: Token Stats | 🔴 High | Medium | - |
| C2: Initiative | 🔴 High | Low | C1 |
| C3: HP & Death | 🔴 High | Medium | C1 |
| C4: Action Economy | 🟡 Medium | Medium | C1 |
| C6: Movement | 🟡 Medium | Medium | C4 |
| C5: Conditions | 🟡 Medium | Medium | C3 |
| C7: Attack Refine | 🟢 Low | Low | C3 |
| C8: Spells & AoE | 🟢 Low | High | C7 |

---

## Success Criteria

- [ ] 2 players có thể combat với tokens có HP bars
- [ ] Initiative tự động với D20 + modifier
- [ ] Đổi turn smooth với "End Turn" button
- [ ] HP giảm khi bị attack, token dies khi HP = 0
- [ ] Movement range hiển thị và validate
