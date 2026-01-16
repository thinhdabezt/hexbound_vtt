using StackExchange.Redis;

namespace Hexbound.API.Services;

public class GameStateService
{
    private readonly IConnectionMultiplexer _redis;
    private const string TokenKey = "Hexbound:GameState:Tokens";

    public GameStateService(IConnectionMultiplexer redis)
    {
        _redis = redis;
    }

    public async Task UpdateTokenPosition(string tokenId, int q, int r)
    {
        var db = _redis.GetDatabase();
        // Store simple "q,r" string
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
}
