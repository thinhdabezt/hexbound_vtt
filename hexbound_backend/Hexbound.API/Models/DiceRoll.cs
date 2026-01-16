namespace Hexbound.API.Models;

public class DiceRoll
{
    public int Count { get; set; } // Number of dice (e.g., 2 in 2d6)
    public int Sides { get; set; } // Number of sides (e.g., 6 in 2d6)
    public int Bonus { get; set; } // Flat bonus (e.g., 5 in +5)
    
    public List<int> Rolls { get; set; } = new(); // Individual die results
    public int Total => Rolls.Sum() + Bonus; // Final result

    public override string ToString()
    {
        return $"{Count}d{Sides}+{Bonus} ({string.Join(",", Rolls)}) = {Total}";
    }
}
