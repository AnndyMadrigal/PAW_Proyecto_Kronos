namespace PAW_Proyecto_KronosAPI.Models
{
    public class CitaCreateRequestModel
    {
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
        public int created_by_user_id { get; set; }
        public List<CitaStaffItemModel>? staff { get; set; }
        public List<int>? service_ids { get; set; }
    }

    public class CitaStaffItemModel
    {
        public int staff_member_id { get; set; }
        public int? role_in_event_id { get; set; }
    }
}
