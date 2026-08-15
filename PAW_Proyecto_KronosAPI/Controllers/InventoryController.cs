using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    // [INVENTARIO] Controlador para gestionar el inventario
    // Cambios realizados:
    // - Agregado endpoint GET /api/inventory/GetInventoryItems
    // - Verifica si la tabla existe, sino devuelve datos de ejemplo
    // - Requiere autenticación JWT
    [Route("api/[controller]")]
    [ApiController]
    public class InventoryController(IConfiguration _config) : Controller
    {
        // Endpoint de prueba para verificar que la API responde
        [HttpGet("test")]
        public IActionResult Test()
        {
            return Ok(new { message = "API está funcionando" });
        }

        // [INVENTARIO] Obtener todos los items del inventario
        // Nota: Para revertir, eliminar todo este controlador
        [Authorize]
        [HttpGet("GetInventoryItems")]
        public IActionResult GetInventoryItems()
        {
            try
            {
                var connectionString = _config["ConnectionStrings:DefaultConnection"];
                using (var context = new SqlConnection(connectionString))
                {
                    context.Open();

                    // Verifica si la tabla existe antes de consultarla
                    var checkTableQuery = @"
                        SELECT TABLE_NAME 
                        FROM INFORMATION_SCHEMA.TABLES 
                        WHERE TABLE_NAME = 'inventory_tbl_items'";

                    var tableExists = context.QueryFirstOrDefault<string>(checkTableQuery);

                    if (tableExists == null)
                    {
                        // Si la tabla no existe, devuelve datos de prueba
                        var exampleItems = new List<InventoryItemResponseModel>
                        {
                            new() { id = 1, name = "Producto A", description = "Descripción del Producto A", minimum_stock = 10 },
                            new() { id = 2, name = "Producto B", description = "Descripción del Producto B", minimum_stock = 20 },
                            new() { id = 3, name = "Producto C", description = "Descripción del Producto C", minimum_stock = 15 }
                        };
                        return Ok(exampleItems);
                    }

                    // Consulta la tabla de inventario
                    var query = "SELECT id, name, description, minimum_stock FROM inventory_tbl_items ORDER BY name";
                    var items = context.Query<InventoryItemResponseModel>(query).ToList();

                    return Ok(items);
                }
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new { message = "Error en la base de datos", error = sqlEx.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener inventario", error = ex.Message });
            }
        }
    }
}
