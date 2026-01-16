using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Hexbound.API.Models;

public class Monster
{
    [Key]
    public Guid Id { get; set; }

    [Required]
    public string Name { get; set; } = string.Empty;

    public float ChallengeRating { get; set; }

    public string Type { get; set; } = string.Empty;

    // Use specific type for PostgreSQL JSONB
    [Column(TypeName = "jsonb")]
    public string Data { get; set; } = "{}";
}
