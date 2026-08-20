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
        public int role_id { get; set; }
        public string RoleName { get; set; } = string.Empty;
        public string Token { get; set; } = string.Empty;
    }

    public class AuthRoleResponseModel
    {
        public string role_name { get; set; } = string.Empty;
    }

    public class UserRegistrationResponseModel
    {
        public bool success { get; set; }
        public string message { get; set; } = string.Empty;
        public int user_id { get; set; }
        public string role_name { get; set; } = string.Empty;
    }
}
