namespace PAW_Proyecto_KronosAPI.Models;

public class StaffMemberRequestModel
{
    public int? id { get; set; }
    public int staff_role_id { get; set; }
    public string first_name { get; set; } = string.Empty;
    public string last_name { get; set; } = string.Empty;
    public string? identification_number { get; set; }
    public string? phone { get; set; }
    public string? email { get; set; }
    public List<int> specialty_ids { get; set; } = [];
}

public class StaffAvailabilityRequestModel
{
    public int staff_member_id { get; set; }
    public DateTime available_date { get; set; }
    public TimeSpan start_time { get; set; }
    public TimeSpan end_time { get; set; }
    public bool is_available { get; set; } = true;
}

public class StaffReferenceDataModel
{
    public List<CatalogItemResponseModel> roles { get; set; } = [];
    public List<CatalogItemResponseModel> specialties { get; set; } = [];
}

public class StaffAvailabilityResponseModel
{
    public int id { get; set; }
    public int staff_member_id { get; set; }
    public DateTime available_date { get; set; }
    public TimeSpan start_time { get; set; }
    public TimeSpan end_time { get; set; }
    public bool is_available { get; set; }
}
