namespace PAW_Proyecto_KronosAPI.Models
{
    public class CatalogItemResponseModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string value { get; set; } = string.Empty;
        public int sort_order { get; set; }
    }

    public class PatientSearchResponseModel
    {
        public int id { get; set; }
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? identification_number { get; set; }
        public string? email { get; set; }
        public string? phone { get; set; }
    }

    public class StaffSearchResponseModel
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
