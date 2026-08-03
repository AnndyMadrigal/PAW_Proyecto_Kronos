using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
using System.Data;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController(IConfiguration _config, IHelpersService _helpers) : ControllerBase
    {
        [HttpGet("ListarUsuariosAPI")]
        public async Task<IActionResult> ListarUsuariosAPI(string? search)
        {
            await using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var users = await context.QueryAsync<UserManagementListItemResponseModel>(
                "access_sp_users_search",
                new { search },
                commandType: CommandType.StoredProcedure);
            return Ok(users);
        }

        [HttpGet("RolesAPI")]
        public async Task<IActionResult> RolesAPI()
        {
            await using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var roles = await context.QueryAsync<UserRoleOptionResponseModel>(
                "access_sp_roles_list",
                commandType: CommandType.StoredProcedure);
            return Ok(roles);
        }

        [HttpGet("UsuarioAPI/{id:int}")]
        public async Task<IActionResult> UsuarioAPI(int id)
        {
            await using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var user = await context.QueryFirstOrDefaultAsync<UserManagementListItemResponseModel>(
                "access_sp_users_get_by_id",
                new { user_id = id },
                commandType: CommandType.StoredProcedure);
            return user is null ? NotFound("El usuario indicado no existe.") : Ok(user);
        }

        [HttpPost("CrearUsuarioAPI")]
        public async Task<IActionResult> CrearUsuarioAPI(UserManagementCreateRequestModel model)
        {
            var administratorUserId = _helpers.ObtenerConsecutivoToken();
            if (administratorUserId == 0)
                return Unauthorized("No se pudo identificar al administrador autenticado.");

            var temporaryPassword = _helpers.GenerateRandomPassword();
            var temporaryPasswordHash = BCrypt.Net.BCrypt.HashPassword(temporaryPassword);

            await using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var response = await context.QueryFirstOrDefaultAsync<UserManagementCreateResponseModel>(
                "access_sp_users_create_by_admin",
                new { administrator_user_id = administratorUserId, model.username, model.email, password = temporaryPasswordHash, model.full_name, model.phone, model.role_id },
                commandType: CommandType.StoredProcedure);

            if (response is null)
                return BadRequest("No se obtuvo respuesta al crear el usuario.");

            if (!response.success)
                return BadRequest(response.message);

            try
            {
                var route = Path.Combine(AppContext.BaseDirectory, "Templates", "UsuarioCreado.html");
                var html = await System.IO.File.ReadAllTextAsync(route);
                html = html.Replace("{{Nombre}}", model.full_name)
                           .Replace("{{Usuario}}", model.username)
                           .Replace("{{Perfil}}", response.role_name)
                           .Replace("{{ContrasenaTemporal}}", temporaryPassword)
                           .Replace("{{Year}}", DateTime.Now.Year.ToString());
                await _helpers.SendEmail(model.email, "Kronos - Tu cuenta ha sido creada", html);
            }
            catch (Exception ex)
            {
                Console.WriteLine("[UsersController] No se pudo enviar el correo de bienvenida: " + ex.Message);
            }

            return Ok(response);
        }

        [HttpPut("ActualizarPerfilAPI")]
        public async Task<IActionResult> ActualizarPerfilAPI(UserManagementUpdateRequestModel model)
        {
            var administratorUserId = _helpers.ObtenerConsecutivoToken();
            if (administratorUserId == 0)
                return Unauthorized("No se pudo identificar al administrador autenticado.");

            await using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            var response = await context.QueryFirstOrDefaultAsync<UserManagementUpdateResponseModel>(
                "access_sp_users_manage_profile",
                new
                {
                    administrator_user_id = administratorUserId,
                    model.user_id,
                    model.role_id,
                    model.is_active,
                    model.confirm_pending_appointments
                },
                commandType: CommandType.StoredProcedure);

            if (response is null)
                return BadRequest("No se obtuvo respuesta al actualizar el perfil.");

            if (!response.success)
                return response.requires_confirmation ? Conflict(response) : BadRequest(response.message);

            if ((response.role_changed || response.status_changed) && !string.IsNullOrWhiteSpace(response.email))
            {
                try
                {
                    var route = Path.Combine(AppContext.BaseDirectory, "Templates", "PerfilUsuarioActualizado.html");
                    var html = await System.IO.File.ReadAllTextAsync(route);
                    html = html.Replace("{{Nombre}}", response.full_name ?? "Usuario")
                               .Replace("{{Rol}}", response.role_name ?? "Sin perfil")
                               .Replace("{{Estado}}", response.is_active ? "Activo" : "Inactivo")
                               .Replace("{{Year}}", DateTime.Now.Year.ToString());
                    await _helpers.SendEmail(response.email, "Kronos - Tu perfil fue actualizado", html);
                }
                catch (Exception ex)
                {
                    Console.WriteLine("[UsersController] No se pudo enviar la notificacion: " + ex.Message);
                }
            }

            return Ok(response);
        }
    }
}
