using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DACN.Models
{
    [Table("TimelineEvents")]
    public class VietnamHistoryEvent
    {
        [Key]
        public int Id { get; set; }

        [Column("Period")]
        public string? Period { get; set; }

        [Column("Year")]
        public string? Year { get; set; }

        [Column("EventTitle")]
        public string? EventTitle { get; set; }

        [Column("Description")]
        public string? Description { get; set; }
    }
}
