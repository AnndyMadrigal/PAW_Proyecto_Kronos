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
    public class UsersController(IConfiguration _config, IHelpersService _helpers) : Controller
    {
        private SqlConnection CrearConexion()
        {
            return new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
        }

        private int? UsuarioActualId()
        {
            var claim = User.FindFirst("Consecutivo")?.Value;
            return int.TryParse(claim, out var id) ? id : null;
        }

        private bool EsAdministradorActual()
        {
            var currentUserId = UsuarioActualId();
            if (currentUserId == null)
            {
                return false;
            }

            using var context = CrearConexion();
            var roleName = context.QueryFirstOrDefault<string>(
                @"SELECT TOP (1) r.name
                  FROM access_tbl_user_roles ur
                  INNER JOIN access_tbl_roles r ON r.id = ur.role_id
                  WHERE ur.user_id = @id
                    AND r.deleted = 0
                    AND r.is_active = 1
                  ORDER BY ur.created_at DESC, r.id DESC",
                new { id = currentUserId },
                commandType: CommandType.Text);

            return string.Equals(roleName, "Administrador", StringComparison.OrdinalIgnoreCase);
        }

        [HttpGet("SearchAPI")]
        public IActionResult SearchAPI(string? searchTerm)
        {
            if (!EsAdministradorActual())
            {
                return Forbid();
            }

            using var context = CrearConexion();
            var parameters = new DynamicParameters();
            parameters.Add("@search_term", searchTerm);

            var response = context.Query<UserResponseModel>("spUsersSearchManage", parameters, commandType: CommandType.StoredProcedure).ToList();
            return Ok(response);
        }

        [HttpGet("DetailAPI")]
        public IActionResult DetailAPI(int id)
        {
            if (!EsAdministradorActual())
            {
                return Forbid();
            }

            using var context = CrearConexion();
            var parameters = new DynamicParameters();
            parameters.Add("@id", id);

            var response = context.QueryFirstOrDefault<UserResponseModel>("spUsersGetManageDetail", parameters, commandType: CommandType.StoredProcedure);
            if (response == null)
            {
                return NotFound("No se encontró el usuario solicitado.");
            }

            return Ok(response);
        }

        [HttpGet("PrecheckAPI")]
        public IActionResult PrecheckAPI(int id, string roleName, bool isActive)
        {
            if (!EsAdministradorActual())
            {
                return Forbid();
            }

            using var context = CrearConexion();
            var parameters = new DynamicParameters();
            parameters.Add("@id", id);
            parameters.Add("@role_name", roleName);
            parameters.Add("@is_active", isActive);

            var response = context.QueryFirstOrDefault<UserResponseModel>("spUsersPrecheckManage", parameters, commandType: CommandType.StoredProcedure);
            if (response == null)
            {
                return NotFound("No se encontró el usuario solicitado.");
            }

            return Ok(response);
        }

        [HttpPut("UpdateProfileAPI")]
        public async Task<IActionResult> UpdateProfileAPI(UserProfileUpdateRequestModel model)
        {
            if (!EsAdministradorActual())
            {
                return Forbid();
            }

            var currentUserId = UsuarioActualId();
            if (currentUserId == null)
            {
                return Unauthorized("No se pudo identificar al usuario autenticado.");
            }

            using var context = CrearConexion();

            var before = context.QueryFirstOrDefault<UserResponseModel>(
                "spUsersGetManageDetail",
                new { id = model.id },
                commandType: CommandType.StoredProcedure);

            if (before == null)
            {
                return NotFound("No se encontró el usuario solicitado.");
            }

            var parameters = new DynamicParameters();
            parameters.Add("@id", model.id);
            parameters.Add("@role_name", model.role_name);
            parameters.Add("@is_active", model.is_active);
            parameters.Add("@allow_pending_appointments", model.allow_pending_appointments);
            parameters.Add("@changed_by_user_id", currentUserId);

            try
            {
                context.Execute("spUsersUpdateProfileManage", parameters, commandType: CommandType.StoredProcedure);
            }
            catch (SqlException ex) when (ex.Number == 50001 || ex.Number == 50002 || ex.Number == 50003)
            {
                return Conflict(ex.Message);
            }

            var changed = !string.Equals(before.role_name, model.role_name, StringComparison.OrdinalIgnoreCase)
                || before.is_active != model.is_active;

            if (changed && !string.IsNullOrWhiteSpace(before.email))
            {
                var updated = context.QueryFirstOrDefault<UserResponseModel>(
                    "spUsersGetManageDetail",
                    new { id = model.id },
                    commandType: CommandType.StoredProcedure);

                if (updated != null)
                {
                    var templatePath = Path.Combine(AppContext.BaseDirectory, "Templates", "UserProfileUpdated.html");
                    var html = File.Exists(templatePath)
                        ? File.ReadAllText(templatePath)
                        : "<p>Tu perfil fue actualizado.</p>";

                    html = html.Replace("{{Name}}", updated.full_name)
                        .Replace("{{Role}}", updated.role_name)
                        .Replace("{{Status}}", updated.is_active ? "Activo" : "Inactivo")
                        .Replace("{{Year}}", DateTime.Now.Year.ToString());

                    await _helpers.SendEmail(updated.email, "Actualización de perfil en Kronos", html);
                }
            }

            return Ok("Perfil de usuario actualizado correctamente.");
        }
    }
}
