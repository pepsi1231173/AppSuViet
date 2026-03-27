using DACN.Data;
using DACN.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Text.RegularExpressions;
using System.IO;
using System.Net.Http;
using System.Text.Json;
using System.Globalization;


namespace DACN.Services
{
    public class HistoryAiService
    {
        private readonly ApplicationDbContext _db;
        private readonly ILogger<HistoryAiService> _logger;

        public HistoryAiService(ApplicationDbContext db, ILogger<HistoryAiService> logger)
        {
            _db = db;
            _logger = logger;
        }

        // ======================================================
        // WELCOME
        // ======================================================
        public string GetWelcomeMessage()
        {
            return "Xin chào! 👋 Bạn muốn tìm hiểu điều gì về lịch sử Việt Nam?";
        }

        // ======================================================
        // MAIN ENTRY
        // ======================================================
        public async Task<string> AskAsync(string question)
        {
            if (string.IsNullOrWhiteSpace(question))
                return "❗ Bạn hãy nhập câu hỏi nhé.";

            string normalized = Normalize(question);
            string cleaned = CleanQuestion(normalized);

            // ======================================================
            // 🔥 ƯU TIÊN TRIỀU ĐẠI (WIKIPEDIA / DYNASTY)
            // ======================================================
            var dynastyAnswer = await TryAnswerDynasty(cleaned);
            if (dynastyAnswer != null)
            {
                return WrapAnswer(dynastyAnswer, cleaned);
            }


            bool askImage = IsAskingForImage(cleaned);
            bool onlyImage = IsOnlyAskingImage(cleaned);

            // 🔥 TRÍCH URL ẢNH
            string? imageUrl = ExtractImageUrl(question);

            _logger.LogInformation("UserQuestion: {q}", question);

            // ======================================================
            // 🔥 NHẬN DIỆN NHÂN VẬT QUA ẢNH (SO FILE NAME)
            // ======================================================
            if (!string.IsNullOrWhiteSpace(imageUrl))
            {
                string inputFile = GetImageFileName(imageUrl);

                _logger.LogWarning("INPUT IMAGE FILE: {f}", inputFile);

                var figureByImage = await _db.HistoricalFigures
                    .AsNoTracking()
                    .FirstOrDefaultAsync(x =>
                        !string.IsNullOrWhiteSpace(x.ImageUrl) &&
                        GetImageFileName(x.ImageUrl) == inputFile
                    );

                if (figureByImage != null)
                {
                    string content = await AnswerHistoricalFigure(
                         figureByImage,
                         question: "thông tin nhân vật",
                         askImage: true,
                         onlyImage: false
                     );

                    return WrapAnswer(content, "ảnh được cung cấp");
                }
            }

            // ======================================================
            // TRẢ LỜI THEO TÊN / SỰ KIỆN / VĂN BẢN
            // ======================================================
            string? result = await AnswerByRuleAsync(cleaned, askImage, onlyImage);

            if (result != null)
            {
                if (onlyImage)
                    return result;

                return WrapAnswer(result, cleaned);
            }

            return "❓ Mình chưa nhận diện được nhân vật hoặc nội dung trong câu hỏi này.";
        }

        // overload
        public async Task<string> AskAsync(string question, bool useHybrid)
        {
            return await AskAsync(question);
        }

