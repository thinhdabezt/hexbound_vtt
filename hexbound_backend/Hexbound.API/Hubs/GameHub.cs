using Microsoft.AspNetCore.SignalR;
using Hexbound.API.Services;

namespace Hexbound.API.Hubs;

public class GameHub : Hub
{
    private readonly DiceService _diceService;
    private readonly GameStateService _gameStateService;

    public GameHub(DiceService diceService, GameStateService gameStateService)
    {
        _diceService = diceService;
        _gameStateService = gameStateService;
    }

    public override async Task OnConnectedAsync()
    {
        Console.WriteLine($"Client connected: {Context.ConnectionId}");
        
        // Send current state to new client
        var state = await _gameStateService.GetGameState();
        // Convert tuple to simple object for serialization if needed, or send as map
        // MessagePack/JSON handles Dictionaries well.
        // We'll verify serialization. Tuples might be tricky in pure JSON, but let's try.
        // Actually, let's map it to a simpler DTO to be safe.
        var dto = state.ToDictionary(k => k.Key, v => new { q = v.Value.q, r = v.Value.r });
        
        await Clients.Caller.SendAsync("GameStateSync", dto);
        
        await base.OnConnectedAsync();
    }

    public async Task SendMessage(string user, string message)
    {
        await Clients.All.SendAsync("ReceiveMessage", user, message);
    }

    public async Task MoveToken(string tokenId, int q, int r)
    {
        // 1. Update State
        await _gameStateService.UpdateTokenPosition(tokenId, q, r);
        
        // 2. Broadcast to all (including caller, to confirm)
        await Clients.All.SendAsync("TokenMoved", tokenId, q, r);
    }

    public async Task RollDice(string user, string formula)
    {
        try 
        {
            var result = _diceService.Roll(formula);
            await Clients.All.SendAsync("DiceRolled", user, result);
        }
        catch (Exception ex)
        {
            await Clients.Caller.SendAsync("ReceiveMessage", "System", $"Error: {ex.Message}");
        }
    }
}
