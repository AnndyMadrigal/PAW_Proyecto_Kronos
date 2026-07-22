namespace PAW_Proyecto_Kronos.Models
{
    public class CitaDetailModel
    {
        public int id { get; set; }
        public int? patient_id { get; set; }
        public string? patient_first_name { get; set; }
        public string? patient_last_name { get; set; }
        public string? patient_email { get; set; }
        public string? patient_phone { get; set; }
        public int event_type_id { get; set; }
        public string event_type_name { get; set; } = string.Empty;
        public string event_type_value { get; set; } = string.Empty;
        public int status_id { get; set; }
        public string status_name { get; set; } = string.Empty;
        public string status_value { get; set; } = string.Empty;
        public DateTime scheduled_start_at { get; set; }
        public DateTime scheduled_end_at { get; set; }
        public DateTime? actual_start_at { get; set; }
        public DateTime? actual_end_at { get; set; }
        public int location_type_id { get; set; }
        public string location_type_name { get; set; } = string.Empty;
        public string location_type_value { get; set; } = string.Empty;
        public int? location_id { get; set; }
        public string? location_name { get; set; }
        public int? address_id { get; set; }
        public string? address_line { get; set; }
        public string? reference { get; set; }
        public string? location_description { get; set; }
        public int? main_staff_member_id { get; set; }
        public string? staff_first_name { get; set; }
        public string? staff_last_name { get; set; }
        public string? staff_email { get; set; }
        public string? staff_phone { get; set; }
        public string? summary { get; set; }
        public int created_by_user_id { get; set; }
        public DateTime created_at { get; set; }
        public DateTime? updated_at { get; set; }
    }

    public class CitaStatusHistoryModel
    {
        public int id { get; set; }
        public int service_event_id { get; set; }
        public int? old_status_id { get; set; }
        public string? old_status_name { get; set; }
        public int new_status_id { get; set; }
        public string new_status_name { get; set; } = string.Empty;
        public string? reason { get; set; }
        public int changed_by_user_id { get; set; }
        public string? changed_by_full_name { get; set; }
        public DateTime changed_at { get; set; }
    }

    public class CitaDetailFullModel
    {
        public CitaDetailModel? cita { get; set; }
        public List<CitaStatusHistoryModel> historial { get; set; } = new();
    }
}
