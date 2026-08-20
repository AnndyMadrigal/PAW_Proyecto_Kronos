namespace PAW_Proyecto_KronosAPI.Models
{
    public class LocationOptionResponseModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string? description { get; set; }
        public string? address_line { get; set; }
    }
}
