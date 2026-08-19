using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    // [INVENTARIO] Controlador para gestionar el inventario
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

                    // Trae los productos que no estén marcados como eliminados
                    var query = @"
                        SELECT id, name, description, minimum_stock,
                               inventory_category_id, inventory_unit_id
                        FROM inventory_tbl_items
                        WHERE deleted = 0
                        ORDER BY name";

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

        // [INVENTARIO] Obtener las categorías disponibles (para el selector)
        [Authorize]
        [HttpGet("GetCategories")]
        public IActionResult GetCategories()
        {
            try
            {
                var connectionString = _config["ConnectionStrings:DefaultConnection"];
                using (var context = new SqlConnection(connectionString))
                {
                    context.Open();
                    var query = @"
                        SELECT id, name
                        FROM inventory_tbl_categories
                        WHERE deleted = 0
                        ORDER BY name";
                    var categories = context.Query(query).ToList();
                    return Ok(categories);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener categorías", error = ex.Message });
            }
        }

        // [INVENTARIO] Obtener las unidades disponibles (para el selector)
        [Authorize]
        [HttpGet("GetUnits")]
        public IActionResult GetUnits()
        {
            try
            {
                var connectionString = _config["ConnectionStrings:DefaultConnection"];
                using (var context = new SqlConnection(connectionString))
                {
                    context.Open();
                    var query = @"
                        SELECT id, name, abbreviation
                        FROM inventory_tbl_units
                        WHERE deleted = 0
                        ORDER BY name";
                    var units = context.Query(query).ToList();
                    return Ok(units);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al obtener unidades", error = ex.Message });
            }
        }

        // [INVENTARIO] Crear un nuevo item en el inventario
        [Authorize]
        [HttpPost("CreateInventoryItem")]
        public IActionResult CreateInventoryItem([FromBody] InventoryItemCreateRequestModel request)
        {
            try
            {
                // Validar campos requeridos
                if (string.IsNullOrWhiteSpace(request.name))
                    return BadRequest(new { message = "El nombre del producto es requerido" });

                if (request.minimum_stock < 0)
                    return BadRequest(new { message = "El stock mínimo no puede ser negativo" });

                if (request.inventory_category_id <= 0)
                    return BadRequest(new { message = "Debe seleccionar una categoría" });

                if (request.inventory_unit_id <= 0)
                    return BadRequest(new { message = "Debe seleccionar una unidad" });

                var connectionString = _config["ConnectionStrings:DefaultConnection"];
                using (var context = new SqlConnection(connectionString))
                {
                    context.Open();

                    // Insertar el nuevo item. Las columnas is_active, deleted y created_at
                    // usan sus valores por defecto definidos en la tabla.
                    var insertQuery = @"
                        INSERT INTO inventory_tbl_items
                            (inventory_category_id, inventory_unit_id, name, description, minimum_stock)
                        VALUES
                            (@CategoryId, @UnitId, @Name, @Description, @MinimumStock);
                        SELECT SCOPE_IDENTITY() as id;";

                    var parameters = new
                    {
                        CategoryId = request.inventory_category_id,
                        UnitId = request.inventory_unit_id,
                        Name = request.name.Trim(),
                        Description = string.IsNullOrWhiteSpace(request.description) ? null : request.description.Trim(),
                        MinimumStock = request.minimum_stock
                    };

                    var newId = context.ExecuteScalar<int>(insertQuery, parameters);

                    return Ok(new
                    {
                        message = "Producto creado exitosamente",
                        id = newId,
                        name = request.name,
                        description = request.description,
                        minimum_stock = request.minimum_stock
                    });
                }
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new { message = "Error en la base de datos", error = sqlEx.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al crear producto", error = ex.Message });
            }
        }

        // [INVENTARIO] Actualizar un item del inventario
        [Authorize]
        [HttpPut("UpdateInventoryItem/{id}")]
        public IActionResult UpdateInventoryItem(int id, [FromBody] InventoryItemCreateRequestModel request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.name))
                    return BadRequest(new { message = "El nombre del producto es requerido" });

                if (request.minimum_stock < 0)
                    return BadRequest(new { message = "El stock mínimo no puede ser negativo" });

                if (request.inventory_category_id <= 0)
                    return BadRequest(new { message = "Debe seleccionar una categoría" });

                if (request.inventory_unit_id <= 0)
                    return BadRequest(new { message = "Debe seleccionar una unidad" });

                var connectionString = _config["ConnectionStrings:DefaultConnection"];
                using (var context = new SqlConnection(connectionString))
                {
                    context.Open();

                    // Verificar si el producto existe
                    var checkProductQuery = "SELECT id FROM inventory_tbl_items WHERE id = @Id AND deleted = 0";
                    var productExists = context.QueryFirstOrDefault<int?>(checkProductQuery, new { Id = id });

                    if (productExists == null)
                        return NotFound(new { message = "El producto no existe" });

                    // Actualizar el producto (también actualiza updated_at)
                    var updateQuery = @"
                        UPDATE inventory_tbl_items
                        SET inventory_category_id = @CategoryId,
                            inventory_unit_id = @UnitId,
                            name = @Name,
                            description = @Description,
                            minimum_stock = @MinimumStock,
                            updated_at = SYSDATETIME()
                        WHERE id = @Id";

                    var parameters = new
                    {
                        Id = id,
                        CategoryId = request.inventory_category_id,
                        UnitId = request.inventory_unit_id,
                        Name = request.name.Trim(),
                        Description = string.IsNullOrWhiteSpace(request.description) ? null : request.description.Trim(),
                        MinimumStock = request.minimum_stock
                    };

                    context.Execute(updateQuery, parameters);

                    return Ok(new
                    {
                        message = "Producto actualizado exitosamente",
                        id = id,
                        name = request.name,
                        description = request.description,
                        minimum_stock = request.minimum_stock
                    });
                }
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new { message = "Error en la base de datos", error = sqlEx.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al actualizar producto", error = ex.Message });
            }
        }

        // [INVENTARIO] Eliminar un item del inventario (borrado lógico)
        [Authorize]
        [HttpDelete("DeleteInventoryItem/{id}")]
        public IActionResult DeleteInventoryItem(int id)
        {
            try
            {
                var connectionString = _config["ConnectionStrings:DefaultConnection"];
                using (var context = new SqlConnection(connectionString))
                {
                    context.Open();

                    var checkProductQuery = "SELECT id FROM inventory_tbl_items WHERE id = @Id AND deleted = 0";
                    var productExists = context.QueryFirstOrDefault<int?>(checkProductQuery, new { Id = id });

                    if (productExists == null)
                        return NotFound(new { message = "El producto no existe" });

                    // Borrado lógico: marca deleted = 1 en lugar de borrar la fila.
                    // Esto respeta las llaves foráneas (movimientos, lotes, etc.).
                    var deleteQuery = @"
                        UPDATE inventory_tbl_items
                        SET deleted = 1, updated_at = SYSDATETIME()
                        WHERE id = @Id";
                    context.Execute(deleteQuery, new { Id = id });

                    return Ok(new
                    {
                        message = "Producto eliminado exitosamente",
                        id = id
                    });
                }
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new { message = "Error en la base de datos", error = sqlEx.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error al eliminar producto", error = ex.Message });
            }
        }
    }
}
