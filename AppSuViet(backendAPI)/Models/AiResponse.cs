// file: Models/AiResponse.cs
using System.Collections.Generic;

namespace DACN.Models
{
    public class AiResponse
    {
        public string Answer { get; set; } = "";
        public List<string>? Sources { get; set; }
    }
}
