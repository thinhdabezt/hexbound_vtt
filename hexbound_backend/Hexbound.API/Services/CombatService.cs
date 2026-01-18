using Hexbound.API.Models;

namespace Hexbound.API.Services;

public class CombatService
{
    private readonly Random _rng = new Random();

    // 1. Initiative: Simple Shuffle for now (Later: D20 + Dex)
    public CombatState StartCombat(List<string> participantIds)
    {
        var order = participantIds.OrderBy(x => _rng.Next()).ToList();
        return new CombatState
        {
            TurnOrder = order,
            CurrentTurnIndex = 0,
            RoundNumber = 1,
            IsActive = true
        };
    }

    public void NextTurn(CombatState state)
    {
        if (!state.IsActive || state.TurnOrder.Count == 0) return;

        state.CurrentTurnIndex++;
        if (state.CurrentTurnIndex >= state.TurnOrder.Count)
        {
            state.CurrentTurnIndex = 0;
            state.RoundNumber++;
        }
    }

    // 2. Attack Logic
    public bool ResolveAttack(int attackRoll, int targetAc)
    {
        // Nat 20 is auto hit (logic can be added here)
        return attackRoll >= targetAc;
    }

    // 3. Damage Logic (Returns new HP)
    public int ApplyDamage(int currentHp, int damage)
    {
        return Math.Max(0, currentHp - damage);
    }
}
