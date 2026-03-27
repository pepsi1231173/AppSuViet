// file: Models/AiRequest.cs
namespace DACN.Models
{
    public class AiRequest
    {
        public string Query { get; set; } = "";
        public bool UseHybrid { get; set; } = false; // nếu true thì dùng OpenAI nếu có key
    }
}
