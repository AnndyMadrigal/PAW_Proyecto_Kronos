namespace PAW_Proyecto_KronosAPI.Models
{
    public class InventoryCategoryResponseModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string? description { get; set; }
    }

    public class InventoryUnitResponseModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string? abbreviation { get; set; }
    }

    public class InventoryOperationResponseModel
    {
        public int id { get; set; }
        public bool success { get; set; }
        public string message { get; set; } = string.Empty;
    }
}
