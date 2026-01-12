using Microsoft.AspNetCore.SignalR;
using Hexbound.API.Services;

namespace Hexbound.API.Hubs;

public class GameHub : Hub
{
    private readonly DiceService _diceService;

    public GameHub(DiceService diceService)
    {
        _diceService = diceService;
    }

    public override async Task OnConnectedAsync()
    {
        Console.WriteLine($"Client connected: {Context.ConnectionId}");
        await base.OnConnectedAsync();
    }

    public async Task SendMessage(string user, string message)
    {
        await Clients.All.SendAsync("ReceiveMessage", user, message);
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
