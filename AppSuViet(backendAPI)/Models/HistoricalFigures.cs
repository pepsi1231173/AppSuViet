using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DACN.Models
{
    [Table("HistoricalFigures")]
    public class HistoricalFigure
    {
        [Key]
        public int Id { get; set; }

        [Column("Dynasty")]
        public string? Dynasty { get; set; }

        [Column("Name")]
        public string? Name { get; set; }

        [Column("ReignPeriod")]
        public string? ReignPeriod { get; set; }

        [Column("Description")]
        public string? Description { get; set; }

        [Column("Detail")]
        public string? Detail { get; set; }   // ⭐ Thêm chi tiết dài

        [Column("ImageUrl")]
        public string? ImageUrl { get; set; }

        [Column("Role")]
        public string? Role { get; set; }
    }
}
