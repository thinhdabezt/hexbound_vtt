namespace Hexbound.API.Models;

/// <summary>
/// Represents a token's combat statistics
/// </summary>
public class TokenStats
{
    public string TokenId { get; set; } = string.Empty;
    public string Name { get; set; } = "Unknown";
    public int MaxHp { get; set; } = 10;
    public int CurrentHp { get; set; } = 10;
    public int ArmorClass { get; set; } = 10;
    public int Speed { get; set; } = 6; // Hexes per turn
    public int InitiativeModifier { get; set; } = 0;
    public List<string> Conditions { get; set; } = new();
    
    // Position (synced with token position)
    public int Q { get; set; }
    public int R { get; set; }
    
    // Helper properties
    public bool IsAlive => CurrentHp > 0;
    public double HpPercentage => MaxHp > 0 ? (double)CurrentHp / MaxHp : 0;
}
