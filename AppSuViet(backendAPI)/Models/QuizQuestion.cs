namespace DACN.Models
{
    public class QuizQuestion
    {
        public int Id { get; set; }

        // Giai đoạn – để API lọc
        public string Era { get; set; } = string.Empty;
        // Ví dụ: "1856-1930"

        public string Question { get; set; } = string.Empty;

        // Danh sách 4 lựa chọn
        public List<string> Options { get; set; } = new();

        // Chỉ số đáp án đúng (0–3)
        public int CorrectIndex { get; set; }

        // Giải thích sau khi trả lời
        public string Explanation { get; set; } = string.Empty;
    }

}
