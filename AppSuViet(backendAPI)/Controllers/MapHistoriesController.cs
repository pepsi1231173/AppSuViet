using DACN.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using DACN.Data;
using DACN.Models;

namespace DACN.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MapHistoryController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public MapHistoryController(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // GET: api/MapHistory
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _context.MapHistories.ToListAsync();
            return Ok(data);
        }

        // GET: api/MapHistory/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var item = await _context.MapHistories.FindAsync(id);
            if (item == null) return NotFound();
            return Ok(item);
        }

        // POST: api/MapHistory
        [HttpPost]
        public async Task<IActionResult> Create([FromForm] MapHistory model, IFormFile? image)
        {
            if (image != null)
            {
                var fileName = $"{Guid.NewGuid()}_{image.FileName}";
                var folder = Path.Combine(_env.WebRootPath, "maps");

                if (!Directory.Exists(folder))
                    Directory.CreateDirectory(folder);

                var filePath = Path.Combine(folder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(stream);
                }

                model.ImagePath = "/maps/" + fileName;
            }

            _context.MapHistories.Add(model);
            await _context.SaveChangesAsync();

            return Ok(model);
        }

        // PUT: api/MapHistory/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromForm] MapHistory model, IFormFile? image)
        {
            var item = await _context.MapHistories.FindAsync(id);
            if (item == null) return NotFound();

            item.Period = model.Period;
            item.RedTitle = model.RedTitle;
            item.RedYear = model.RedYear;
            item.Detail = model.Detail; // 🔥 BẮT BUỘC

            if (image != null)
            {
                var fileName = $"{Guid.NewGuid()}_{image.FileName}";
                var folder = Path.Combine(_env.WebRootPath, "maps");

                if (!Directory.Exists(folder))
                    Directory.CreateDirectory(folder);

                var filePath = Path.Combine(folder, fileName);
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(stream);
                }

                item.ImagePath = "/maps/" + fileName;
            }

            await _context.SaveChangesAsync();
            return Ok(item);
        }

        // DELETE: api/MapHistory/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _context.MapHistories.FindAsync(id);
            if (item == null) return NotFound();

            _context.MapHistories.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Deleted" });
        }
    }
}
