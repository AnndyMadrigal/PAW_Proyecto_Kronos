using Microsoft.AspNetCore.Authentication.JwtBearer;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
using System.Security.Claims;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IHelpersService, HelpersService>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowWeb", policy => policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
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
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:SecretKey"]!))
        };
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userIdText = context.Principal?.FindFirst("Consecutivo")?.Value;
                var tokenId = context.Principal?.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Jti)?.Value;
                if (!int.TryParse(userIdText, out var userId) || string.IsNullOrWhiteSpace(tokenId))
                {
                    context.Fail("Token de sesión inválido.");
                    return;
                }

                await using var connection = new SqlConnection(builder.Configuration["ConnectionStrings:DefaultConnection"]);
                var validation = await connection.QueryFirstOrDefaultAsync<TokenValidationResponseModel>(
                    "access_sp_auth_validate_token", new { user_id = userId, token_id = tokenId },
                    commandType: System.Data.CommandType.StoredProcedure);
                if (validation?.is_valid != true)
                {
                    context.Fail("La sesión ya no está vigente.");
                    return;
                }

                var role = await connection.QueryFirstOrDefaultAsync<AuthRoleResponseModel>(
                    "access_sp_auth_get_user_role", new { user_id = userId },
                    commandType: System.Data.CommandType.StoredProcedure);
                if (string.IsNullOrWhiteSpace(role?.role_name))
                {
                    context.Fail("El usuario no tiene un perfil activo.");
                    return;
                }

                (context.Principal?.Identity as ClaimsIdentity)?.AddClaim(new System.Security.Claims.Claim(ClaimTypes.Role, role.role_name));
            }
        };
    });

var app = builder.Build();
app.UseExceptionHandler("/api/Error/RegistrarErrorAPI");
app.UseCors("AllowWeb");
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
