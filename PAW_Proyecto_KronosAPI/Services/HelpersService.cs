using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using System.IdentityModel.Tokens.Jwt;

namespace PAW_Proyecto_KronosAPI.Services
{
    public class HelpersService(IConfiguration _config) : IHelpersService
    {

        public string GenerateToken(int id)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = System.Text.Encoding.ASCII.GetBytes(_config["Jwt:SecretKey"]!);
            var tokenDescriptor = new Microsoft.IdentityModel.Tokens.SecurityTokenDescriptor
            {
                Subject = new System.Security.Claims.ClaimsIdentity(new[]
                {
                    new System.Security.Claims.Claim("Consecutivo", id.ToString())
                }),
                Expires = DateTime.UtcNow.AddMinutes(30),
                SigningCredentials = new Microsoft.IdentityModel.Tokens.SigningCredentials(
                    new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(key),
                    Microsoft.IdentityModel.Tokens.SecurityAlgorithms.HmacSha256Signature)
            };
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        public string GenerateRandomPassword()
        {
            return Guid.NewGuid().ToString("N")[..10];
        }

        public async Task SendEmail(string to, string subject, string body)
        {
            var message = new MimeMessage();
            var emailSender = _config["Email:EmailAccount"]!;
            var applicationPassword = _config["Email:ApplicationPassword"]!;

            if (string.IsNullOrEmpty(applicationPassword))
                return;
            message.From.Add(new MailboxAddress("Kronos", emailSender));
            message.To.Add(MailboxAddress.Parse(to));
            message.Subject = subject;

            var builder = new BodyBuilder { HtmlBody = body };
            var logoPath = Path.Combine(AppContext.BaseDirectory, "Templates", "iconKronos.png");
            if (File.Exists(logoPath))
            {
                var logo = builder.LinkedResources.Add(logoPath);
                logo.ContentId = "logoKronos";
            }

            message.Body = builder.ToMessageBody();

            using var client = new SmtpClient();
            try
            {
                await client.ConnectAsync("smtp.gmail.com", 587, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(emailSender, applicationPassword);
                await client.SendAsync(message);
            }
            finally
            {
                client.Disconnect(true);
            }
        }
    }
}