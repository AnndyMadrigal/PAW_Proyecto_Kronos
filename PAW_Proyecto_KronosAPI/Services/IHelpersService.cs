namespace PAW_Proyecto_KronosAPI.Services
{
    public interface IHelpersService
    {
        string GenerateToken(int id, string tokenId);

        int ObtenerConsecutivoToken();

        Task SendEmail(string to, string subject, string body);

        string GenerateRandomPassword();
    }
}
