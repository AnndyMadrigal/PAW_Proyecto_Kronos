namespace PAW_Proyecto_KronosAPI.Models
{
    
    public class CitaResponseModel
    {
        public int id { get; set; }
        public int? patient_id { get; set; }
        public string? patient_first_name { get; set; }
        public string? patient_last_name { get; set; }
        public int event_type_id { get; set; }
        public string event_type_name { get; set; } = string.Empty;
        public int status_id { get; set; }
        public string status_name { get; set; } = string.Empty;
        public DateTime scheduled_start_at { get; set; }
        public DateTime scheduled_end_at { get; set; }
        public int? main_staff_member_id { get; set; }
        public string? staff_first_name { get; set; }
        public string? staff_last_name { get; set; }
    }

    
    public class CitaOperationResponseModel
    {
        public bool success { get; set; }
        public int service_event_id { get; set; }
    }
}