        // ======================================================
        // TEXT PROCESSING
        // ======================================================
        private string Normalize(string text)
            => text.ToLower().Trim();
        private List<string> BuildAliases(HistoricalFigure f)
        {
            var aliases = new List<string>();

            if (!string.IsNullOrWhiteSpace(f.Name))
            {
                aliases.AddRange(
                    f.Name.ToLower()
                          .Split(new[] { "/", "-", ",", "(", ")" }, StringSplitOptions.RemoveEmptyEntries)
                          .Select(x => x.Trim())
                );
            }

            // ==================================================
            // TRUYỀN THUYẾT – DỰNG NƯỚC
            // ==================================================
            if (f.Name.Contains("Lạc Long Quân", StringComparison.OrdinalIgnoreCase))
                aliases.Add("sùng lãm");

            if (f.Name.Contains("Kinh Dương Vương", StringComparison.OrdinalIgnoreCase))
                aliases.Add("lộc tục");

            // ==================================================
            // ÂU LẠC – NGÔ
            // ==================================================
            if (f.Name.Contains("Thục Phán", StringComparison.OrdinalIgnoreCase))
            {
                aliases.Add("an dương vương");
            }

            if (f.Name.Contains("Ngô Quyền", StringComparison.OrdinalIgnoreCase))
                aliases.Add("ngô vương");

            if (f.Name.Contains("Ngô Chân Lưu", StringComparison.OrdinalIgnoreCase))
                aliases.Add("khuông việt đại sư");

            // ==================================================
            // NHÀ ĐINH – TIỀN LÊ
            // ==================================================
            if (f.Name.Contains("Đinh Bộ Lĩnh", StringComparison.OrdinalIgnoreCase))
                aliases.Add("đinh tiên hoàng");

            if (f.Name.Contains("Đinh Toàn", StringComparison.OrdinalIgnoreCase))
                aliases.Add("đinh phế đế");

            if (f.Name.Contains("Lê Đại Hành", StringComparison.OrdinalIgnoreCase)
                || f.Name.Contains("Lê Hoàn", StringComparison.OrdinalIgnoreCase))
            {
                aliases.Add("lê hoàn");
                aliases.Add("lê đại hành");
            }

            if (f.Name.Contains("Lê Long Đĩnh", StringComparison.OrdinalIgnoreCase))
                aliases.Add("lê ngọa triều");

            if (f.Name.Contains("Dương Vân Nga", StringComparison.OrdinalIgnoreCase))
                aliases.Add("đại thắng minh hoàng hậu");

            // ==================================================
            // NHÀ LÝ
            // ==================================================
            if (f.Name.Contains("Lý Thái Tổ", StringComparison.OrdinalIgnoreCase)
                || f.Name.Contains("Lý Công Uẩn", StringComparison.OrdinalIgnoreCase))
            {
                aliases.Add("lý công uẩn");
                aliases.Add("lý thái tổ");
            }

            if (f.Name.Contains("Lý Thường Kiệt", StringComparison.OrdinalIgnoreCase))
                aliases.Add("ngô tuấn");

            // ==================================================
            // NHÀ TRẦN
            // ==================================================
            if (f.Name.Contains("Trần Quốc Tuấn", StringComparison.OrdinalIgnoreCase)
                || f.Name.Contains("Trần Hưng Đạo", StringComparison.OrdinalIgnoreCase))
            {
                aliases.AddRange(new[]
                {
            "trần hưng đạo",
            "hưng đạo đại vương",
            "quốc công tiết chế",
            "đức thánh trần",
            "thánh trần"
        });
            }

            if (f.Name.Contains("Trần Nhân Tông", StringComparison.OrdinalIgnoreCase))
            {
                aliases.Add("trần khâm");
                aliases.Add("điều ngự giác hoàng");
            }

            if (f.Name.Contains("Trần Quang Khải", StringComparison.OrdinalIgnoreCase))
                aliases.Add("chiêu minh đại vương");

            // ==================================================
            // HẬU LÊ
            // ==================================================
            if (f.Name.Contains("Lê Lợi", StringComparison.OrdinalIgnoreCase))
            {
                aliases.Add("bình định vương");
                aliases.Add("lê thái tổ");
            }

            if (f.Name.Contains("Lê Thánh Tông", StringComparison.OrdinalIgnoreCase))
                aliases.Add("lê tư thành");

            if (f.Name.Contains("Lê Uy Mục", StringComparison.OrdinalIgnoreCase))
                aliases.Add("quỷ vương");

            if (f.Name.Contains("Lê Tương Dực", StringComparison.OrdinalIgnoreCase))
                aliases.Add("trư vương");

            // ==================================================
            // TÂY SƠN
            // ==================================================
            if (f.Name.Contains("Nguyễn Nhạc", StringComparison.OrdinalIgnoreCase))
                aliases.Add("thái đức hoàng đế");

            if (f.Name.Contains("Nguyễn Huệ", StringComparison.OrdinalIgnoreCase))
            {
                aliases.Add("quang trung");
                aliases.Add("quang trung hoàng đế");
            }

            if (f.Name.Contains("Nguyễn Quang Toản", StringComparison.OrdinalIgnoreCase))
                aliases.Add("cảnh thịnh");

            // ==================================================
            // NHÀ NGUYỄN
            // ==================================================
            if (f.Name.Contains("Nguyễn Ánh", StringComparison.OrdinalIgnoreCase))
                aliases.Add("gia long");

            if (f.Name.Contains("Nguyễn Phúc Đảm", StringComparison.OrdinalIgnoreCase))
                aliases.Add("minh mạng");

            if (f.Name.Contains("Nguyễn Phúc Miên Tông", StringComparison.OrdinalIgnoreCase))
                aliases.Add("thiệu trị");

            if (f.Name.Contains("Nguyễn Phúc Hồng Nhậm", StringComparison.OrdinalIgnoreCase))
                aliases.Add("tự đức");

            if (f.Name.Contains("Nguyễn Phúc Ưng Đăng", StringComparison.OrdinalIgnoreCase))
                aliases.Add("hiệp hòa");

            if (f.Name.Contains("Nguyễn Phúc Hồng Dật", StringComparison.OrdinalIgnoreCase))
                aliases.Add("kiến phúc");

            if (f.Name.Contains("Nguyễn Phúc Ưng Lịch", StringComparison.OrdinalIgnoreCase))
                aliases.Add("hàm nghi");

            if (f.Name.Contains("Nguyễn Phúc Bửu Lân", StringComparison.OrdinalIgnoreCase))
                aliases.Add("đồng khánh");

            if (f.Name.Contains("Nguyễn Phúc Bửu Chánh", StringComparison.OrdinalIgnoreCase))
                aliases.Add("duy tân");

            if (f.Name.Contains("Nguyễn Phúc Bửu Đảo", StringComparison.OrdinalIgnoreCase))
                aliases.Add("khải định");

            if (f.Name.Contains("Nguyễn Phúc Vĩnh Thụy", StringComparison.OrdinalIgnoreCase))
                aliases.Add("bảo đại");

            // ==================================================
            // CẬN – HIỆN ĐẠI
            // ==================================================
            if (f.Name.Contains("Hồ Chí Minh", StringComparison.OrdinalIgnoreCase)
                || f.Name.Contains("Nguyễn Ái Quốc", StringComparison.OrdinalIgnoreCase))
            {
                aliases.AddRange(new[]
                {
            "bác hồ",
            "nguyễn ái quốc",
            "nguyễn tất thành",
            "chủ tịch hồ chí minh"
        });
            }

            if (f.Name.Contains("Hoàng Hoa Thám", StringComparison.OrdinalIgnoreCase))
                aliases.Add("đề thám");

            if (f.Name.Contains("Trương Định", StringComparison.OrdinalIgnoreCase))
                aliases.Add("bình tây đại nguyên soái");

            if (f.Name.Contains("Phan Bội Châu", StringComparison.OrdinalIgnoreCase))
                aliases.Add("sào nam");

            if (f.Name.Contains("Huỳnh Thúc Kháng", StringComparison.OrdinalIgnoreCase))
                aliases.Add("mính viên");

            if (f.Name.Contains("Trường Chinh", StringComparison.OrdinalIgnoreCase))
                aliases.Add("đặng xuân khu");

            if (f.Name.Contains("Lê Duẩn", StringComparison.OrdinalIgnoreCase))
                aliases.Add("anh ba");

            return aliases.Distinct().ToList();
        }
        private string NormalizeText(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return "";

            text = text.ToLower();

            string[] noise =
            {
        "trận","cuộc","chiến thắng","sự kiện","phong trào",
        "về","là","năm","khi","đã","diễn ra","xảy ra"
    };

            foreach (var n in noise)
                text = text.Replace(n, "");

            return Regex.Replace(text, @"\s+", " ").Trim();
        }
        private List<string> BuildEventKeywords(TimelineEvent e)
        {
            var keys = new List<string>();

            // tên sự kiện (đã làm sạch)
            if (!string.IsNullOrWhiteSpace(e.EventTitle))
                keys.Add(NormalizeText(e.EventTitle));

            // năm
            if (!string.IsNullOrWhiteSpace(e.Year))
                keys.Add(e.Year.Trim());

            return keys;
        }
        private bool IsDocumentQuestion(string q)
        {
            return Regex.IsMatch(q,
                @"(tuyên ngôn|hiệp định|hiến pháp|nghị quyết|chỉ thị|sắc lệnh|lời kêu gọi|tuyên bố|văn kiện)");
        }
        private List<string> BuildDocumentKeywords(HistoricalDocument d)
        {
            var keys = new List<string>();

            if (!string.IsNullOrWhiteSpace(d.Title))
                keys.Add(NormalizeText(d.Title));

            if (!string.IsNullOrWhiteSpace(d.DocumentType))
                keys.Add(NormalizeText(d.DocumentType));

            if (!string.IsNullOrWhiteSpace(d.Year))
                keys.Add(d.Year.Trim());

            return keys.Distinct().ToList();
        }
        private string? ExtractYear(string q)
        {
            var match = Regex.Match(q, @"\b(1[0-9]{3}|20[0-9]{2})\b");
            return match.Success ? match.Value : null;
        }
        private bool IsMapQuestion(string q)
        {
            return Regex.IsMatch(q,
                @"(bản đồ|lãnh thổ|biên giới|địa giới|không gian lãnh thổ)");
        }

