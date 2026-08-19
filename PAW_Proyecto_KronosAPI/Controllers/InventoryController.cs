using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    // [INVENTARIO] Controlador para gestionar el inventario (RF-07)
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class InventoryController(IConfiguration _config) : Controller
    {
        #region Consultas

        [AllowAnonymous]
        [HttpGet("test")]
        public IActionResult Test()
        {
            return Ok(new { message = "API de inventario funcionando correctamente" });
        }

        // Listar o buscar productos del inventario
        [HttpGet("ListarInventarioAPI")]
        [HttpGet("GetInventoryItems")]
        public IActionResult ListarInventarioAPI([FromQuery] string? search = null, [FromQuery] int? category_id = null)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@search", search);
            parameters.Add("@category_id", category_id);

            var items = context.Query<InventoryItemResponseModel>("inventory_sp_items_search", parameters).ToList();
            return Ok(items);
        }

        // Obtener detalle de un producto por ID
        [HttpGet("ItemAPI/{id}")]
        public IActionResult ItemAPI(int id)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@id", id);

            var item = context.QueryFirstOrDefault<InventoryItemResponseModel>("inventory_sp_items_get_by_id", parameters);
            if (item == null)
                return NotFound(new { message = "El producto no existe o fue eliminado." });

            return Ok(item);
        }

        // Obtener catalogo de categorias de inventario
        [HttpGet("CategoriasAPI")]
        [HttpGet("GetCategories")]
        public IActionResult CategoriasAPI()
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var categories = context.Query<InventoryCategoryResponseModel>("inventory_sp_categories_list").ToList();
            return Ok(categories);
        }

        // Obtener catalogo de unidades de medida
        [HttpGet("UnidadesAPI")]
        [HttpGet("GetUnits")]
        public IActionResult UnidadesAPI()
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var units = context.Query<InventoryUnitResponseModel>("inventory_sp_units_list").ToList();
            return Ok(units);
        }

        #endregion

        #region Comandos

        // Crear un nuevo producto en el inventario
        [HttpPost("CrearItemAPI")]
        [HttpPost("CreateInventoryItem")]
        public IActionResult CrearItemAPI([FromBody] InventoryItemCreateRequestModel request)
        {
            if (request == null)
                return BadRequest(new { message = "Datos del producto requeridos." });

            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@name", request.name);
            parameters.Add("@description", request.description);
            parameters.Add("@minimum_stock", request.minimum_stock);
            parameters.Add("@inventory_category_id", request.inventory_category_id);
            parameters.Add("@inventory_unit_id", request.inventory_unit_id);

            var result = context.QueryFirstOrDefault<InventoryOperationResponseModel>("inventory_sp_items_create", parameters);
            return Ok(result);
        }

        // Actualizar un producto existente
        [HttpPut("ActualizarItemAPI/{id}")]
        [HttpPut("UpdateInventoryItem/{id}")]
        public IActionResult ActualizarItemAPI(int id, [FromBody] InventoryItemCreateRequestModel request)
        {
            if (request == null)
                return BadRequest(new { message = "Datos del producto requeridos." });

            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@id", id);
            parameters.Add("@name", request.name);
            parameters.Add("@description", request.description);
            parameters.Add("@minimum_stock", request.minimum_stock);
            parameters.Add("@inventory_category_id", request.inventory_category_id);
            parameters.Add("@inventory_unit_id", request.inventory_unit_id);

            var result = context.QueryFirstOrDefault<InventoryOperationResponseModel>("inventory_sp_items_update", parameters);
            return Ok(result);
        }

        // Eliminar un producto (borrado logico)
        [HttpDelete("EliminarItemAPI/{id}")]
        [HttpDelete("DeleteInventoryItem/{id}")]
        public IActionResult EliminarItemAPI(int id)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@id", id);

            var result = context.QueryFirstOrDefault<InventoryOperationResponseModel>("inventory_sp_items_delete", parameters);
            return Ok(result);
        }

        #endregion
    }
}
