namespace DACN.Services
{
    public class KnowledgeBaseInitializer : IHostedService
    {
        private readonly KnowledgeBaseService _kb;
        private readonly ILogger<KnowledgeBaseInitializer> _logger;

        public KnowledgeBaseInitializer(KnowledgeBaseService kb, ILogger<KnowledgeBaseInitializer> logger)
        {
            _kb = kb;
            _logger = logger;
        }

        public async Task StartAsync(CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("Building KnowledgeBase...");
                await _kb.BuildAsync(cancellationToken);
                _logger.LogInformation(
                    "KnowledgeBase built. Docs: {count}",
                    _kb.DocumentCount()
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ KnowledgeBase build FAILED");
                // 🔥 KHÔNG throw → app vẫn chạy, Swagger vẫn lên
            }
        }


        public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    }

}