        private string RemoveDiacritics(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return "";

            var normalized = text.Normalize(System.Text.NormalizationForm.FormD);
            var chars = normalized
                .Where(c => System.Globalization.CharUnicodeInfo.GetUnicodeCategory(c)
                            != System.Globalization.UnicodeCategory.NonSpacingMark)
                .ToArray();

            return new string(chars).Normalize(System.Text.NormalizationForm.FormC);
        }
        private bool IsBirthDeathQuestion(string q)
        {
            return Regex.IsMatch(q,
                @"(sinh năm|sinh năm nào|sinh bao nhiêu|mất năm|mất năm nào|qua đời năm)");
        }
        private (string? birth, string? death) ExtractBirthDeath(string? reignPeriod)
        {
            if (string.IsNullOrWhiteSpace(reignPeriod))
                return (null, null);

            // Ví dụ: "1890–1969" | "898–944" | "?–43"
            var parts = reignPeriod
                .Replace("–", "-")
                .Split('-', StringSplitOptions.RemoveEmptyEntries);

            string? birth = parts.Length > 0 && parts[0].Trim() != "?"
                ? parts[0].Trim()
                : null;

            string? death = parts.Length > 1 && parts[1].Trim() != "?"
                ? parts[1].Trim()
                : null;

            return (birth, death);
        }

