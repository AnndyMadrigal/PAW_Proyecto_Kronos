using Microsoft.AspNetCore.Authentication.JwtBearer;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IHelpersService, HelpersService>();

// [INVENTARIO] Configurar CORS para permitir llamadas desde el cliente web
// Nota: Para revertir, eliminar todo este bloque AddCors()
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowWeb", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:SecretKey"]!))
        };
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userIdText = context.Principal?.FindFirst("Consecutivo")?.Value;
                var tokenId = context.Principal?.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Jti)?.Value;
                if (!int.TryParse(userIdText, out var userId) || string.IsNullOrWhiteSpace(tokenId))
                {
                    context.Fail("Token de sesiÃ³n invÃ¡lido.");
                    return;
                }

                await using var connection = new SqlConnection(builder.Configuration["ConnectionStrings:DefaultConnection"]);
                var validation = await connection.QueryFirstOrDefaultAsync<TokenValidationResponseModel>(
                    "access_sp_auth_validate_token",
                    new { user_id = userId, token_id = tokenId },
                    commandType: System.Data.CommandType.StoredProcedure);
                if (validation?.is_valid != true)
                    context.Fail("La sesiÃ³n ya no estÃ¡ vigente.");
            }
        };
    });

var app = builder.Build();


// [INVENTARIO] CORS debe ejecutarse antes que HTTPS redirect
app.UseCors("AllowWeb");

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
