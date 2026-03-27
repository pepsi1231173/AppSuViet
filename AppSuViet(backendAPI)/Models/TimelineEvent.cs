public class TimelineEvent
{
    public int Id { get; set; }
    public string Period { get; set; } = string.Empty;
    public string Year { get; set; } = string.Empty;
    public string EventTitle { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? Details { get; set; }
    public string? ImageUrl { get; set; }

    // ⭐ MỚI
    public string Dynasty { get; set; } = string.Empty;
}
