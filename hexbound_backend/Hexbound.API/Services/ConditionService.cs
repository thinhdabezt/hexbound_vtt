namespace Hexbound.API.Services;

using Hexbound.API.Models;

/// <summary>
/// Manages D&D 5e conditions and their effects
/// </summary>
public class ConditionService
{
    // D&D 5e SRD Conditions
    public static readonly HashSet<string> ValidConditions = new()
    {
        "Blinded", "Charmed", "Deafened", "Frightened",
        "Grappled", "Incapacitated", "Invisible", "Paralyzed",
        "Petrified", "Poisoned", "Prone", "Restrained",
        "Stunned", "Unconscious", "Dead"
    };

    // Condition icons for UI
    public static readonly Dictionary<string, string> ConditionIcons = new()
    {
        { "Blinded", "🙈" },
        { "Charmed", "💕" },
        { "Deafened", "🔇" },
        { "Frightened", "😱" },
        { "Grappled", "🤝" },
        { "Incapacitated", "💫" },
        { "Invisible", "👻" },
        { "Paralyzed", "⚡" },
        { "Petrified", "🗿" },
        { "Poisoned", "🤢" },
        { "Prone", "🔻" },
        { "Restrained", "⛓️" },
        { "Stunned", "😵" },
        { "Unconscious", "💤" },
        { "Dead", "💀" }
    };

    /// <summary>
    /// Add a condition to a token
    /// </summary>
    public bool AddCondition(TokenStats stats, string condition)
    {
        if (!ValidConditions.Contains(condition)) return false;
        if (stats.Conditions.Contains(condition)) return false;
        
        stats.Conditions.Add(condition);
        return true;
    }

    /// <summary>
    /// Remove a condition from a token
    /// </summary>
    public bool RemoveCondition(TokenStats stats, string condition)
    {
        return stats.Conditions.Remove(condition);
    }

    /// <summary>
    /// Get effective speed considering conditions
    /// Grappled/Restrained/Paralyzed/Stunned/Unconscious/Petrified → 0
    /// </summary>
    public int GetEffectiveSpeed(TokenStats stats)
    {
        var zeroSpeedConditions = new[] { "Grappled", "Restrained", "Paralyzed", "Stunned", "Unconscious", "Petrified" };
        if (stats.Conditions.Any(c => zeroSpeedConditions.Contains(c)))
        {
            return 0;
        }
        return stats.Speed;
    }

    /// <summary>
    /// Check if token can take their turn
    /// Stunned/Paralyzed/Unconscious/Petrified → cannot take turn
    /// </summary>
    public bool CanTakeTurn(TokenStats stats)
    {
        var skipTurnConditions = new[] { "Stunned", "Paralyzed", "Unconscious", "Petrified", "Dead" };
        return !stats.Conditions.Any(c => skipTurnConditions.Contains(c));
    }

    /// <summary>
    /// Get movement cost to stand up from Prone (half of max movement)
    /// </summary>
    public int GetStandUpCost(TokenStats stats)
    {
        if (!stats.Conditions.Contains("Prone")) return 0;
        return stats.Speed / 2;
    }

    /// <summary>
    /// Check if token has a specific condition
    /// </summary>
    public bool HasCondition(TokenStats stats, string condition)
    {
        return stats.Conditions.Contains(condition);
    }

    /// <summary>
    /// Get icon for a condition
    /// </summary>
    public string GetConditionIcon(string condition)
    {
        return ConditionIcons.GetValueOrDefault(condition, "❓");
    }
}
