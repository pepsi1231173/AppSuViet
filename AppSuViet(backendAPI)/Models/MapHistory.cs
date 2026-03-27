using System.ComponentModel.DataAnnotations;

namespace DACN.Models
{
    public class MapHistory
    {
        public int Id { get; set; }

        // Thời kỳ (Văn Lang, Âu Lạc, Bắc Thuộc,...)
        public string Period { get; set; } = string.Empty;

        // Chữ màu đỏ lớn trong bản đồ
        public string RedTitle { get; set; } = string.Empty;

        // Năm màu đỏ trong ảnh
        public string RedYear { get; set; } = string.Empty;

        // 🔥 MÔ TẢ CHI TIẾT (ý nghĩa bản đồ, bối cảnh lịch sử...)
        public string Detail { get; set; } = string.Empty;

        // Link ảnh bản đồ
        public string? ImagePath { get; set; }
    }
}
