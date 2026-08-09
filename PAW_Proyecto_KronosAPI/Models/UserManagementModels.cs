using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_KronosAPI.Models
{
    public class UserManagementListItemResponseModel
    {
        public int id { get; set; }
        public string username { get; set; } = string.Empty;
        public string email { get; set; } = string.Empty;
        public string full_name { get; set; } = string.Empty;
        public string? phone { get; set; }
        public bool is_active { get; set; }
        public int? role_id { get; set; }
        public string? role_name { get; set; }
    }

    public class UserRoleOptionResponseModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
    }

    public class UserManagementUpdateRequestModel
    {
        [Required]
        public int user_id { get; set; }

        [Required]
        public int role_id { get; set; }

        public bool is_active { get; set; }
        public bool confirm_pending_appointments { get; set; }
    }

    public class UserManagementCreateRequestModel
    {
        [Required]
        public string username { get; set; } = string.Empty;
        [Required]
        [EmailAddress]
        public string email { get; set; } = string.Empty;
        [Required]
        public string full_name { get; set; } = string.Empty;
        public string? phone { get; set; }
        [Required]
        public int role_id { get; set; }
    }

    public class UserManagementCreateResponseModel
    {
        public bool success { get; set; }
        public string message { get; set; } = string.Empty;
        public string role_name { get; set; } = string.Empty;
    }

    public class UserManagementUpdateResponseModel
    {
        public bool success { get; set; }
        public bool requires_confirmation { get; set; }
        public string message { get; set; } = string.Empty;
        public int pending_appointment_count { get; set; }
        public bool role_changed { get; set; }
        public bool status_changed { get; set; }
        public string? email { get; set; }
        public string? full_name { get; set; }
        public string? role_name { get; set; }
        public bool is_active { get; set; }
    }

    public class TokenValidationResponseModel
    {
        public bool is_valid { get; set; }
    }
}
