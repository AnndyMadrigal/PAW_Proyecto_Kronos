using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_KronosAPI.Models
{
    public class ChangePasswordRequestModel
    {
        [Required]
        public int id { get; set; }

        [Required]
        public string password { get; set; } = string.Empty;
    }
}
