namespace PAW_Proyecto_KronosAPI.Models;

public class CatalogResponseModel { public int id { get; set; } public string name { get; set; } = string.Empty; public string? description { get; set; } }
public class CatalogItemSaveRequestModel { public int? id { get; set; } public int catalog_id { get; set; } public string value { get; set; } = string.Empty; public string name { get; set; } = string.Empty; public int sort_order { get; set; } }
