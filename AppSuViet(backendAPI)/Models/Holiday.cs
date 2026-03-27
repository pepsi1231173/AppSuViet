using System;
using System.ComponentModel.DataAnnotations;

namespace DACN.Models
{
    public class Holiday
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Description { get; set; } = string.Empty;

        // Ngày dương
        public DateTime? DateGregorian { get; set; }

        // Ngày âm (dạng chuỗi: "15/08")
        [MaxLength(10)]
        public string? DateLunar { get; set; }

        public bool IsLunar { get; set; }

        [MaxLength(100)]
        public string Type { get; set; } = string.Empty; // Lịch sử, Truyền thống, v.v

        [MaxLength(200)]
        public string? Tags { get; set; } // ví dụ: văn hóa, cách mạng,...

        [MaxLength(255)]
        public string? ImageUrl { get; set; } // <-- Thêm cột hình ảnh
    }
}
