using DACN.Data;
using DACN.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DACN.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HistoricalFiguresController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public HistoricalFiguresController(ApplicationDbContext context)
        {
            _context = context;
        }

        // ==========================================
        // ✅ API: Lấy nhân vật theo TRIỀU ĐẠI (KHÔNG TRÙNG)
        // ==========================================
        [HttpGet("by-era/{eraName}")]
        public async Task<ActionResult<IEnumerable<HistoricalFigure>>> GetFiguresByEra(string eraName)
        {
            // Chuẩn hóa: Nhà_Ngô → Nhà Ngô
            string dynastyName = eraName.Replace("_", " ");

            var figures = await _context.HistoricalFigures
                .Where(h =>
                    h.Dynasty == dynastyName &&
                    (h.Role == "Vua" ||
                     h.Role == "Danh tướng" ||
                     h.Role == "Tướng lĩnh")
                )
                .OrderBy(h => h.Id)
                .ToListAsync();

            return Ok(figures);
        }

        // ==========================================
        // API: Lấy tất cả nhân vật (nếu cần)
        // ==========================================
        [HttpGet("all")]
        public async Task<ActionResult<IEnumerable<HistoricalFigure>>> GetAllHistoricalFigures()
        {
            return Ok(await _context.HistoricalFigures.ToListAsync());
        }
    }
}
