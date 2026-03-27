using Azure.Core;
using DACN.Data;
using Microsoft.AspNetCore.Mvc;
using System;

namespace DACN.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DocumentsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public DocumentsController(ApplicationDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public IActionResult GetAll()
        {
            var docs = _db.HistoricalDocuments.ToList();

            // build full path
            docs.ForEach(d =>
            {
                if (!string.IsNullOrEmpty(d.ImageUrl))
                {
                    d.ImageUrl = $"{Request.Scheme}://{Request.Host}{d.ImageUrl}";
                }
            });

            return Ok(docs);
        }

        [HttpGet("{id}")]
        public IActionResult Get(int id)
        {
            var doc = _db.HistoricalDocuments.Find(id);

            if (doc == null) return NotFound();

            if (!string.IsNullOrEmpty(doc.ImageUrl))
            {
                doc.ImageUrl = $"{Request.Scheme}://{Request.Host}{doc.ImageUrl}";
            }

            return Ok(doc);
        }
    }

}
