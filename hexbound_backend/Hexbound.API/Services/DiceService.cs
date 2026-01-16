using System.Text.RegularExpressions;
using Hexbound.API.Models;
using System.Security.Cryptography;

namespace Hexbound.API.Services;

public class DiceService
{
    // Regex matches: "2d6", "1d20+5", "d8-1"
    private static readonly Regex DiceRegex = new(@"^(?:(\d+))?d(\d+)(?:\s*([+-])\s*(\d+))?$");

    public DiceRoll Roll(string formula)
    {
        var match = DiceRegex.Match(formula.ToLower().Trim());
        if (!match.Success)
        {
            throw new ArgumentException($"Invalid dice formula: {formula}");
        }

        // Parse Count (default to 1 if missing, e.g. "d20")
        int count = string.IsNullOrEmpty(match.Groups[1].Value) ? 1 : int.Parse(match.Groups[1].Value);
        
        // Parse Sides
        int sides = int.Parse(match.Groups[2].Value);

        // Parse Bonus via Sign and Value
        int bonus = 0;
        if (match.Groups[3].Success && match.Groups[4].Success)
        {
            int rawBonus = int.Parse(match.Groups[4].Value);
            bonus = match.Groups[3].Value == "-" ? -rawBonus : rawBonus;
        }

        var result = new DiceRoll
        {
            Count = count,
            Sides = sides,
            Bonus = bonus
        };

        // Perform Rolls (Secure RNG)
        for (int i = 0; i < count; i++)
        {
            result.Rolls.Add(RandomNumberGenerator.GetInt32(1, sides + 1));
        }

        return result;
    }
}
