// file: Models/KbDocument.cs
using System;

namespace DACN.Models
{
    public class KbDocument
    {
        public int Id { get; set; }             // internal id
        public string Title { get; set; } = "";
        public string Text { get; set; } = "";
        public string Source { get; set; } = ""; // e.g. "figure","timeline","document"
    }
}