        private string CleanQuestion(string q)
        {
            string[] noiseWords =
            {
                "cho tui","cho tôi","tui","tôi",
                "hãy","hãy cho","hãy cho tui biết",
                "bạn hãy","bạn có thể",
                "làm ơn","giúp tui","giúp tôi",
                "biết","thông tin","về",
                "là ai","là gì","không","vậy","nha"
            };

            foreach (var w in noiseWords)
                q = q.Replace(w, "");

            q = q.Replace("bác hồ", "hồ chí minh");

            return Regex.Replace(q, @"\s+", " ").Trim();
        }

        private string WrapAnswer(string content, string keyword)
        {
            return
                $"✨ **Mình vừa tra cứu và tìm được thông tin liên quan đến _{keyword}_ cho bạn:**\n\n" +
                content +
                "\n\n📚 *Nếu bạn muốn biết thêm sự kiện, nhân vật hoặc mốc thời gian liên quan, cứ hỏi tiếp nhé!*";
        }

        // ======================================================
        // IMAGE UTILS (CHUẨN – KHÔNG FAIL)
        // ======================================================
        private string? ExtractImageUrl(string text)
        {
            var match = Regex.Match(
                text,
                @"(http[s]?:\/\/[^\s""']+\.(jpg|jpeg|png|webp))",
                RegexOptions.IgnoreCase
            );

            if (match.Success)
                return match.Value.Trim();

            return null;
        }

