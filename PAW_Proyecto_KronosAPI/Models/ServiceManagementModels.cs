namespace PAW_Proyecto_KronosAPI.Models;

public class ServiceDefinitionRequestModel
{
    public int? id { get; set; }
    public string name { get; set; } = string.Empty;
    public string? description { get; set; }
    public bool is_billable { get; set; }
    public decimal? default_price { get; set; }
}

public class ServiceDefinitionResponseModel
{
    public int id { get; set; }
    public string name { get; set; } = string.Empty;
    public string? description { get; set; }
    public bool is_billable { get; set; }
    public decimal? default_price { get; set; }
    public bool is_active { get; set; }
}

public class ServiceEventNoteRequestModel
{
    public int service_event_id { get; set; }
    public int? staff_member_id { get; set; }
    public int note_type_id { get; set; }
    public string note_text { get; set; } = string.Empty;
}

public class ServiceEventCompleteRequestModel
{
    public int service_event_id { get; set; }
    public int? completed_by_staff_member_id { get; set; }
    public string? completion_summary { get; set; }
    public DateTime? actual_start_at { get; set; }
    public DateTime? actual_end_at { get; set; }
}

public class ServiceEventNoteResponseModel
{
    public int id { get; set; }
    public int service_event_id { get; set; }
    public string? staff_name { get; set; }
    public string note_type_name { get; set; } = string.Empty;
    public string note_text { get; set; } = string.Empty;
    public DateTime created_at { get; set; }
}

public class ServiceReferenceOptionModel
{
    public int id { get; set; }
    public string name { get; set; } = string.Empty;
}

public class ServiceCompletionReferenceDataModel
{
    public List<ServiceReferenceOptionModel> events { get; set; } = [];
    public List<ServiceReferenceOptionModel> staff_members { get; set; } = [];
}
