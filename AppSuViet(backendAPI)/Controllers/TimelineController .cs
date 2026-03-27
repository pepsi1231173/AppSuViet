using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.RegularExpressions;
using DACN.Data;
using DACN.Models;

namespace DACN.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TimelineController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public TimelineController(ApplicationDbContext context)
        {
            _context = context;
        }

        // 🔍 Parse năm từ chuỗi SQL (TCN, dạng khoảng…)
        private int ParseYear(string yearText)
        {
            if (string.IsNullOrWhiteSpace(yearText))
                return 0;

            yearText = yearText.Trim();

            if (yearText.Contains("–"))
            {
                var first = yearText.Split("–")[0].Trim();
                return ParseYear(first);
            }

            if (yearText.Contains("TCN"))
            {
                var num = Regex.Match(yearText, @"\d+").Value;
                return -int.Parse(num);
            }

            if (int.TryParse(yearText, out int result))
                return result;

            return 0;
        }

        // ================== API CŨ ==================
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var list = await _context.TimelineEvents.OrderBy(e => e.Id).ToListAsync();
            return Ok(list);
        }

        [HttpGet("year/{year}")]
        public async Task<IActionResult> GetByYear(string year)
        {
            var results = await _context.TimelineEvents
                .Where(e => e.Year.Contains(year))
                .OrderBy(e => e.Id)
                .ToListAsync();

            return Ok(results);
        }

        [HttpGet("period/{period}")]
        public async Task<IActionResult> GetByPeriod(string period)
        {
            var results = await _context.TimelineEvents
                .Where(e => e.Period.Contains(period))
                .OrderBy(e => e.Id)
                .ToListAsync();

            return Ok(results);
        }

        [HttpPost]
        public async Task<IActionResult> Add([FromBody] TimelineEvent model)
        {
            _context.TimelineEvents.Add(model);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Thêm thành công", data = model });
        }


        // ================== 🎯 API MỚI — lấy theo triều đại ==================
        // ================== 🎯 API MỚI — lấy theo triều đại (KHÔNG LẶP) ==================
        // ================== 🎯 API MỚI — lấy theo triều đại (DỰA VÀO DYNASTY) ==================
        [HttpGet("events-by-era/{eraName}")]
        public async Task<IActionResult> GetEventsByEra(string eraName)
        {
            var dynastyMap = new Dictionary<string, string[]>
            {
                ["Nhà_Ngô"] = new[] { "Nhà Ngô" },
                ["Nhà_Đinh"] = new[] { "Nhà Đinh" },
                ["Nhà_Tiền_Lê"] = new[] { "Nhà Tiền Lê" },
                ["Nhà_Lý"] = new[] { "Nhà Lý" },
                ["Nhà_Trần"] = new[] { "Nhà Trần" },
                ["Nhà_Hồ"] = new[] { "Nhà Hồ" },
                ["Nhà_Hậu_Lê"] = new[] { "Nhà Hậu Lê", "Lê Trung Hưng – Trịnh Nguyễn phân tranh" },
                ["Nhà_Mạc"] = new[] { "Nhà Mạc" },
                ["Nhà_Tây_Sơn"] = new[] { "Nhà Tây Sơn" },
                ["Nhà_Nguyễn"] = new[] { "Nhà Nguyễn" }
            };

            if (!dynastyMap.ContainsKey(eraName))
                return BadRequest("Tên triều đại không hợp lệ!");

            var dynastyNames = dynastyMap[eraName];

            var events = await _context.TimelineEvents
                .Where(e => dynastyNames.Contains(e.Dynasty))
                .OrderBy(e => e.Id)
                .ToListAsync();

            return Ok(events);
        }

    }
}
