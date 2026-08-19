namespace PAW_Proyecto_Kronos.Models
{
    public class InventoryModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string description { get; set; } = string.Empty;
        public decimal minimum_stock { get; set; }
        public int inventory_category_id { get; set; }
        public string category_name { get; set; } = string.Empty;
        public int inventory_unit_id { get; set; }
        public string unit_name { get; set; } = string.Empty;
        public string unit_abbreviation { get; set; } = string.Empty;
        public bool is_active { get; set; } = true;
        public DateTime? created_at { get; set; }
        public DateTime? updated_at { get; set; }

        public List<CategoryModel> Categories { get; set; } = new();
        public List<UnitModel> Units { get; set; } = new();
    }

    public class CategoryModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string description { get; set; } = string.Empty;
    }

    public class UnitModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string abbreviation { get; set; } = string.Empty;

        public string DisplayName => string.IsNullOrWhiteSpace(abbreviation) ? name : $"{name} ({abbreviation})";
    }
}
