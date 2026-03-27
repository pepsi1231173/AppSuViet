using DACN.Data;
using DACN.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace z.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HolidaysController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public HolidaysController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/Holidays
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Holiday>>> GetHolidays()
        {
            return await _context.Holidays.OrderBy(h => h.DateGregorian).ToListAsync();
        }

        // GET: api/Holidays/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Holiday>> GetHoliday(int id)
        {
            var holiday = await _context.Holidays.FindAsync(id);

            if (holiday == null)
                return NotFound();

            return holiday;
        }

        // GET: api/Holidays/type/{type}
        [HttpGet("type/{type}")]
        public async Task<ActionResult<IEnumerable<Holiday>>> GetByType(string type)
        {
            return await _context.Holidays
                .Where(h => h.Type.ToLower().Contains(type.ToLower()))
                .ToListAsync();
        }

        // GET: api/Holidays/year/2023
        [HttpGet("year/{year}")]
        public async Task<ActionResult<IEnumerable<Holiday>>> GetByYear(int year)
        {
            return await _context.Holidays
                .Where(h => h.DateGregorian.HasValue && h.DateGregorian.Value.Year == year)
                .ToListAsync();
        }

        // POST: api/Holidays
        [HttpPost]
        public async Task<ActionResult<Holiday>> PostHoliday(Holiday holiday)
        {
            _context.Holidays.Add(holiday);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetHoliday), new { id = holiday.Id }, holiday);
        }

        // PUT: api/Holidays/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> PutHoliday(int id, Holiday holiday)
        {
            if (id != holiday.Id)
                return BadRequest();

            _context.Entry(holiday).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.Holidays.Any(e => e.Id == id))
                    return NotFound();
                else
                    throw;
            }

            return NoContent();
        }

        // DELETE: api/Holidays/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteHoliday(int id)
        {
            var holiday = await _context.Holidays.FindAsync(id);
            if (holiday == null)
                return NotFound();

            _context.Holidays.Remove(holiday);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}
