namespace Hexbound.API.Models;

/// <summary>
/// Tracks action economy per actor per turn (D&D 5e rules)
/// </summary>
public class TurnActions
{
    public bool ActionUsed { get; set; } = false;
    public bool BonusActionUsed { get; set; } = false;
    public int MovementRemaining { get; set; } = 6; // Default speed in hexes
    public bool ReactionUsed { get; set; } = false;

    /// <summary>
    /// Reset all actions for a new turn
    /// </summary>
    public void Reset(int speed = 6)
    {
        ActionUsed = false;
        BonusActionUsed = false;
        MovementRemaining = speed;
        ReactionUsed = false;
    }

    /// <summary>
    /// Check if any actions are still available
    /// </summary>
    public bool HasActionsRemaining => !ActionUsed || !BonusActionUsed || MovementRemaining > 0;
}
