namespace PAW_Proyecto_KronosAPI.Models
{
    public class UserProfileUpdateRequestModel
    {
        public int id { get; set; }
        public string role_name { get; set; } = string.Empty;
        public bool is_active { get; set; }
        public bool allow_pending_appointments { get; set; }
    }
}
