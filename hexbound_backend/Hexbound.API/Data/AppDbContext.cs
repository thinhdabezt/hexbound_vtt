using Microsoft.EntityFrameworkCore;
using Hexbound.API.Models;

namespace Hexbound.API.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Monster> Monsters { get; set; }
    public DbSet<Spell> Spells { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Additional configuration for PostgreSQL
        modelBuilder.Entity<Monster>().HasIndex(m => m.Name);
        modelBuilder.Entity<Spell>().HasIndex(s => s.Name);
    }
}
