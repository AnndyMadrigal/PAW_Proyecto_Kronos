using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_KronosAPI.Models
{
    public class UserEmailRequestModel
    {
        [Required]
        public string email { get; set; } = string.Empty;

    }
}
