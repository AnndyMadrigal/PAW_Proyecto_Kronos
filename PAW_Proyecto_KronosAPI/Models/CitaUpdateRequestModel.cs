namespace PAW_Proyecto_KronosAPI.Models
{
    public class CitaUpdateRequestModel
    {
        public int service_event_id { get; set; }
        public int? patient_id { get; set; }
        public int event_type_id { get; set; }
        public DateTime scheduled_start_at { get; set; }
        public DateTime scheduled_end_at { get; set; }
        public int location_type_id { get; set; }
        public int? location_id { get; set; }
        public int? address_id { get; set; }
        public string? location_description { get; set; }
        public int? main_staff_member_id { get; set; }
        public string? summary { get; set; }
        public string? reason { get; set; }
        public int changed_by_user_id { get; set; }
        public List<CitaStaffItemModel>? staff { get; set; }
        public List<int>? service_ids { get; set; }
    }

    public class CitaRescheduleRequestModel
    {
        public int service_event_id { get; set; }
        public DateTime scheduled_start_at { get; set; }
        public DateTime scheduled_end_at { get; set; }
        public string? reason { get; set; }
        public int changed_by_user_id { get; set; }
    }

    public class CitaCancelRequestModel
    {
        public int service_event_id { get; set; }
        public string reason { get; set; } = string.Empty;
        public int changed_by_user_id { get; set; }
    }
}