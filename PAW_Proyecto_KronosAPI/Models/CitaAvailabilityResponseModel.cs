namespace PAW_Proyecto_KronosAPI.Models
{
    public class CitaAvailabilityResponseModel
    {
        public bool is_available { get; set; }
        public List<CitaSuggestedSlotModel> suggested_slots { get; set; } = new();
    }

    public class CitaSuggestedSlotModel
    {
        public DateTime candidate_start { get; set; }
        public DateTime candidate_end { get; set; }
    }
}
