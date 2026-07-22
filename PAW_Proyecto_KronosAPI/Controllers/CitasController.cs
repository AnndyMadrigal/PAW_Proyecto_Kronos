using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    // RF-06 Gestion de Citas.
    // A diferencia de AuthController, este controller SI exige JWT (no lleva
    // [AllowAnonymous]): el token que emite Auth/LoginAPI debe viajar en el
    // header Authorization: Bearer <token> en cada llamada desde la capa WEB.
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class CitasController(IConfiguration _config, IHelpersService _helpers) : Controller
    {
        // Numeros de error personalizados que lanzan los SPs de citas
        // (ver 10_rf06_citas_sp.sql), para traducirlos a una respuesta HTTP
        // clara. El detalle fino de este manejo se termina de pulir en el
        // paso de "Validaciones y manejo de errores" del RF-06.
        private IActionResult HandleSqlException(SqlException ex)
        {
            return ex.Number switch
            {
                50010 => Conflict(ex.Message),      // colaborador no disponible en ese horario
                50011 => NotFound(ex.Message),      // paciente no existe/inactivo
                50012 => NotFound(ex.Message),      // colaborador no existe/inactivo
                50013 => NotFound(ex.Message),      // la cita no existe
                50014 => BadRequest(ex.Message),    // cita ya cancelada/completada
                50000 => BadRequest(ex.Message),    // validacion generica del SP
                _ => StatusCode(500, "Ocurrió un error al procesar la solicitud.")
            };
        }

        // RF-06 Paso 5: cualquier error que no sea un SqlException controlado
        // (timeout, problema de red hacia SQL, etc.) tambien debe devolver
        // una respuesta clara al WEB en vez de dejar que ASP.NET muestre una
        // excepcion cruda. Se deja el detalle en consola para diagnosticar.
        private IActionResult HandleUnexpectedException(Exception ex)
        {
            Console.WriteLine("[CitasController] ERROR inesperado: " + ex);
            return StatusCode(500, "Ocurrió un error inesperado al procesar la solicitud.");
        }

        private static string? ToJson<T>(List<T>? items)
        {
            return (items == null || items.Count == 0) ? null : JsonSerializer.Serialize(items);
        }

        [HttpPost("CrearCitaAPI")]
        public async Task<IActionResult> CrearCitaAPI(CitaCreateRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@patient_id", model.patient_id);
                parameters.Add("@event_type_id", model.event_type_id);
                parameters.Add("@scheduled_start_at", model.scheduled_start_at);
                parameters.Add("@scheduled_end_at", model.scheduled_end_at);
                parameters.Add("@location_type_id", model.location_type_id);
                parameters.Add("@location_id", model.location_id);
                parameters.Add("@address_id", model.address_id);
                parameters.Add("@location_description", model.location_description);
                parameters.Add("@main_staff_member_id", model.main_staff_member_id);
                parameters.Add("@summary", model.summary);
                parameters.Add("@created_by_user_id", model.created_by_user_id);
                parameters.Add("@staff_json", ToJson(model.staff));
                parameters.Add("@services_json", ToJson(model.service_ids?.Select(id => new { service_id = id }).ToList()));

                var response = context.QueryFirstOrDefault<CitaOperationResponseModel>("service_sp_orc_events_create", parameters, commandType: System.Data.CommandType.StoredProcedure);

                // La cita ya quedo guardada en este punto. Un fallo de correo no
                // debe cambiar la respuesta (RF-06, flujo alterno "fallo de correo").
                if (response != null && response.success)
                    await EnviarNotificacionesCitaAsync(response.service_event_id, "creada");

                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpPut("ActualizarCitaAPI")]
        public IActionResult ActualizarCitaAPI(CitaUpdateRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@service_event_id", model.service_event_id);
                parameters.Add("@patient_id", model.patient_id);
                parameters.Add("@event_type_id", model.event_type_id);
                parameters.Add("@scheduled_start_at", model.scheduled_start_at);
                parameters.Add("@scheduled_end_at", model.scheduled_end_at);
                parameters.Add("@location_type_id", model.location_type_id);
                parameters.Add("@location_id", model.location_id);
                parameters.Add("@address_id", model.address_id);
                parameters.Add("@location_description", model.location_description);
                parameters.Add("@main_staff_member_id", model.main_staff_member_id);
                parameters.Add("@summary", model.summary);
                parameters.Add("@reason", model.reason);
                parameters.Add("@changed_by_user_id", model.changed_by_user_id);
                parameters.Add("@staff_json", ToJson(model.staff));
                parameters.Add("@services_json", ToJson(model.service_ids?.Select(id => new { service_id = id }).ToList()));

                var response = context.QueryFirstOrDefault<CitaOperationResponseModel>("service_sp_orc_events_update", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpPut("ReprogramarCitaAPI")]
        public IActionResult ReprogramarCitaAPI(CitaRescheduleRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@service_event_id", model.service_event_id);
                parameters.Add("@scheduled_start_at", model.scheduled_start_at);
                parameters.Add("@scheduled_end_at", model.scheduled_end_at);
                parameters.Add("@reason", model.reason);
                parameters.Add("@changed_by_user_id", model.changed_by_user_id);

                var response = context.QueryFirstOrDefault<CitaOperationResponseModel>("service_sp_orc_events_reschedule", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpPut("CancelarCitaAPI")]
        public async Task<IActionResult> CancelarCitaAPI(CitaCancelRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@service_event_id", model.service_event_id);
                parameters.Add("@reason", model.reason);
                parameters.Add("@changed_by_user_id", model.changed_by_user_id);

                var response = context.QueryFirstOrDefault<CitaOperationResponseModel>("service_sp_orc_events_cancel", parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (response != null && response.success)
                    await EnviarNotificacionesCitaAsync(response.service_event_id, "cancelada");

                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpGet("ListarCitasAPI")]
        public IActionResult ListarCitasAPI(DateTime? dateFrom, DateTime? dateTo, int? patientId, int? staffMemberId, int? statusId, int? eventTypeId)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@date_from", dateFrom?.Date);
                parameters.Add("@date_to", dateTo?.Date);
                parameters.Add("@patient_id", patientId);
                parameters.Add("@staff_member_id", staffMemberId);
                parameters.Add("@status_id", statusId);
                parameters.Add("@event_type_id", eventTypeId);

                var response = context.Query<CitaResponseModel>("service_sp_report_events", parameters, commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpGet("DetalleCitaAPI/{id}")]
        public IActionResult DetalleCitaAPI(int id)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@service_event_id", id);

                using var multi = context.QueryMultiple("service_sp_events_get_detail", parameters, commandType: System.Data.CommandType.StoredProcedure);
                var cita = multi.Read<CitaDetailResponseModel>().FirstOrDefault();
                var historial = multi.Read<CitaStatusHistoryResponseModel>().ToList();

                if (cita == null)
                    return NotFound("La cita indicada no existe.");

                return Ok(new CitaDetailFullResponseModel { cita = cita, historial = historial });
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpGet("VerificarDisponibilidadAPI")]
        public IActionResult VerificarDisponibilidadAPI(int staffMemberId, DateTime scheduledStartAt, DateTime scheduledEndAt, int? excludeEventId)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@staff_member_id", staffMemberId);
                parameters.Add("@scheduled_start_at", scheduledStartAt);
                parameters.Add("@scheduled_end_at", scheduledEndAt);
                parameters.Add("@exclude_event_id", excludeEventId);

                using var multi = context.QueryMultiple("service_sp_events_validate_staff_availability", parameters, commandType: System.Data.CommandType.StoredProcedure);
                var isAvailable = multi.ReadFirst<bool>();
                var suggestedSlots = isAvailable ? new List<CitaSuggestedSlotModel>() : multi.Read<CitaSuggestedSlotModel>().ToList();

                return Ok(new CitaAvailabilityResponseModel { is_available = isAvailable, suggested_slots = suggestedSlots });
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpGet("BuscarPacientesAPI")]
        public IActionResult BuscarPacientesAPI(string? search)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@search", search);

                var response = context.Query<PatientSearchResponseModel>("patient_sp_patients_search", parameters, commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpGet("BuscarColaboradoresAPI")]
        public IActionResult BuscarColaboradoresAPI(string? search, int? staffRoleId)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@search", search);
                parameters.Add("@staff_role_id", staffRoleId);

                var response = context.Query<StaffSearchResponseModel>("staff_sp_members_search", parameters, commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        [HttpGet("CatalogoAPI/{catalogName}")]
        public IActionResult CatalogoAPI(string catalogName)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@catalog_name", catalogName);

                var response = context.Query<CatalogItemResponseModel>("config_sp_catalog_items_list", parameters, commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex)
            {
                return HandleSqlException(ex);
            }
            catch (Exception ex)
            {
                return HandleUnexpectedException(ex);
            }
        }

        #region Notificaciones (RF-06)

        // Envia (o intenta enviar) los correos de una cita al paciente y al
        // colaborador, y deja registro en notification_tbl_logs de cada
        // intento (enviado o fallido). Este metodo nunca deja que una falla
        // de correo se propague hacia el endpoint que lo llama: la cita ya
        // esta guardada en BD antes de que se ejecute esto.
        private async Task EnviarNotificacionesCitaAsync(int serviceEventId, string evento)
        {
            try
            {
                using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                // OJO: el SP devuelve 2 result sets (cita + historial), y aqui
                // solo nos interesa el primero. Cerramos "multi" apenas lo
                // leemos (bloque propio) para liberar el DataReader antes de
                // seguir usando "context" para las consultas de catalogos y
                // el INSERT del log; si no, revienta con
                // "Ya hay un DataReader abierto asociado a Connection".
                CitaDetailResponseModel? cita;
                var detailParams = new DynamicParameters();
                detailParams.Add("@service_event_id", serviceEventId);
                using (var multi = context.QueryMultiple("service_sp_events_get_detail", detailParams, commandType: System.Data.CommandType.StoredProcedure))
                {
                    cita = multi.Read<CitaDetailResponseModel>().FirstOrDefault();
                }
                if (cita == null) return;

                int? tipoEmailId = await context.QueryFirstOrDefaultAsync<int?>(
                    @"SELECT ci.id FROM config_tbl_catalog_items ci
                      INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
                      WHERE c.name = N'notification_type' AND ci.value = N'email'");
                int? statusSentId = await context.QueryFirstOrDefaultAsync<int?>(
                    @"SELECT ci.id FROM config_tbl_catalog_items ci
                      INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
                      WHERE c.name = N'notification_status' AND ci.value = N'sent'");
                int? statusFailedId = await context.QueryFirstOrDefaultAsync<int?>(
                    @"SELECT ci.id FROM config_tbl_catalog_items ci
                      INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
                      WHERE c.name = N'notification_status' AND ci.value = N'failed'");

                string fecha = cita.scheduled_start_at.ToString("dd/MM/yyyy HH:mm");
                string year = DateTime.Now.Year.ToString();
                string direccion = string.IsNullOrEmpty(cita.address_line) ? (cita.location_description ?? "N/A") : cita.address_line!;
                bool esCancelada = evento == "cancelada";

                if (!string.IsNullOrEmpty(cita.patient_email))
                {
                    string plantilla = esCancelada ? "CitaCanceladaPaciente.html" : "CitaCreadaPaciente.html";
                    string html = System.IO.File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Templates", plantilla));
                    html = html.Replace("{{Nombre}}", $"{cita.patient_first_name} {cita.patient_last_name}")
                               .Replace("{{TipoCita}}", cita.event_type_name)
                               .Replace("{{Fecha}}", fecha)
                               .Replace("{{Ubicacion}}", cita.location_type_name)
                               .Replace("{{Direccion}}", direccion)
                               .Replace("{{Colaborador}}", string.IsNullOrEmpty(cita.staff_first_name) ? "Por asignar" : $"{cita.staff_first_name} {cita.staff_last_name}")
                               .Replace("{{Year}}", year);

                    string asunto = esCancelada ? "Kronos - Tu cita ha sido cancelada" : "Kronos - Confirmación de cita";
                    await EnviarYRegistrarAsync(context, cita.patient_email!, asunto, html, tipoEmailId, statusSentId, statusFailedId, cita.patient_id, serviceEventId);
                }

                if (!string.IsNullOrEmpty(cita.staff_email))
                {
                    string plantilla = esCancelada ? "CitaCanceladaColaborador.html" : "CitaCreadaColaborador.html";
                    string html = System.IO.File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Templates", plantilla));
                    html = html.Replace("{{Nombre}}", $"{cita.staff_first_name} {cita.staff_last_name}")
                               .Replace("{{TipoCita}}", cita.event_type_name)
                               .Replace("{{Fecha}}", fecha)
                               .Replace("{{Ubicacion}}", cita.location_type_name)
                               .Replace("{{Direccion}}", direccion)
                               .Replace("{{Paciente}}", string.IsNullOrEmpty(cita.patient_first_name) ? "Sin paciente asociado" : $"{cita.patient_first_name} {cita.patient_last_name}")
                               .Replace("{{Year}}", year);

                    string asunto = esCancelada ? "Kronos - Cita cancelada" : "Kronos - Nueva cita asignada";
                    await EnviarYRegistrarAsync(context, cita.staff_email!, asunto, html, tipoEmailId, statusSentId, statusFailedId, null, serviceEventId);
                }
            }
            catch (Exception ex)
            {
                // La cita ya se guardo antes de llegar aqui (RF-06, flujo
                // alterno "fallo de correo"): un error aqui no debe tumbar
                // la respuesta del endpoint que creo o cancelo la cita.
                // Se deja visible en consola para poder diagnosticar fallas
                // de correo/DB sin afectar al usuario.
                Console.WriteLine("[EnviarNotificacionesCitaAsync] ERROR: " + ex.Message);
            }
        }

        // Envia un correo puntual y registra el resultado (enviado o fallido)
        // en notification_tbl_logs via notification_sp_logs_create.
        private async Task EnviarYRegistrarAsync(SqlConnection context, string destinatario, string asunto, string cuerpoHtml,
            int? notificationTypeId, int? statusSentId, int? statusFailedId, int? patientId, int serviceEventId)
        {
            var logParams = new DynamicParameters();
            logParams.Add("@user_id", null);
            logParams.Add("@patient_id", patientId);
            logParams.Add("@service_event_id", serviceEventId);
            logParams.Add("@notification_type_id", notificationTypeId);
            logParams.Add("@recipient", destinatario);
            logParams.Add("@subject", asunto);
            logParams.Add("@message", cuerpoHtml);

            try
            {
                await _helpers.SendEmail(destinatario, asunto, cuerpoHtml);
                logParams.Add("@status_id", statusSentId);
                logParams.Add("@sent_at", DateTime.Now);
                logParams.Add("@error_message", (string?)null);
            }
            catch (Exception ex)
            {
                logParams.Add("@status_id", statusFailedId);
                logParams.Add("@sent_at", (DateTime?)null);
                logParams.Add("@error_message", ex.Message);
            }

            try
            {
                context.Execute("notification_sp_logs_create", logParams, commandType: System.Data.CommandType.StoredProcedure);
            }
            catch (Exception ex)
            {
                // Si ni siquiera se puede dejar el log, no interrumpimos el
                // flujo (el correo, o el intento, ya se proceso). Se deja
                // visible en consola para no perder de vista el problema.
                Console.WriteLine("[EnviarYRegistrarAsync] ERROR al insertar en notification_tbl_logs: " + ex.Message);
            }
        }

        #endregion
    }
}