namespace Hexbound.API.Models;

public class CombatState
{
    public List<string> TurnOrder { get; set; } = new();
    public Dictionary<string, int> InitiativeRolls { get; set; } = new();
    public int CurrentTurnIndex { get; set; } = 0;
    public int RoundNumber { get; set; } = 1;
    public bool IsActive { get; set; } = false;
    
    // Helper to get current actor
    public string? CurrentActor => TurnOrder.Count > 0 && CurrentTurnIndex < TurnOrder.Count 
        ? TurnOrder[CurrentTurnIndex] 
        : null;
}

