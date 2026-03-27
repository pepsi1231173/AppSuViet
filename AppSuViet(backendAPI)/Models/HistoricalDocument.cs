namespace DACN.Models
{
    public class HistoricalDocument
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string DocumentType { get; set; } // "Tuyên ngôn", "Hiệp định", ...
        public string Year { get; set; }
        public string Description { get; set; }
        public string Content { get; set; }
        public string? ImageUrl { get; set; }
    }

}
