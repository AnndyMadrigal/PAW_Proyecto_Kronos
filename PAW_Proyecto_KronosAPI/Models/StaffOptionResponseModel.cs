namespace PAW_Proyecto_KronosAPI.Models
{
    public class StaffOptionResponseModel
    {
        public int id { get; set; }
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public int staff_role_id { get; set; }
        public string staff_role_name { get; set; } = string.Empty;
        public string? email { get; set; }
        public string? phone { get; set; }
    }
}