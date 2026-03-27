using Microsoft.EntityFrameworkCore;
using DACN.Models;

namespace DACN.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        // Bảng chính
        public DbSet<TimelineEvent> TimelineEvents { get; set; }
        public DbSet<VietnamHistoryEvent> VietnamHistoryEvents { get; set; } // ← TÁCH riêng
        public DbSet<Province> Provinces { get; set; }
        public DbSet<Holiday> Holidays { get; set; }
        public DbSet<HistoricalFigure> HistoricalFigures { get; set; }
        public DbSet<HistoricalDocument> HistoricalDocuments { get; set; }
        public DbSet<QuizQuestion> QuizQuestions { get; set; }
        public DbSet<MapHistory> MapHistories { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // =============================
            // 1️⃣ Bảng TimelineEvents (giữ nguyên)
            // =============================
            modelBuilder.Entity<TimelineEvent>(entity =>
            {
                entity.ToTable("TimelineEvents");
                entity.HasKey(e => e.Id);
            });

            // =============================
            // 2️⃣ Bảng VietnamHistoryEvents (bảng riêng)
            // =============================
            modelBuilder.Entity<VietnamHistoryEvent>(entity =>
            {
                entity.ToTable("VietnamHistoryEvents");  // 🔥 Bảng mới, KHÔNG dùng bảng TimelineEvents
                entity.HasKey(e => e.Id);

                entity.Property(e => e.Period).HasMaxLength(255);
                entity.Property(e => e.Year).HasMaxLength(50);
                entity.Property(e => e.EventTitle).HasMaxLength(255);
                entity.Property(e => e.Description).HasColumnType("nvarchar(max)");
            });

            // =============================
            // 3️⃣ Bảng Provinces
            // =============================
            modelBuilder.Entity<Province>(entity =>
            {
                entity.ToTable("Provinces");
                entity.HasKey(p => p.Id);

                entity.Property(p => p.Code)
                      .HasMaxLength(10)
                      .IsRequired();

                entity.Property(p => p.Name)
                      .HasMaxLength(100)
                      .IsRequired();

                entity.Property(p => p.History)
                      .HasMaxLength(100);
            });

          
        }
    }
}
