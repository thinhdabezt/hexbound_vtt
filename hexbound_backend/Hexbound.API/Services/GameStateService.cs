using System.Text.Json;
using Hexbound.API.Models;
using StackExchange.Redis;

namespace Hexbound.API.Services;

public class GameStateService
{
    private readonly IConnectionMultiplexer _redis;
    private const string TokenKey = "Hexbound:GameState:Tokens";
    private const string CombatKey = "Hexbound:GameState:Combat";

    public GameStateService(IConnectionMultiplexer redis)
    {
        _redis = redis;
    }

    public async Task UpdateTokenPosition(string tokenId, int q, int r)
    {
        var db = _redis.GetDatabase();
        await db.HashSetAsync(TokenKey, tokenId, $"{q},{r}");
    }

    public async Task<Dictionary<string, (int q, int r)>> GetGameState()
    {
        var db = _redis.GetDatabase();
        var entries = await db.HashGetAllAsync(TokenKey);

        var state = new Dictionary<string, (int q, int r)>();

        foreach (var entry in entries)
        {
            var parts = entry.Value.ToString().Split(',');
            if (parts.Length == 2 && int.TryParse(parts[0], out int q) && int.TryParse(parts[1], out int r))
            {
                state[entry.Name.ToString()] = (q, r);
            }
        }

        return state;
    }

    public async Task SaveCombatState(CombatState state)
    {
        var db = _redis.GetDatabase();
        var json = JsonSerializer.Serialize(state);
        await db.StringSetAsync(CombatKey, json);
    }

    public async Task<CombatState?> GetCombatState()
    {
        var db = _redis.GetDatabase();
        var json = await db.StringGetAsync(CombatKey);
        
        if (json.IsNullOrEmpty) return null;
        
        return JsonSerializer.Deserialize<CombatState>(json.ToString());
    }

    // ===== TOKEN STATS =====
    private const string TokenStatsPrefix = "Hexbound:TokenStats:";

    public async Task SaveTokenStats(TokenStats stats)
    {
        var db = _redis.GetDatabase();
        var key = TokenStatsPrefix + stats.TokenId;
        var json = JsonSerializer.Serialize(stats);
        await db.StringSetAsync(key, json);
    }

    public async Task<TokenStats?> GetTokenStats(string tokenId)
    {
        var db = _redis.GetDatabase();
        var key = TokenStatsPrefix + tokenId;
        var json = await db.StringGetAsync(key);
        
        if (json.IsNullOrEmpty) return null;
        
        return JsonSerializer.Deserialize<TokenStats>(json.ToString());
    }

    public async Task<List<TokenStats>> GetAllTokenStats()
    {
        var db = _redis.GetDatabase();
        var server = _redis.GetServer(_redis.GetEndPoints().First());
        var keys = server.Keys(pattern: TokenStatsPrefix + "*");
        
        var result = new List<TokenStats>();
        foreach (var key in keys)
        {
            var json = await db.StringGetAsync(key);
            if (!json.IsNullOrEmpty)
            {
                var stats = JsonSerializer.Deserialize<TokenStats>(json.ToString());
                if (stats != null) result.Add(stats);
            }
        }
        return result;
    }

    public async Task UpdateTokenHp(string tokenId, int damage)
    {
        var stats = await GetTokenStats(tokenId);
        if (stats == null) return;
        
        stats.CurrentHp = Math.Max(0, stats.CurrentHp - damage);
        await SaveTokenStats(stats);
    }

    /// <summary>
    /// Apply damage with D&D 5e death handling
    /// </summary>
    public async Task<(TokenStats? stats, string? deathEvent)> ApplyDamageWithDeathHandling(string tokenId, int damage)
    {
        var stats = await GetTokenStats(tokenId);
        if (stats == null) return (null, null);
        
        var previousHp = stats.CurrentHp;
        stats.CurrentHp = Math.Max(0, stats.CurrentHp - damage);
        
        string? deathEvent = null;
        
        // Check for death conditions
        if (stats.CurrentHp == 0 && previousHp > 0)
        {
            var overkill = damage - previousHp;
            
            // Massive damage: overkill >= MaxHp = instant death
            if (overkill >= stats.MaxHp)
            {
                if (!stats.Conditions.Contains("Dead"))
                {
                    stats.Conditions.Add("Dead");
                    stats.Conditions.Remove("Unconscious");
                    deathEvent = "Dead";
                }
            }
            else
            {
                // HP = 0 → Unconscious
                if (!stats.Conditions.Contains("Unconscious") && !stats.Conditions.Contains("Dead"))
                {
                    stats.Conditions.Add("Unconscious");
                    deathEvent = "Unconscious";
                }
            }
        }
        
        await SaveTokenStats(stats);
        return (stats, deathEvent);
    }

    /// <summary>
    /// Apply healing (capped at MaxHp, removes Unconscious if healed above 0)
    /// </summary>
    public async Task<TokenStats?> ApplyHealing(string tokenId, int amount)
    {
        var stats = await GetTokenStats(tokenId);
        if (stats == null) return null;
        
        // Dead tokens cannot be healed (need resurrection)
        if (stats.Conditions.Contains("Dead")) return stats;
        
        var previousHp = stats.CurrentHp;
        stats.CurrentHp = Math.Min(stats.MaxHp, stats.CurrentHp + amount);
        
        // Remove Unconscious if healed above 0
        if (previousHp == 0 && stats.CurrentHp > 0)
        {
            stats.Conditions.Remove("Unconscious");
        }
        
        await SaveTokenStats(stats);
        return stats;
    }
}


