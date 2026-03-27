using DACN.Data;
using DACN.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;

namespace DACN.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class QuizController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public QuizController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET api/quiz/1856-1930
        [HttpGet("{era}")]
        public async Task<ActionResult<IEnumerable<QuizQuestion>>> GetByEra(string era)
        {
            var list = await _context.QuizQuestions
                .Where(q => q.Era == era)
                .ToListAsync();

            if (!list.Any()) return NotFound();

            return Ok(list);
        }
    }

}