        private string GetImageFileName(string path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return "";

            return Path.GetFileName(path).ToLower().Trim();
        }

        private bool IsAskingForImage(string q)
        {
            return Regex.IsMatch(q, @"(ảnh|hình|hình ảnh|cho xem|xem ảnh)");
        }

        private bool IsOnlyAskingImage(string q)
        {
            return Regex.IsMatch(q, @"^(ảnh|hình|hình ảnh|cho xem ảnh|xem ảnh)");
        }
        private bool IsRoleQuestion(string q)
        {
            return Regex.IsMatch(q,
                @"(là ai|vai trò|chức vụ|giữ chức|làm gì|thuộc vai trò|ông là ai|bà là ai)");
        }
        private bool IsHolidayQuestion(string q)
        {
            return Regex.IsMatch(q,
                @"(tết|ngày giỗ|giỗ|lễ|lễ hội|kỷ niệm|ngày mất|tưởng niệm)");
        }

        private string FormatHolidayType(string? type)
        {
            if (string.IsNullOrWhiteSpace(type))
                return "Không xác định";

            return type.Trim();
        }

        // ======================================================
        // RULE CONTROLLER
        // ======================================================
        private async Task<string?> AnswerByRuleAsync(string q, bool askImage, bool onlyImage)
        {
            var qn = NormalizeText(q);
            var yearInQuestion = ExtractYear(qn);

            // ==================================================
            // 1️⃣ DOCUMENT – ƯU TIÊN CAO NHẤT
            // ==================================================
            if (IsDocumentQuestion(qn))
            {
                var docs = await _db.HistoricalDocuments
                    .AsNoTracking()
                    .ToListAsync();

                var doc = docs.FirstOrDefault(d =>
                {
                    if (string.IsNullOrWhiteSpace(d.Title))
                        return false;

                    // bắt buộc match title
                    if (!qn.Contains(NormalizeText(d.Title)))
                        return false;

                    // nếu có hỏi năm → phải khớp
                    if (!string.IsNullOrWhiteSpace(yearInQuestion))
                    {
                        if (string.IsNullOrWhiteSpace(d.Year))
                            return false;

                        return d.Year.Trim() == yearInQuestion;
                    }

                    return true;
                });

                if (doc != null)
                    return await AnswerDocument(doc, askImage, onlyImage);

                if (!string.IsNullOrWhiteSpace(yearInQuestion))
                {
                    return
                        $"❌ Không tìm thấy văn kiện phù hợp với năm **{yearInQuestion}**.\n\n" +
                        $"📌 *Ví dụ đúng: **Tuyên ngôn Độc lập (1945)**.*";
                }
            }

            // ==================================================
            // 2️⃣ HOLIDAY – CHỈ MATCH KHI TỒN TẠI THẬT
            // ==================================================
            if (IsHolidayQuestion(qn))
            {
                var holidays = await _db.Holidays
                    .AsNoTracking()
                    .ToListAsync();

                var holiday = holidays.FirstOrDefault(h =>
                {
                    if (string.IsNullOrWhiteSpace(h.Name))
                        return false;

                    // so sánh tên – có dấu & không dấu
                    var name = NormalizeText(h.Name);
                    var nameNoSign = RemoveDiacritics(name);

                    var qClean = NormalizeText(qn);
                    var qNoSign = RemoveDiacritics(qClean);

                    return qClean.Contains(name) || qNoSign.Contains(nameNoSign);
                });

                if (holiday != null)
                    return await AnswerHoliday(holiday, askImage, onlyImage);

                // ❌ KHÔNG CÓ TRONG DATABASE → DỪNG
                return null;
            }



            // ==================================================
            // 3️⃣ FIGURE
            // ==================================================
            var figures = await _db.HistoricalFigures
                .AsNoTracking()
                .ToListAsync();

            var figure = figures.FirstOrDefault(f =>
                BuildAliases(f).Any(a => q.Contains(a)));

            if (figure != null)
                return await AnswerHistoricalFigure(
                    figure,
                    q,
                    askImage,
                    onlyImage
                );

            // ==================================================
            // 4️⃣ EVENT
            // ==================================================
            var events = await _db.TimelineEvents
                .AsNoTracking()
                .ToListAsync();

            var ev = events.FirstOrDefault(e =>
                BuildEventKeywords(e).Any(k => qn.Contains(k)));

            if (ev != null)
                return await AnswerTimelineEvent(ev, askImage, onlyImage);
            // ==================================================
            //5 MAP HISTORY (BẢN ĐỒ LỊCH SỬ)
            // ==================================================
            if (IsMapQuestion(qn))
            {
                var maps = await _db.MapHistories
                    .AsNoTracking()
                    .ToListAsync();

                var map = maps.FirstOrDefault(m =>
                    qn.Contains(NormalizeText(m.RedTitle)) ||
                    qn.Contains(NormalizeText(m.Period)) ||
                    (!string.IsNullOrWhiteSpace(m.RedYear) && qn.Contains(m.RedYear))
                );

                if (map != null)
                    return await AnswerMapHistory(map, askImage, onlyImage);
            }


            // ==================================================
            // 6 PROVINCE
            // ==================================================
            var province = await _db.Provinces
                .AsNoTracking()
                .FirstOrDefaultAsync(x => q.Contains(x.Name!.ToLower()));

            if (province != null)
                return await AnswerProvince(province, askImage, onlyImage);

            return null;
        }

