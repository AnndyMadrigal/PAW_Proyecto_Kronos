using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    [AllowAnonymous]
    [Route("api/[controller]")]
    [ApiController]
    public class ErrorController(IConfiguration _config, IHelpersService _helpers) : Controller
    {
        #region Catalogo de codigos de error de negocio
        private static IActionResult? MapearErrorSqlDeNegocio(ControllerBase controller, SqlException ex)
        {
            return ex.Number switch
            {
                50010 => controller.Conflict(ex.Message),   // colaborador no disponible en ese horario
                50011 => controller.NotFound(ex.Message),   // paciente no existe/inactivo
                50012 => controller.NotFound(ex.Message),   // colaborador no existe/inactivo
                50013 => controller.NotFound(ex.Message),   // la cita no existe
                50014 => controller.BadRequest(ex.Message), // cita ya cancelada/completada
                50000 => controller.BadRequest(ex.Message), // validacion generica del SP
                _ => null
            };
        }

        #endregion

        #region Registro en base de datos

        private ErrorLogResponseModel RegistrarEnBaseDatos(int? userId, string? source, string message, string? detail)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@user_id", userId);
            parameters.Add("@source", source);
            parameters.Add("@message", message);
            parameters.Add("@detail", detail);

            return context.QueryFirstOrDefault<ErrorLogResponseModel>("system_sp_error_logs_create", parameters)
                   ?? new ErrorLogResponseModel { success = false };
        }

        #endregion

        [HttpGet("RegistrarErrorAPI")]
        public IActionResult RegistrarErrorAPI()
        {
            var feature = HttpContext.Features.Get<IExceptionHandlerPathFeature>();
            var ex = feature?.Error;

            if (ex == null)
                return StatusCode(500, new { message = "Ocurrió un error inesperado en el servidor." });

            // Errores de negocio esperados (validaciones del SP): no se
            // registran como fallas de sistema, solo se traduce la respuesta.
            if (ex is SqlException sqlEx)
            {
                var respuestaDeNegocio = MapearErrorSqlDeNegocio(this, sqlEx);
                if (respuestaDeNegocio != null)
                    return respuestaDeNegocio;
            }

            var consecutivo = _helpers.ObtenerConsecutivoToken();
            int? userId = consecutivo == 0 ? null : consecutivo;

            RegistrarEnBaseDatos(userId, feature!.Path, ex.Message, ex.ToString());

            return StatusCode(500, new { message = "Ocurrió un error inesperado en el servidor." });
        }

        //para dejar en la misma tabla los errores que ocurren en la capa WEB (que nunca accede a la BD directamente).
        [HttpPost("RegistrarErrorWebAPI")]
        public IActionResult RegistrarErrorWebAPI(ErrorLogRequestModel model)
        {
            var resultado = RegistrarEnBaseDatos(model.user_id, model.source, model.message, model.detail);
            return Ok(resultado);
        }
    }
}
