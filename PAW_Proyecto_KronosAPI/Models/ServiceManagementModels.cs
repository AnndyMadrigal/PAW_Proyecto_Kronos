namespace PAW_Proyecto_KronosAPI.Models;

public class ServiceDefinitionRequestModel
{
    public int? id { get; set; }
    public string name { get; set; } = string.Empty;
    public string? description { get; set; }
    public bool is_billable { get; set; }
    public decimal? default_price { get; set; }
    public string? linked_module_url { get; set; }
}

public class ServiceDefinitionResponseModel
{
    public int id { get; set; }
    public string name { get; set; } = string.Empty;
    public string? description { get; set; }
    public bool is_billable { get; set; }
    public decimal? default_price { get; set; }
    public bool is_active { get; set; }
    public string? linked_module_url { get; set; }
}

public class ServiceEventInventoryUsageRequestModel
{
    public int inventory_item_id { get; set; }
    public int location_id { get; set; }
    public decimal quantity_used { get; set; }
    public string? notes { get; set; }
}

public class EquipmentLoanRequestModel
{
    public int patient_id { get; set; }
    public int inventory_item_id { get; set; }
    public int location_id { get; set; }
    public string loan_type { get; set; } = "loan";
    public DateTime loaned_at { get; set; }
    public DateTime? expected_return_at { get; set; }
    public decimal? amount { get; set; }
    public string? notes { get; set; }
}

public class EquipmentLoanResponseModel
{
    public int id { get; set; }
    public string patient_name { get; set; } = string.Empty;
    public string equipment_name { get; set; } = string.Empty;
    public string location_name { get; set; } = string.Empty;
    public string loan_type { get; set; } = string.Empty;
    public DateTime loaned_at { get; set; }
    public DateTime? expected_return_at { get; set; }
    public DateTime? returned_at { get; set; }
    public decimal? amount { get; set; }
    public string status { get; set; } = string.Empty;
    public string? notes { get; set; }
}

public class EquipmentLoanReferenceDataModel
{
    public List<ServiceReferenceOptionModel> patients { get; set; } = [];
    public List<ServiceReferenceOptionModel> equipment { get; set; } = [];
    public List<ServiceReferenceOptionModel> locations { get; set; } = [];
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
