namespace PAW_Proyecto_KronosAPI.Models
{
    public class ErrorLogRequestModel
    {
        public int? user_id { get; set; }
        public string? source { get; set; }
        public string message { get; set; } = string.Empty;
        public string? detail { get; set; }
    }
}
