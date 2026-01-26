using Hexbound.API.Models;

namespace Hexbound.API.Services;

public class CombatService
{
    private readonly DiceService _diceService;

    public CombatService(DiceService diceService)
    {
        _diceService = diceService;
    }

    /// <summary>
    /// Start combat with real D20 + Initiative Modifier rolls
    /// </summary>
    public CombatState StartCombat(List<TokenStats> participants)
    {
        var initiativeRolls = new Dictionary<string, int>();
        
        foreach (var participant in participants)
        {
            // Roll 1d20 + Initiative Modifier
            var roll = _diceService.Roll("1d20");
            var initiative = roll.Total + participant.InitiativeModifier;
            initiativeRolls[participant.TokenId] = initiative;
        }
        
        // Sort by initiative (descending), then by modifier for tie-breaking
        var sortedOrder = participants
            .OrderByDescending(p => initiativeRolls[p.TokenId])
            .ThenByDescending(p => p.InitiativeModifier)
            .Select(p => p.TokenId)
            .ToList();

        return new CombatState
        {
            TurnOrder = sortedOrder,
            InitiativeRolls = initiativeRolls,
            CurrentTurnIndex = 0,
            RoundNumber = 1,
            IsActive = true
        };
    }

    /// <summary>
    /// Legacy overload for backward compatibility (random shuffle)
    /// </summary>
    public CombatState StartCombat(List<string> participantIds)
    {
        var rng = new Random();
        var order = participantIds.OrderBy(x => rng.Next()).ToList();
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

    // Attack Logic
    public bool ResolveAttack(int attackRoll, int targetAc)
    {
        return attackRoll >= targetAc;
    }

    // Damage Logic (Returns new HP)
    public int ApplyDamage(int currentHp, int damage)
    {
        return Math.Max(0, currentHp - damage);
    }
}
