using System.ComponentModel.DataAnnotations;

namespace PAW_Proyecto_KronosAPI.Models
{
    public class UserInfoUpdateRequestModel
    {
        [Required]
        public int id { get; set; }
        [Required]
        public string username { get; set; } = string.Empty;
        [Required]
        public string full_name { get; set; } = string.Empty;
        [Required]
        public string phone { get; set; } = string.Empty;
    }
}
