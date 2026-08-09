using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_Kronos.Models
{
    public class UserManagementListItemModel
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

    public class UserRoleOptionModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
    }

    public class UserManagementEditModel : UserManagementListItemModel
    {
        [Required(ErrorMessage = "Debes seleccionar un perfil.")]
        public new int? role_id { get; set; }
        public bool confirm_pending_appointments { get; set; }
        public bool requires_confirmation { get; set; }
        public int pending_appointment_count { get; set; }
        public List<UserRoleOptionModel> Roles { get; set; } = new();
    }

    public class UserManagementCreateModel
    {
        [Required(ErrorMessage = "Debes indicar el nombre de usuario.")]
        public string username { get; set; } = string.Empty;
        [Required(ErrorMessage = "Debes indicar el correo electronico.")]
        [EmailAddress(ErrorMessage = "El correo electronico no es valido.")]
        public string email { get; set; } = string.Empty;
        [Required(ErrorMessage = "Debes indicar el nombre completo.")]
        public string full_name { get; set; } = string.Empty;
        public string? phone { get; set; }
        [Required(ErrorMessage = "Debes seleccionar un perfil.")]
        public int? role_id { get; set; }
        public List<UserRoleOptionModel> Roles { get; set; } = new();
    }

    public class UserManagementUpdateResponseModel
    {
        public bool success { get; set; }
        public bool requires_confirmation { get; set; }
        public string message { get; set; } = string.Empty;
        public int pending_appointment_count { get; set; }
    }
}
