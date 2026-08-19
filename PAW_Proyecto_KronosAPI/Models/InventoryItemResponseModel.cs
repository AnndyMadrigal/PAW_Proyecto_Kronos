namespace PAW_Proyecto_KronosAPI.Models
{
    public class InventoryItemResponseModel
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
        public bool is_active { get; set; } = true;
        public DateTime? created_at { get; set; }
        public DateTime? updated_at { get; set; }
    }
}