        // ======================================================
        // ANSWERS
        // ======================================================
        private async Task<string> AnswerHistoricalFigure(
    HistoricalFigure f,
    string question,
    bool askImage,
    bool onlyImage)
        {
            // 👉 CHỈ XEM ẢNH
            if (onlyImage)
                return !string.IsNullOrWhiteSpace(f.ImageUrl)
                    ? $"[[IMAGE]]{f.ImageUrl}"
                    : "❌ Không có ảnh của nhân vật này.";

            var (birth, death) = ExtractBirthDeath(f.ReignPeriod);

            // 👉 HỎI SINH / MẤT
            if (IsBirthDeathQuestion(question))
            {
                string birthDeathResult =
                    $"👤 **{f.Name}**\n\n";

                if (question.Contains("sinh") && !string.IsNullOrWhiteSpace(birth))
                    birthDeathResult += $"📆 **Sinh năm:** {birth}\n";

                if ((question.Contains("mất") || question.Contains("qua đời"))
                    && !string.IsNullOrWhiteSpace(death))
                    birthDeathResult += $"🕊️ **Mất năm:** {death}\n";

                if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                    birthDeathResult += $"\n\n[[IMAGE]]{f.ImageUrl}";

                return birthDeathResult;
            }

            // 👉 HỎI VAI TRÒ
            if (IsRoleQuestion(question))
            {
                string roleText = !string.IsNullOrWhiteSpace(f.Role)
                    ? f.Role
                    : "Chưa xác định rõ trong sử liệu";

                string roleAnswer =
                    $"👤 **{f.Name}**\n\n" +
                    $"🔰 **Vai trò / Chức vị:** {roleText}\n";

                if (!string.IsNullOrWhiteSpace(f.Dynasty))
                    roleAnswer += $"🏛 Triều đại: {f.Dynasty}\n";

                if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                    roleAnswer += $"\n\n[[IMAGE]]{f.ImageUrl}";

                return roleAnswer;
            }

            // 👉 TRẢ LỜI ĐẦY ĐỦ
            string result =
                $"👤 **{f.Name}**\n\n" +
                $"🔰 Vai trò: {f.Role}\n" +
                $"🏛 Triều đại: {f.Dynasty}\n" +
                $"📆 Năm sinh – mất: {f.ReignPeriod}\n\n" +
                $"📌 {f.Description}\n\n" +
                $"{f.Detail}";

            if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                result += $"\n\n[[IMAGE]]{f.ImageUrl}";

            return result;
        }



