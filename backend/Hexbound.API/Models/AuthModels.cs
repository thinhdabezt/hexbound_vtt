namespace Hexbound.API.Models;

public record LoginRequest(string Username, string Password);
public record LoginResponse(string Token, string Username);
