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
        var actorActions = new Dictionary<string, TurnActions>();
        
        foreach (var participant in participants)
        {
            // Roll 1d20 + Initiative Modifier
            var roll = _diceService.Roll("1d20");
            var initiative = roll.Total + participant.InitiativeModifier;
            initiativeRolls[participant.TokenId] = initiative;
            
            // Initialize TurnActions with participant's speed
            actorActions[participant.TokenId] = new TurnActions { MovementRemaining = participant.Speed };
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
            ActorActions = actorActions,
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
        var actorActions = participantIds.ToDictionary(id => id, _ => new TurnActions());
        
        return new CombatState
        {
            TurnOrder = order,
            ActorActions = actorActions,
            CurrentTurnIndex = 0,
            RoundNumber = 1,
            IsActive = true
        };
    }

    public void NextTurn(CombatState state, Dictionary<string, TokenStats>? statsLookup = null)
    {
        if (!state.IsActive || state.TurnOrder.Count == 0) return;

        state.CurrentTurnIndex++;
        if (state.CurrentTurnIndex >= state.TurnOrder.Count)
        {
            state.CurrentTurnIndex = 0;
            state.RoundNumber++;
        }
        
        // Reset new current actor's actions
        var currentActor = state.CurrentActor;
        if (currentActor != null && state.ActorActions.ContainsKey(currentActor))
        {
            var speed = statsLookup?.GetValueOrDefault(currentActor)?.Speed ?? 6;
            state.ActorActions[currentActor].Reset(speed);
        }
    }

    // === Action Economy Methods ===
    
    public bool UseAction(CombatState state)
    {
        var actions = state.CurrentActorActions;
        if (actions == null || actions.ActionUsed) return false;
        actions.ActionUsed = true;
        return true;
    }

    public bool UseBonusAction(CombatState state)
    {
        var actions = state.CurrentActorActions;
        if (actions == null || actions.BonusActionUsed) return false;
        actions.BonusActionUsed = true;
        return true;
    }

    public bool UseMovement(CombatState state, int hexes)
    {
        var actions = state.CurrentActorActions;
        if (actions == null || actions.MovementRemaining < hexes) return false;
        actions.MovementRemaining -= hexes;
        return true;
    }

    public bool UseReaction(CombatState state, string actorId)
    {
        if (!state.ActorActions.ContainsKey(actorId)) return false;
        var actions = state.ActorActions[actorId];
        if (actions.ReactionUsed) return false;
        actions.ReactionUsed = true;
        return true;
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

