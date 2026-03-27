// Controllers/AiController.cs
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using DACN.Models;
using DACN.Services;

namespace DACN.Controllers
{
    [ApiController]
    [Route("api/ai")]
    public class AiController : ControllerBase
    {
        private readonly HistoryAiService _ai;
        private readonly KnowledgeBaseService _kb;
        private readonly ImageQuestionService _imageAi;
        private readonly ILogger<AiController> _logger;

        public AiController(
            HistoryAiService ai,
            KnowledgeBaseService kb,
            ImageQuestionService imageAi,
            ILogger<AiController> logger)
        {
            _ai = ai;
            _kb = kb;
            _imageAi = imageAi;
            _logger = logger;
        }


        // -------------------------------------------
        // 📌 API: Lời chào khi mở Chat Box
        // -------------------------------------------
        [HttpGet("welcome")]
        public IActionResult Welcome()
        {
            var msg = _ai.GetWelcomeMessage();
            return Ok(new { message = msg });
        }

        // -------------------------------------------
        // 📌 API: Chat với AI lịch sử
        // -------------------------------------------
        [HttpPost("chat")]
        public async Task<IActionResult> Chat([FromBody] AiRequest req)
        {
            if (req == null || string.IsNullOrWhiteSpace(req.Query))
                return BadRequest(new { error = "Query is required" });

            _logger.LogInformation("AI CHAT QUERY: {q}", req.Query);

            // 👉 Gọi thẳng AskAsync (đã xử lý triều đại bên trong)
            var answer = await _ai.AskAsync(req.Query);

            return Ok(new AiResponse
            {
                Answer = answer,
                Sources = new List<string>
        {
            "history-db",
            "wikipedia-vi"
        }
            });
        }


        // -------------------------------------------
        // 📌 API: Rebuild lại Knowledge Base
        // -------------------------------------------
        [HttpPost("rebuild")]
        public async Task<IActionResult> Rebuild()
        {
            await _kb.BuildAsync();
            return Ok(new
            {
                status = "rebuilt",
                docs = _kb.DocumentCount()
            });
        }

        // -------------------------------------------
        // 📌 API: Thông tin KB
        // -------------------------------------------
        [HttpGet("info")]
        public IActionResult Info()
        {
            return Ok(new { docs = _kb.DocumentCount() });
        }
        // -------------------------------------------
        // 📌 API: Nhận ảnh → nhận dạng → trả thông tin lịch sử
        // -------------------------------------------
        [HttpPost("image")]
        public async Task<IActionResult> AskByImage(IFormFile image)
        {
            if (image == null || image.Length == 0)
                return BadRequest("❌ Chưa chọn ảnh.");

            using var ms = new MemoryStream();
            await image.CopyToAsync(ms);

            var result =
                await _imageAi.AskByImageAsync(ms.ToArray());

            return Ok(new
            {
                answer = result,
                sources = new[] { "vision+db" }
            });
        }
    }
}
