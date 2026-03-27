namespace DACN.Services
{
    public class ImageQuestionService
    {
        private readonly OpenAiVisionService _vision;
        private readonly HistoryAiService _history;

        public ImageQuestionService(
            OpenAiVisionService vision,
            HistoryAiService history)
        {
            _vision = vision;
            _history = history;
        }

        public async Task<string> AskByImageAsync(byte[] imageBytes)
        {
            var description = await _vision.DescribeImageAsync(imageBytes);

            if (string.IsNullOrWhiteSpace(description))
                return "❓ Không phân tích được nội dung ảnh.";

            // 🔥 dùng mô tả ảnh để hỏi DB
            var answer = await _history.AskAsync(description);

            if (answer.StartsWith("❓"))
                return "❓ Không nhận dạng được nội dung lịch sử trong ảnh.";

            return
        $@"📸 **Phân tích hình ảnh**
{description}

--------------------------------
{answer}";
        }
    }
}
