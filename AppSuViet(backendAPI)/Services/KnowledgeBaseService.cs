using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using DACN.Data;
using DACN.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace DACN.Services
{
    public class KnowledgeBaseService
    {
        private readonly IServiceProvider _services;
        private readonly ILogger<KnowledgeBaseService> _logger;

        // Danh sách tài liệu đã tổng hợp
        private readonly List<KbDocument> _docs = new();

        // Inverted index: term -> (docId -> tf)
        private readonly Dictionary<string, Dictionary<int, int>> _inverted = new();

        // Độ dài mỗi document
        private readonly Dictionary<int, int> _docLengths = new();

        // Giá trị IDF của mỗi term
        private readonly Dictionary<string, double> _idf = new();

        private bool _built = false;

        public KnowledgeBaseService(IServiceProvider services, ILogger<KnowledgeBaseService> logger)
        {
            _services = services;
            _logger = logger;
        }

        // =====================================================================
        // 📌 Trả số lượng documents có trong Knowledge Base
        // =====================================================================
        public int DocumentCount()
        {
            return _docs.Count;
        }

        // =====================================================================
        // 📌 Build lại Knowledge Base (chỉ chạy 1 lần)
        // =====================================================================
        public async Task BuildAsync(CancellationToken ct = default)
        {
            if (_built) return;

            _logger.LogInformation("KnowledgeBase: start building...");

            _docs.Clear();
            _inverted.Clear();
            _docLengths.Clear();
            _idf.Clear();

            int id = 1;

            try
            {
                using var scope = _services.CreateScope();
                var _db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                // ================================================================
                // HISTORICAL FIGURES
                // ================================================================
                if (_db.HistoricalFigures != null)
                {
                    var items = await _db.HistoricalFigures.AsNoTracking().ToListAsync(ct);

                    foreach (var f in items)
                    {
                        AddDocument(new KbDocument
                        {
                            Id = id++,
                            Title = f?.Name ?? "",
                            Text = $"{f?.Description} {f?.Detail}".Trim(),
                            Image = "",
                            Source = "historical_figure"
                        });
                    }
                }

                // ================================================================
                // TIMELINE EVENTS
                // ================================================================
                if (_db.TimelineEvents != null)
                {
                    var items = await _db.TimelineEvents.AsNoTracking().ToListAsync(ct);

                    foreach (var t in items)
                    {
                        AddDocument(new KbDocument
                        {
                            Id = id++,
                            Title = t?.EventTitle ?? "",
                            Text = $"{t?.Description} {t?.Details}".Trim(),
                            Image = t?.ImageUrl ?? "",
                            Source = "timeline_event"
                        });
                    }
                }

                // ================================================================
                // HISTORICAL DOCUMENTS
                // ================================================================
                if (_db.HistoricalDocuments != null)
                {
                    var items = await _db.HistoricalDocuments.AsNoTracking().ToListAsync(ct);

                    foreach (var d in items)
                    {
                        AddDocument(new KbDocument
                        {
                            Id = id++,
                            Title = d?.Title ?? "",
                            Text = $"{d?.Description} {d?.Content}".Trim(),
                            Image = d?.ImageUrl ?? "",
                            Source = "document"
                        });
                    }
                }

                // ================================================================
                // PROVINCES
                // ================================================================
                if (_db.Provinces != null)
                {
                    var items = await _db.Provinces.AsNoTracking().ToListAsync(ct);

                    foreach (var p in items)
                    {
                        AddDocument(new KbDocument
                        {
                            Id = id++,
                            Title = p?.Name ?? "",
                            Text = (p?.History ?? "").Trim(),
                            Image = p?.ImageUrl ?? "",
                            Source = "province"
                        });
                    }
                }

                // ================================================================
                // HOLIDAYS
                // ================================================================
                if (_db.Holidays != null)
                {
                    var items = await _db.Holidays.AsNoTracking().ToListAsync(ct);

                    foreach (var h in items)
                    {
                        AddDocument(new KbDocument
                        {
                            Id = id++,
                            Title = h?.Name ?? "",
                            Text = $"{h?.Description} {h?.Type} {h?.Tags}".Trim(),
                            Image = h?.ImageUrl ?? "",
                            Source = "holiday"
                        });
                    }
                }

                // ================================================================
                // MAP HISTORY
                // ================================================================
                if (_db.MapHistories != null)
                {
                    var items = await _db.MapHistories.AsNoTracking().ToListAsync(ct);

                    foreach (var m in items)
                    {
                        AddDocument(new KbDocument
                        {
                            Id = id++,
                            Title = m?.RedTitle ?? "",
                            Text = string.Join(" ", new[]
                            {
                                m?.Period,
                                m?.RedTitle,
                                m?.RedYear,
                                m?.Detail
                            }.Where(x => !string.IsNullOrWhiteSpace(x))),
                                                    Image = m?.ImagePath ?? "",
                                                    Source = "map"
                        });

                    }
                }

                // ================================================================
                // Build TF-IDF
                // ================================================================
                BuildInvertedIndex();

                _built = true;
                _logger.LogInformation("KnowledgeBase: built OK, {count} docs.", _docs.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error building KB");
            }
        }

        // =====================================================================
        // 👉 Thêm Document (đã có lọc chống null / text trống)
        // =====================================================================
        private void AddDocument(KbDocument doc)
        {
            if (doc == null) return;
            if (string.IsNullOrWhiteSpace(doc.Text)) return;

            _docs.Add(doc);
        }

        // =====================================================================
        // 👉 Build Inverted Index + IDF
        // =====================================================================
        private void BuildInvertedIndex()
        {
            foreach (var doc in _docs)
            {
                var tokens = Tokenize(doc.Text);

                foreach (var tk in tokens)
                {
                    if (!_inverted.ContainsKey(tk))
                        _inverted[tk] = new();

                    if (!_inverted[tk].ContainsKey(doc.Id))
                        _inverted[tk][doc.Id] = 0;

                    _inverted[tk][doc.Id]++;
                }

                _docLengths[doc.Id] = tokens.Count;
            }

            int N = _docs.Count;

            foreach (var term in _inverted.Keys)
            {
                int df = _inverted[term].Count;
                _idf[term] = Math.Log((double)(N + 1) / (df + 1)) + 1;
            }
        }

        // =====================================================================
        // 👉 Tokenizer hỗ trợ tiếng Việt chuẩn
        // =====================================================================
        private List<string> Tokenize(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return new List<string>();

            return Regex.Matches(
                    text.ToLower(),
                    @"[a-zA-Z0-9áàảãạăắằẳẵặâấầẩẫậđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ]+"
                )
                .Select(m => m.Value)
                .ToList();
        }

        // =====================================================================
        // 📌 SEARCH (trả về 1 document phù hợp nhất)
        // =====================================================================
        public async Task<string> SearchAsync(string query)
        {
            if (!_built)
                await BuildAsync();

            var tokens = Tokenize(query);
            var scores = new Dictionary<int, double>();

            foreach (var tk in tokens)
            {
                if (!_inverted.ContainsKey(tk)) continue;

                foreach (var pair in _inverted[tk])
                {
                    int docId = pair.Key;
                    int tf = pair.Value;

                    double tfidf = tf * _idf[tk];

                    if (!scores.ContainsKey(docId))
                        scores[docId] = 0;

                    scores[docId] += tfidf;
                }
            }

            if (!scores.Any())
                return "";

            int bestId = scores.OrderByDescending(x => x.Value).First().Key;
            var best = _docs.First(x => x.Id == bestId);

            return
                $"📌 **{best.Title}**\n\n" +
                $"{best.Text}\n\n" +
                (string.IsNullOrEmpty(best.Image) ? "" : $"📷 Ảnh: {best.Image}");
        }
    }

    // =====================================================================
    // MODEL
    // =====================================================================
    public class KbDocument
    {
        public int Id { get; set; }
        public string Title { get; set; } = "";
        public string Text { get; set; } = "";
        public string Image { get; set; } = "";
        public string Source { get; set; } = "";
    }
}
