using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using DACN.Data;
using DACN.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ======================================================
// 1️⃣ DATABASE
// ======================================================
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection")
    )
);

// ======================================================
// 2️⃣ CORE SERVICES
// ======================================================
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHttpClient();

// ======================================================
// 3️⃣ AI & KNOWLEDGE SERVICES (CHUẨN DI)
// ======================================================

// KB build 1 lần khi app start → dùng HostedService
builder.Services.AddSingleton<KnowledgeBaseService>();
builder.Services.AddHostedService<KnowledgeBaseInitializer>();

// AI xử lý theo request → Scoped
builder.Services.AddScoped<HistoryAiService>();
builder.Services.AddScoped<ImageQuestionService>();

// OpenAI Vision (dùng HttpClient)
builder.Services.AddHttpClient<OpenAiVisionService>();

// ======================================================
// 4️⃣ CORS (Flutter)
// ======================================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader()
    );
});

// ======================================================
// BUILD APP
// ======================================================
var app = builder.Build();

// ======================================================
// MIDDLEWARE
// ======================================================
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();
app.UseHttpsRedirection();

app.UseCors("AllowFlutter");
app.UseAuthorization();

app.MapControllers();

app.Run();
