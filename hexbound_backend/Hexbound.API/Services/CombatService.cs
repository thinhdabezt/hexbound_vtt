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

    // === Movement Helpers ===

    /// <summary>
    /// Calculate hex distance between two points (axial coordinates)
    /// </summary>
    public int HexDistance(int q1, int r1, int q2, int r2)
    {
        // Convert axial to cube coordinates and use cube distance
        int s1 = -q1 - r1;
        int s2 = -q2 - r2;
        return (Math.Abs(q1 - q2) + Math.Abs(r1 - r2) + Math.Abs(s1 - s2)) / 2;
    }

    /// <summary>
    /// Calculate movement cost for a path (supports difficult terrain)
    /// </summary>
    public int CalculateMovementCost(int fromQ, int fromR, int toQ, int toR, HashSet<(int q, int r)>? difficultTerrain = null)
    {
        int baseCost = HexDistance(fromQ, fromR, toQ, toR);
        
        // For now, simple direct cost. In future, implement A* with terrain costs
        if (difficultTerrain != null && difficultTerrain.Contains((toQ, toR)))
        {
            return baseCost + 1; // Difficult terrain costs +1 extra
        }
        
        return baseCost;
    }

    /// <summary>
    /// Validate and execute combat movement
    /// </summary>
    public (bool success, string? error) ValidateCombatMove(
        CombatState state, 
        TokenStats actor,
        int toQ, int toR,
        HashSet<(int q, int r)>? difficultTerrain = null)
    {
        if (!state.IsActive)
            return (false, "Combat is not active");

        if (state.CurrentActor != actor.TokenId)
            return (false, "Not your turn");

        var actions = state.CurrentActorActions;
        if (actions == null)
            return (false, "No actions available");

        int cost = CalculateMovementCost(actor.Q, actor.R, toQ, toR, difficultTerrain);
        
        if (cost > actions.MovementRemaining)
            return (false, $"Not enough movement. Need {cost}, have {actions.MovementRemaining}");

        // Deduct movement
        actions.MovementRemaining -= cost;
        
        return (true, null);
    }

    /// <summary>
    /// Check if moving from one hex to another triggers opportunity attacks
    /// Returns list of enemy token IDs that can make opportunity attacks
    /// </summary>
    public List<string> CheckOpportunityAttacks(
        int fromQ, int fromR, 
        int toQ, int toR,
        Dictionary<string, (int q, int r)> enemyPositions,
        string movingTokenId)
    {
        var attackers = new List<string>();
        
        foreach (var (enemyId, pos) in enemyPositions)
        {
            if (enemyId == movingTokenId) continue;
            
            // Check if leaving an adjacent hex (threat range = 1 hex)
            int distanceFrom = HexDistance(fromQ, fromR, pos.q, pos.r);
            int distanceTo = HexDistance(toQ, toR, pos.q, pos.r);
            
            // If was adjacent (distance 1) and now leaving (distance > 1)
            if (distanceFrom == 1 && distanceTo > 1)
            {
                attackers.Add(enemyId);
            }
        }
        
        return attackers;
    }
}


