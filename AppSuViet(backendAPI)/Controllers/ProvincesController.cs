using DACN.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DACN.Models;

namespace DACN.Controllers.Api
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProvincesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ProvincesController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/provinces
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            // Kiểm tra DbSet có null (tránh lỗi)
            if (_context.Provinces == null)
                return Problem("DbSet<Province> is null. Check your ApplicationDbContext configuration.");

            var provinces = await _context.Provinces.ToListAsync();
            return Ok(provinces);
        }

        // GET: api/provinces/VN01
        [HttpGet("{code}")]
        public async Task<IActionResult> GetByCode(string code)
        {
            if (_context.Provinces == null)
                return Problem("DbSet<Province> is null.");

            var province = await _context.Provinces.FirstOrDefaultAsync(p => p.Code == code);
            if (province == null)
                return NotFound();

            return Ok(province);
        }
    }
}
