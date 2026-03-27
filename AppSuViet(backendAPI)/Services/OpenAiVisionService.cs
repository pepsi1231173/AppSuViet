using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace DACN.Services
{
    public class OpenAiVisionService
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public OpenAiVisionService(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        public async Task<string?> DescribeImageAsync(byte[] imageBytes)
        {
            var apiKey = _config["OpenAI:ApiKey"];
            if (string.IsNullOrWhiteSpace(apiKey)) return null;

            var base64 = Convert.ToBase64String(imageBytes);

            var payload = new
            {
                model = "gpt-4.1-mini",
                input = new[]
                {
            new
            {
                role = "user",
                content = new object[]
                {
                    new
                    {
                        type = "input_text",
                        text =
@"Mô tả chi tiết ảnh này.
Tập trung vào:
- Nhân vật
- Trang phục
- Bối cảnh
- Thời kỳ lịch sử
Viết bằng tiếng Việt."
                    },
                    new
                    {
                        type = "input_image",
                        image_url = $"data:image/jpeg;base64,{base64}"
                    }
                }
            }
        }
            };

            var req = new HttpRequestMessage(
                HttpMethod.Post,
                "https://api.openai.com/v1/responses");

            req.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", apiKey);

            req.Content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");

            var res = await _http.SendAsync(req);
            var json = await res.Content.ReadAsStringAsync();

            using var doc = JsonDocument.Parse(json);

            if (!doc.RootElement.TryGetProperty("output_text", out var output))
                return null;

            return output.GetString();
        }
    }
}
