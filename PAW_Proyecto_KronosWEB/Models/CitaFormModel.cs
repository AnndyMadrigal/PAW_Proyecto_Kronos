namespace PAW_Proyecto_Kronos.Models
{
    
    public class CitaFormModel
    {
        public int service_event_id { get; set; }
        public int? patient_id { get; set; }
        public int event_type_id { get; set; }
        public DateTime? scheduled_start_at { get; set; }
        public DateTime? scheduled_end_at { get; set; }
        public int location_type_id { get; set; }
        public int? location_id { get; set; }
        public int? address_id { get; set; }
        public string? location_description { get; set; }
        public int? main_staff_member_id { get; set; }
        public string? summary { get; set; }
        public string? reason { get; set; }

        
        public List<PatientOptionModel> Pacientes { get; set; } = new();
        public List<StaffOptionModel> Colaboradores { get; set; } = new();
        public List<CatalogOptionModel> TiposCita { get; set; } = new();
        public List<CatalogOptionModel> TiposUbicacion { get; set; } = new();

        
        public List<CitaSuggestedSlotModel> HorariosSugeridos { get; set; } = new();
    }

    public class PatientOptionModel
    {
        public int id { get; set; }
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? identification_number { get; set; }
        public string? email { get; set; }
        public string? phone { get; set; }
    }

    public class StaffOptionModel
    {
        public int id { get; set; }
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public int staff_role_id { get; set; }
        public string staff_role_name { get; set; } = string.Empty;
        public string? email { get; set; }
        public string? phone { get; set; }
    }

    public class CatalogOptionModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string value { get; set; } = string.Empty;
        public int sort_order { get; set; }
    }

    public class CitaSuggestedSlotModel
    {
        public DateTime candidate_start { get; set; }
        public DateTime candidate_end { get; set; }
    }
}
