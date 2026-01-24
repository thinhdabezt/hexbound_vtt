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
}

