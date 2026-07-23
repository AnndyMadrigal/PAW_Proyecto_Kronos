namespace PAW_Proyecto_Kronos.Models
{
    public class UserModel
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
        public string confirmPassword { get; set; } = string.Empty;
        public string role_name { get; set; } = string.Empty;
        public int pending_appointments_count { get; set; }
        public bool has_pending_appointments { get; set; }
        public bool is_unique_admin { get; set; }
        public bool allow_pending_appointments { get; set; }
        public string warning_message { get; set; } = string.Empty;
        public DateTime? profile_stamp_at { get; set; }
    }
}
