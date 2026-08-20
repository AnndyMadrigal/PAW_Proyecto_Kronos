namespace PAW_Proyecto_Kronos.Models;

public class InventoryItemViewModel
{
    public int id { get; set; }
    public string name { get; set; } = string.Empty;
    public string? description { get; set; }
    public decimal minimum_stock { get; set; }
    public int inventory_category_id { get; set; }
    public string? category_name { get; set; }
    public int inventory_unit_id { get; set; }
    public string? unit_name { get; set; }
    public string? unit_abbreviation { get; set; }
    public bool requires_expiration_date { get; set; }
}

public class InventoryReferenceViewModel { public int id { get; set; } public string name { get; set; } = string.Empty; }
public class InventoryReferencesViewModel { public List<InventoryReferenceViewModel> categories { get; set; } = []; public List<InventoryReferenceViewModel> units { get; set; } = []; }

public class InventoryStockViewModel
{
    public int inventory_item_id { get; set; }
    public string name { get; set; } = string.Empty;
    public string category_name { get; set; } = string.Empty;
    public string unit_name { get; set; } = string.Empty;
    public decimal minimum_stock { get; set; }
    public decimal quantity_available { get; set; }
}
