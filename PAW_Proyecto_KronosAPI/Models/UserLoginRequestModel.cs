using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_KronosAPI.Models

{
    public class UserLoginRequestModel
    {
        [Required]
        public string email { get; set; } = string.Empty;
        [Required]
        public string password { get; set; } = string.Empty;

    }
}
