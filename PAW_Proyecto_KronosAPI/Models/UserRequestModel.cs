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
        [Required]
        public string phone { get; set; } = string.Empty;

    }
}
