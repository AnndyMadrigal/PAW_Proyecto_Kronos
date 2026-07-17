namespace PAW_Proyecto_Kronos.Models
{
    public class UserResponseModel
    {
        public int id { get; set; }
        public string username { get; set; } = string.Empty;
        public string email { get; set; } = string.Empty;
        public string password { get; set; } = string.Empty;
        public string full_name { get; set; } = string.Empty;
        public string phone { get; set; } = string.Empty;

        public bool is_active { get; set; }
    }
}