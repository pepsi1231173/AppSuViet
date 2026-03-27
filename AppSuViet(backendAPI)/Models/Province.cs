using System.ComponentModel.DataAnnotations;

namespace DACN.Models
{
    public class Province
    {
        public int Id { get; set; }

        [Required]
        [StringLength(10)]
        public string Code { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; }

        [Required]
        public string History { get; set; }

        [StringLength(255)]
        public string? ImageUrl { get; set; } // 🖼️ Thêm dòng này
    }
}