        private async Task<string> AnswerTimelineEvent(
            TimelineEvent f, bool askImage, bool onlyImage)
        {
            if (onlyImage)
                return !string.IsNullOrWhiteSpace(f.ImageUrl)
                    ? $"[[IMAGE]]{f.ImageUrl}"
                    : "❌ Không có ảnh tư liệu.";

            string result =
                $"🔥 **{f.EventTitle} ({f.Year})**\n\n" +
                $"{f.Description}\n\n" +
                $"{f.Details}";

            if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                result += $"\n\n\n[[IMAGE]]{f.ImageUrl}";

            return result;
        }

        private async Task<string> AnswerDocument(
            HistoricalDocument f, bool askImage, bool onlyImage)
        {
            if (onlyImage)
                return !string.IsNullOrWhiteSpace(f.ImageUrl)
                    ? $"[[IMAGE]]{f.ImageUrl}"
                    : "❌ Không có ảnh tư liệu.";

            string result =
                $"📜 **{f.Title} ({f.Year})**\n\n" +
                $"{f.Description}\n\n" +
                $"{f.Content}";

            if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                result += $"\n\n\n[[IMAGE]]{f.ImageUrl}";

            return result;
        }

        private async Task<string> AnswerProvince(
            Province f, bool askImage, bool onlyImage)
        {
            if (onlyImage)
                return !string.IsNullOrWhiteSpace(f.ImageUrl)
                    ? $"[[IMAGE]]{f.ImageUrl}"
                    : "❌ Không có ảnh.";

            string result = $"📍 **{f.Name}**\n\n{f.History}";

            if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                result += $"\n\n\n[[IMAGE]]{f.ImageUrl}";

            return result;
        }

        private async Task<string> AnswerHoliday(
     Holiday f, bool askImage, bool onlyImage)
        {
            if (onlyImage)
                return !string.IsNullOrWhiteSpace(f.ImageUrl)
                    ? $"[[IMAGE]]{f.ImageUrl}"
                    : "❌ Không có ảnh lễ hội.";

            string result =
                $"🎉 **{f.Name}**\n\n" +
                $"{f.Description}\n\n" +
                $"🏷️ **Loại:** {FormatHolidayType(f.Type)}\n" +
                $"📅 Âm lịch: {f.DateLunar}\n" +
                $"📆 Dương lịch: {f.DateGregorian:dd/MM/yyyy}";

            if (askImage && !string.IsNullOrWhiteSpace(f.ImageUrl))
                result += $"\n\n[[IMAGE]]{f.ImageUrl}";

            return result;
        }
        private string? NormalizeImagePath(string? path)
        {
            if (string.IsNullOrWhiteSpace(path))
                return null;

            // bỏ wwwroot
            if (path.StartsWith("wwwroot"))
                path = path.Replace("wwwroot", "");

            // đảm bảo có dấu /
            if (!path.StartsWith("/"))
                path = "/" + path;

            return path;
        }

        private async Task<string> AnswerMapHistory(
    MapHistory m,
    bool askImage,
    bool onlyImage)
        {
            var image = NormalizeImagePath(m.ImagePath);

            if (onlyImage)
                return image != null
                    ? $"[[IMAGE]]{image}"
                    : "❌ Không có bản đồ cho giai đoạn này.";

            string result =
                $"🗺️ **{m.RedTitle}**\n\n" +
                $"⏳ **Thời gian:** {m.RedYear}\n" +
                $"🏛 **Giai đoạn:** {m.Period}\n\n" +
                $"{m.Detail}";

            if (askImage && image != null)
                result += $"\n\n[[IMAGE]]{image}";

            return result;
        }

