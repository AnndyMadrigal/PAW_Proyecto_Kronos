namespace PAW_Proyecto_KronosAPI.Models
{
    public class InventoryItemResponseModel
    {
        public int id { get; set; }
        public string name { get; set; }
        public string description { get; set; }
        public int minimum_stock { get; set; }
    }
}
