using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_KronosAPI.Models

{
    public class UserRequestModel
    {
        [Required]
        public string username { get; set; } = string.Empty;
        [Required]
        public string email { get; set; } = string.Empty;
        [Required]
        public string password { get; set; } = string.Empty;
        [Required]
        public string full_name { get; set; } = string.Empty;
        
        public string phone { get; set; } = string.Empty;
        [Required]
        public int failed_login_attempts { get; set; }
        
        public DateTime lockout_until { get; set; }
        
        public DateTime last_login_at { get; set; }
        [Required]
        public bool is_active { get; set; }
        [Required]
        public bool deleted { get; set; }
        [Required]
        public DateTime created_at { get; set; }
        
        public DateTime updated_at { get; set; }

    }
}
