using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
namespace PAW_Proyecto_KronosAPI.Controllers;
[Authorize(Roles = "Administrador")]
[Route("api/[controller]")]
[ApiController]
public class CatalogsController(IConfiguration config, PAW_Proyecto_KronosAPI.Services.IHelpersService helpers) : ControllerBase
{
 private SqlConnection Connection()=>new(config["ConnectionStrings:DefaultConnection"]);
 [HttpGet] public IActionResult List(){using var c=Connection();return Ok(c.Query<CatalogResponseModel>("config_sp_catalogs_list",new{requested_by_user_id=helpers.ObtenerConsecutivoToken()},commandType:System.Data.CommandType.StoredProcedure));}
 [HttpGet("{id:int}/Items")] public IActionResult Items(int id){using var c=Connection();return Ok(c.Query<CatalogItemResponseModel>("config_sp_catalog_items_by_catalog",new{catalog_id=id,requested_by_user_id=helpers.ObtenerConsecutivoToken()},commandType:System.Data.CommandType.StoredProcedure));}
 [HttpPost("Items")] public IActionResult Save(CatalogItemSaveRequestModel m){if(m.catalog_id<=0||string.IsNullOrWhiteSpace(m.name)||string.IsNullOrWhiteSpace(m.value))return BadRequest("Catálogo, código y nombre son requeridos.");using var c=Connection();return Ok(c.QueryFirst("config_sp_catalog_item_save",new{m.id,m.catalog_id,m.value,m.name,m.sort_order,requested_by_user_id=helpers.ObtenerConsecutivoToken()},commandType:System.Data.CommandType.StoredProcedure));}
 [HttpDelete("Items/{id:int}")] public IActionResult Delete(int id){using var c=Connection();return Ok(c.QueryFirst("config_sp_catalog_item_delete",new{id,requested_by_user_id=helpers.ObtenerConsecutivoToken()},commandType:System.Data.CommandType.StoredProcedure));}
}
