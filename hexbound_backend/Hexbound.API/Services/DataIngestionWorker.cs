using Hexbound.API.Data;
using Hexbound.API.Models;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Hexbound.API.Services;

public class DataIngestionWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DataIngestionWorker> _logger;
    private readonly HttpClient _httpClient;

    public DataIngestionWorker(IServiceProvider serviceProvider, ILogger<DataIngestionWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _httpClient = new HttpClient { BaseAddress = new Uri("https://www.dnd5eapi.co") };
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("DataIngestionWorker starting...");

        // Wait a bit for DB to be readyContainer
        await Task.Delay(5000, stoppingToken);

        try
        {
            using (var scope = _serviceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Ensure Database Created and Migrations Applied
                try 
                {
                    await dbContext.Database.MigrateAsync(stoppingToken);
                }
                catch(Exception ex)
                {
                    _logger.LogError(ex, "Migration failed. Database might not be ready or reachable.");
                    return;
                }

                if (!dbContext.Monsters.Any())
                {
                    _logger.LogInformation("Monsters table empty. Seeding data...");
                    await SeedMonstersAsync(dbContext, stoppingToken);
                }
                else
                {
                    _logger.LogInformation("Monsters table already has data. Skipping seed.");
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during data ingestion");
        }
    }

    private async Task SeedMonstersAsync(AppDbContext dbContext, CancellationToken stoppingToken)
    {
        // 1. Get List
        var response = await _httpClient.GetFromJsonAsync<JsonNode>("/api/monsters", stoppingToken);
        var results = response?["results"]?.AsArray();

        if (results == null) return;

        int count = 0;
        foreach (var item in results)
        {
            if (count >= 10) break; // Limit to 10 for demo speed
            count++;

            var url = item?["url"]?.ToString();
            if (string.IsNullOrEmpty(url)) continue;

            // 2. Get Detail
            try 
            {
                var detailNode = await _httpClient.GetFromJsonAsync<JsonNode>(url, stoppingToken);
                if (detailNode == null) continue;

                var monster = new Monster
                {
                    Id = Guid.NewGuid(),
                    Name = detailNode["name"]?.ToString() ?? "Unknown",
                    Type = detailNode["type"]?.ToString() ?? "Unknown",
                    ChallengeRating = detailNode["challenge_rating"]?.GetValue<float>() ?? 0,
                    Data = detailNode.ToJsonString()
                };

                dbContext.Monsters.Add(monster);
                _logger.LogInformation($"fetched monster: {monster.Name}");
            }
            catch(Exception ex)
            {
                _logger.LogError($"Failed to fetch monster at {url}: {ex.Message}");
            }
        }

        await dbContext.SaveChangesAsync(stoppingToken);
        _logger.LogInformation($"Seeding completed. Added {count} monsters.");
    }
}
