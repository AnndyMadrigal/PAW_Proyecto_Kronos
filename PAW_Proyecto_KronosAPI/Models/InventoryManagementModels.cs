namespace PAW_Proyecto_KronosAPI.Models;

public class InventoryItemRequestModel
{
    public int? id { get; set; }
    public int inventory_category_id { get; set; }
    public int inventory_unit_id { get; set; }
    public string name { get; set; } = string.Empty;
    public string? description { get; set; }
    public decimal minimum_stock { get; set; }
    public bool requires_expiration_date { get; set; }
}

public class InventoryMovementRequestModel
{
    public int inventory_item_id { get; set; }
    public int location_id { get; set; }
    public int? inventory_batch_id { get; set; }
    public decimal quantity { get; set; }
    public string? batch_number { get; set; }
    public DateTime? expiration_date { get; set; }
    public decimal? unit_cost { get; set; }
    public string? notes { get; set; }
}

public class InventoryReferenceDataModel
{
    public List<CatalogItemResponseModel> categories { get; set; } = [];
    public List<CatalogItemResponseModel> units { get; set; } = [];
    public List<CatalogItemResponseModel> locations { get; set; } = [];
}

public class InventoryStockItemModel
{
    public int inventory_item_id { get; set; }
    public string name { get; set; } = string.Empty;
    public string category_name { get; set; } = string.Empty;
    public string unit_name { get; set; } = string.Empty;
    public decimal minimum_stock { get; set; }
    public decimal quantity_available { get; set; }
}

public class InventoryBatchAlertModel
{
    public int id { get; set; }
    public string inventory_item_name { get; set; } = string.Empty;
    public string location_name { get; set; } = string.Empty;
    public string? batch_number { get; set; }
    public DateTime expiration_date { get; set; }
    public decimal quantity_available { get; set; }
}
