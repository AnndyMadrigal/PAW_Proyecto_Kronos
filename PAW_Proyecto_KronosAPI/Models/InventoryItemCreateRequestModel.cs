namespace PAW_Proyecto_KronosAPI.Models
{
    public class InventoryItemCreateRequestModel
    {
        public string name { get; set; }
        public string description { get; set; }
        public decimal minimum_stock { get; set; }
        public int inventory_category_id { get; set; }
        public int inventory_unit_id { get; set; }
    }
}