using Dapper;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;
using PAW_Proyecto_KronosAPI.Services;
using System.IdentityModel.Tokens.Jwt;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
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
            ClockSkew = TimeSpan.Zero,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:SecretKey"]!))
        };

        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userIdClaim = context.Principal?.FindFirst("Consecutivo")?.Value;
                if (!int.TryParse(userIdClaim, out var userId))
                {
                    context.Fail("Token inválido.");
                    return;
                }

                var token = context.SecurityToken as JwtSecurityToken;
                var issuedAt = token?.IssuedAt;
                if (issuedAt == null)
                {
                    context.Fail("Token inválido.");
                    return;
                }

                await using var connection = new SqlConnection(builder.Configuration["ConnectionStrings:DefaultConnection"]!);
                var userData = await connection.QueryFirstOrDefaultAsync(
                    @"SELECT is_active, deleted, profile_stamp_at
                      FROM access_tbl_users
                      WHERE id = @id",
                    new { id = userId });

                if (userData == null || userData.deleted == true || userData.is_active == false)
                {
                    context.Fail("Usuario inactivo o no disponible.");
                    return;
                }

                if (userData.profile_stamp_at != null)
                {
                    var profileStamp = DateTime.SpecifyKind((DateTime)userData.profile_stamp_at, DateTimeKind.Utc);
                    if (issuedAt.Value < profileStamp)
                    {
                        context.Fail("La sesión fue invalidada por un cambio de perfil.");
                    }
                }
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