        // ======================================================
        // DYNASTY (TRIỀU ĐẠI VIỆT NAM)
        // ======================================================
        private static readonly Dictionary<string, (string wiki, int start, int end)> Dynasties =
     new()
     {
        { "nhà ngô", ("Nhà Ngô", 939, 965) },
        { "nhà đinh", ("Nhà Đinh", 968, 980) },
        { "nhà tiền lê", ("Nhà Tiền Lê", 980, 1009) },
        { "nhà lý", ("Nhà Lý", 1009, 1225) },
        { "nhà trần", ("Nhà Trần", 1226, 1400) },
        { "nhà hồ", ("Nhà Hồ", 1400, 1407) },
        { "nhà hậu lê", ("Nhà Hậu Lê", 1428, 1789) },
        { "nhà mạc", ("Nhà Mạc", 1527, 1677) },
        { "nhà tây sơn", ("Nhà Tây Sơn", 1778, 1802) },
        { "nhà nguyễn", ("Nhà Nguyễn", 1802, 1945) },
     };


        private async Task<string?> TryAnswerDynasty(string question)
        {
            var q = question.ToLower();
            bool askFlag = IsAskingForFlag(q);

            foreach (var d in Dynasties)
            {
                if (q.Contains(d.Key))
                {
                    // 🟨 HỎI CỜ TRIỀU ĐẠI
                    if (askFlag)
                    {
                        return $"[[FLAG]]{CultureInfo.CurrentCulture.TextInfo.ToTitleCase(d.Key)}";
                    }

                    // 📖 HỎI THÔNG TIN TRIỀU ĐẠI
                    var wikiText = await FetchWikipedia(d.Value.wiki);

                    return
        $"""
🏛️ **{CultureInfo.CurrentCulture.TextInfo.ToTitleCase(d.Key)}**
📅 **Thời gian tồn tại:** {d.Value.start} – {d.Value.end}

📖 **Giới thiệu:**
{wikiText}

📚 *Nguồn: Wikipedia tiếng Việt*
""";
                }
            }

            return null;
        }


        private async Task<string> FetchWikipedia(string title)
        {
            try
            {
                using var http = new HttpClient();

                // 🔥 BẮT BUỘC có User-Agent
                http.DefaultRequestHeaders.UserAgent.ParseAdd(
                    "DACN-HistoryBot/1.0 (contact: admin@dacn.local)"
                );

                var url =
                    "https://vi.wikipedia.org/w/api.php" +
                    "?action=query" +
                    $"&titles={Uri.EscapeDataString(title)}" +
                    "&prop=extracts" +
                    "&exintro=1" +
                    "&explaintext=1" +
                    "&format=json";

                var json = await http.GetStringAsync(url);

                using var doc = JsonDocument.Parse(json);

                var pages = doc.RootElement
                    .GetProperty("query")
                    .GetProperty("pages");

                foreach (var page in pages.EnumerateObject())
                {
                    // ❌ Trang không tồn tại
                    if (page.Value.TryGetProperty("missing", out _))
                        return "❌ Không tìm thấy trang triều đại trên Wikipedia.";

                    // ✅ Đọc extract an toàn
                    if (page.Value.TryGetProperty("extract", out var extract))
                    {
                        var text = extract.GetString();

                        if (!string.IsNullOrWhiteSpace(text))
                        {
                            // 🔥 Giới hạn độ dài cho đẹp
                            return text.Length > 1200
                                ? text.Substring(0, 1200) + "..."
                                : text;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Wikipedia error");
                return "❌ Lỗi khi kết nối Wikipedia.";
            }

            return "❌ Wikipedia không có nội dung giới thiệu cho triều đại này.";
        }
        private bool IsAskingForFlag(string q)
        {
            return Regex.IsMatch(q, @"(cờ|quốc kỳ|lá cờ|hình cờ)");
        }



    }
}

