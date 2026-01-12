using Hexbound.API.Data;
using Hexbound.API.Hubs;
using Hexbound.API.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// SignalR with MessagePack
builder.Services.AddSignalR()
    .AddMessagePackProtocol();

// Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"] ?? "default_secret_key_if_config_missing_must_be_long_enough";
var key = Encoding.ASCII.GetBytes(secretKey);
// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Background Services
builder.Services.AddHostedService<DataIngestionWorker>();
builder.Services.AddSingleton<DiceService>();

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = false,
        ValidateAudience = false
    };
});

// CORS (Allow Flutter Web)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder => builder
            .WithOrigins("http://localhost:3000", "http://localhost:5000", "http://127.0.0.1:3000") // Adjust as needed
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseCors("AllowAll"); // Enable CORS

app.UseAuthentication(); // Enable Auth
app.UseAuthorization();

app.MapControllers();
app.MapHub<GameHub>("/gameHub"); // Map SignalR Hub

// Verify DiceService (Quick Test)
using (var scope = app.Services.CreateScope())
{
    var diceService = scope.ServiceProvider.GetRequiredService<DiceService>();
    try 
    {
        var result = diceService.Roll("2d6+5");
        Console.WriteLine($"✅ Dice Test (2d6+5): {result}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Dice Test Failed: {ex.Message}");
    }
}

app.Run();
