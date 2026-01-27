using Microsoft.AspNetCore.SignalR;
using Hexbound.API.Services;
using Hexbound.API.Models;

namespace Hexbound.API.Hubs;

public class GameHub : Hub
{
    private readonly DiceService _diceService;
    private readonly GameStateService _gameStateService;
    private readonly CombatService _combatService;

    public GameHub(DiceService diceService, GameStateService gameStateService, CombatService combatService)
    {
        _diceService = diceService;
        _gameStateService = gameStateService;
        _combatService = combatService;
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
        
        // Sync TokenStats
        var allStats = await _gameStateService.GetAllTokenStats();
        await Clients.Caller.SendAsync("TokenStatsSync", allStats);
        
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

    // --- Token Stats API ---
    
    public async Task UpdateTokenStats(TokenStats stats)
    {
        await _gameStateService.SaveTokenStats(stats);
        await Clients.All.SendAsync("TokenStatsUpdated", stats);
    }

    public async Task DealDamage(string tokenId, int damage)
    {
        var (stats, deathEvent) = await _gameStateService.ApplyDamageWithDeathHandling(tokenId, damage);
        if (stats == null) return;
        
        await Clients.All.SendAsync("TokenStatsUpdated", stats);
        await Clients.All.SendAsync("CombatLog", $"💥 {stats.Name} takes {damage} damage! (HP: {stats.CurrentHp}/{stats.MaxHp})");
        
        // Broadcast death events
        if (deathEvent == "Unconscious")
        {
            await Clients.All.SendAsync("CombatLog", $"💤 {stats.Name} falls unconscious!");
            await Clients.All.SendAsync("TokenDeath", new { tokenId, state = "Unconscious" });
        }
        else if (deathEvent == "Dead")
        {
            await Clients.All.SendAsync("CombatLog", $"💀 {stats.Name} is killed by massive damage!");
            await Clients.All.SendAsync("TokenDeath", new { tokenId, state = "Dead" });
        }
    }

    public async Task HealToken(string tokenId, int amount)
    {
        var stats = await _gameStateService.ApplyHealing(tokenId, amount);
        if (stats == null) return;
        
        await Clients.All.SendAsync("TokenStatsUpdated", stats);
        
        if (stats.Conditions.Contains("Dead"))
        {
            await Clients.All.SendAsync("CombatLog", $"⚰️ {stats.Name} is dead and cannot be healed.");
        }
        else
        {
            await Clients.All.SendAsync("CombatLog", $"💚 {stats.Name} is healed for {amount}! (HP: {stats.CurrentHp}/{stats.MaxHp})");
            
            // Check if revived from unconscious
            if (stats.CurrentHp > 0 && !stats.Conditions.Contains("Unconscious"))
            {
                await Clients.All.SendAsync("TokenRevive", tokenId);
            }
        }
    }

    // --- Combat API ---

    public async Task StartCombat(List<string> participantIds)
    {
        // Fetch TokenStats for all participants
        var participants = new List<TokenStats>();
        foreach (var id in participantIds)
        {
            var stats = await _gameStateService.GetTokenStats(id);
            if (stats != null)
            {
                participants.Add(stats);
            }
            else
            {
                // Create default stats for tokens without stats
                participants.Add(new TokenStats { TokenId = id, Name = id });
            }
        }
        
        // Start combat with real initiative rolls
        var state = _combatService.StartCombat(participants);
        await _gameStateService.SaveCombatState(state);
        
        // Broadcast with initiative details
        await Clients.All.SendAsync("CombatStarted", state);
        
        // Send initiative roll results to combat log
        foreach (var (tokenId, roll) in state.InitiativeRolls)
        {
            var name = participants.FirstOrDefault(p => p.TokenId == tokenId)?.Name ?? tokenId;
            await Clients.All.SendAsync("CombatLog", $"🎲 {name} rolled initiative: {roll}");
        }
    }

    public async Task EndTurn()
    {
        var state = await _gameStateService.GetCombatState();
        if (state == null || !state.IsActive) return;

        _combatService.NextTurn(state);
        await _gameStateService.SaveCombatState(state);
        await Clients.All.SendAsync("TurnChanged", state); // Client updates CurrentActor highlight
    }

    public async Task Attack(string targetId, int attackRoll)
    {
        // Ideally we fetch Target Stat from DB/Redis. 
        // For Proof of Concept, let's assume AC 15 for everyone.
        int targetAc = 15; 
        
        bool isHit = _combatService.ResolveAttack(attackRoll, targetAc);
        
        string log = isHit ? $"Attack Hit! (Roll {attackRoll} vs AC {targetAc})" : $"Attack Missed. (Roll {attackRoll} vs AC {targetAc})";
        
        await Clients.All.SendAsync("CombatLog", log);
        
        if (isHit) {
             // For now static damage
             await Clients.All.SendAsync("CombatLog", $"{targetId} takes 5 damage!");
        }
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
