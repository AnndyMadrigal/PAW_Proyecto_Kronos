using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;

namespace PAW_Proyecto_KronosAPI.Controllers;

[Authorize(Roles = "Administrador,Inventario")]
[Route("api/[controller]")]
[ApiController]
public class InventoryController(IConfiguration config, IHelpersService helpers) : ControllerBase
{
    private SqlConnection Connection() => new(config["ConnectionStrings:DefaultConnection"]);
    [HttpGet("GetInventoryItems")]
    [HttpGet("Items")]
    public IActionResult GetInventoryItems([FromQuery] string? search = null, [FromQuery] int? categoryId = null)
    {
        using var c = Connection();
        return Ok(c.Query<InventoryItemResponseModel>("inventory_sp_items_search", new { search, category_id = categoryId }, commandType: System.Data.CommandType.StoredProcedure));
    }
    [HttpGet("Items/{id:int}")]
    public IActionResult GetItem(int id)
    {
        using var c = Connection();
        var item = c.QueryFirstOrDefault<InventoryItemResponseModel>("inventory_sp_items_get_by_id", new { id }, commandType: System.Data.CommandType.StoredProcedure);
        return item is null ? NotFound("El producto indicado no existe.") : Ok(item);
    }
    [HttpGet("Stock")] public IActionResult Stock() => Ok(GetStock());
    [HttpGet("LowStock")] public IActionResult LowStock() { using var c=Connection(); return Ok(c.Query<InventoryStockItemModel>("inventory_sp_report_low_stock", commandType:System.Data.CommandType.StoredProcedure)); }
    [HttpGet("ExpiringBatches")] public IActionResult ExpiringBatches(int days=30) { using var c=Connection(); return Ok(c.Query<InventoryBatchAlertModel>("inventory_sp_report_expiring_batches", new { days }, commandType:System.Data.CommandType.StoredProcedure)); }
    [HttpGet("References")]
    public IActionResult References() { using var c=Connection(); using var m=c.QueryMultiple("inventory_sp_reference_data_get", commandType:System.Data.CommandType.StoredProcedure); return Ok(new InventoryReferenceDataModel { categories=m.Read<CatalogItemResponseModel>().ToList(), units=m.Read<CatalogItemResponseModel>().ToList(), locations=m.Read<CatalogItemResponseModel>().ToList() }); }
    [HttpPost("Items")]
    public IActionResult CreateItem(InventoryItemRequestModel model) { if(string.IsNullOrWhiteSpace(model.name)||model.minimum_stock<0) return BadRequest("Nombre y stock mínimo válidos son requeridos."); if (HasMoreThanTwoDecimals(model.minimum_stock)) return BadRequest("El stock mínimo admite como máximo dos decimales."); using var c=Connection(); return Ok(c.QueryFirst("inventory_sp_item_save", new { id = model.id is > 0 ? model.id : null, model.inventory_category_id, model.inventory_unit_id, model.name, model.description, model.minimum_stock, model.requires_expiration_date }, commandType:System.Data.CommandType.StoredProcedure)); }
    [HttpPut("Items/{id:int}")]
    public IActionResult UpdateItem(int id, InventoryItemRequestModel model) { model.id=id; return CreateItem(model); }
    [HttpDelete("Items/{id:int}")]
    public IActionResult DeleteItem(int id) { using var c=Connection(); return Ok(c.QueryFirst("inventory_sp_item_delete", new { id }, commandType:System.Data.CommandType.StoredProcedure)); }
    [HttpPost("Entries")] public IActionResult Entry(InventoryMovementRequestModel m) => RegisterMovement("entry",m);
    [HttpPost("Exits")] public IActionResult Exit(InventoryMovementRequestModel m) => RegisterMovement("exit",m);
    [HttpPost("Adjustments")] public IActionResult Adjustment(InventoryMovementRequestModel m) => RegisterMovement("adjustment",m);
    private IEnumerable<InventoryStockItemModel> GetStock() { using var c=Connection(); return c.Query<InventoryStockItemModel>("inventory_sp_report_stock", commandType:System.Data.CommandType.StoredProcedure); }
    private IActionResult RegisterMovement(string type, InventoryMovementRequestModel m) { if(m.quantity<=0) return BadRequest("La cantidad debe ser mayor que cero."); if (HasMoreThanTwoDecimals(m.quantity)) return BadRequest("La cantidad admite como máximo dos decimales."); using var c=Connection(); return Ok(c.QueryFirst("inventory_sp_movement_register", new { movement_type=type, m.inventory_item_id, m.location_id, m.inventory_batch_id, m.quantity, m.batch_number, m.expiration_date, m.unit_cost, m.notes, created_by_user_id=helpers.ObtenerConsecutivoToken() }, commandType:System.Data.CommandType.StoredProcedure)); }
    private static bool HasMoreThanTwoDecimals(decimal value) => decimal.Round(value, 2) != value;
}
