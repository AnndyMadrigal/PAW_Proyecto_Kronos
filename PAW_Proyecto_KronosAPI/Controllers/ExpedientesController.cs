using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using Microsoft.AspNetCore.Authorization;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    // RF-05 Gestion de Expedientes Clinicos.
    // Exige JWT igual que CitasController: el token viaja en el header
    // Authorization: Bearer <token> en cada llamada desde la capa WEB.
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class ExpedientesController(IConfiguration _config) : Controller
    {
        // Numeros de error personalizados que lanzan los SPs de expedientes
        // (ver 14_rf05_expedientes_sp.sql), traducidos a una respuesta HTTP clara.
        private IActionResult HandleSqlException(SqlException ex)
        {
            LogErrorToDatabase("SqlException", ex.Message, ex.ToString());

            return ex.Number switch
            {
                50101 => NotFound(ex.Message),      // paciente no existe/inactivo
                50102 => NotFound(ex.Message),      // expediente no existe
                50103 => Conflict(ex.Message),      // ya tiene expediente abierto
                50104 => BadRequest(ex.Message),    // expediente cerrado
                50105 => NotFound(ex.Message),      // condicion no existe en catalogo
                50106 => NotFound(ex.Message),      // medicamento no existe en catalogo
                50107 => BadRequest(ex.Message),    // tipo de documento invalido
                50108 => NotFound(ex.Message),      // adjunto no existe
                50109 => BadRequest(ex.Message),    // id de catalogo invalido
                50100 or 50000 => BadRequest(ex.Message), // validacion generica del SP
                _ => StatusCode(500, "Ocurrió un error al procesar la solicitud.")
            };
        }

        // RF-05 flujo alterno "Error de BD": se registra en la tabla de
        // errores del sistema y se muestra un mensaje amigable.
        private IActionResult HandleUnexpectedException(Exception ex)
        {
            LogErrorToDatabase("UnexpectedException", ex.Message, ex.ToString());
            return StatusCode(500, "Ocurrió un error inesperado al procesar la solicitud.");
        }

        private void LogErrorToDatabase(string source, string message, string detail)
        {
            try
            {
                using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
                var parameters = new DynamicParameters();
                parameters.Add("@user_id", (int?)null);
                parameters.Add("@source", "[ExpedientesController] " + source);
                parameters.Add("@message", message);
                parameters.Add("@detail", detail);
                context.Execute("system_sp_error_logs_create", parameters, commandType: System.Data.CommandType.StoredProcedure);
            }
            catch (Exception logEx)
            {
                // Si ni siquiera se puede dejar el log, no interrumpimos el flujo.
                Console.WriteLine("[ExpedientesController] ERROR al insertar en system_tbl_error_logs: " + logEx.Message);
            }
        }

        private string ObtenerRutaAdjuntos(SqlConnection context)
        {
            var ruta = context.QueryFirstOrDefault<string>(
                @"SELECT setting_value FROM config_tbl_settings
                  WHERE setting_type = N'files' AND setting_name = N'medical_attachments_root' AND deleted = 0");
            return ruta ?? "/uploads/medical-records";
        }

        [HttpPost("AbrirExpedienteAPI")]
        public IActionResult AbrirExpedienteAPI(ExpedienteOpenRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@patient_id", model.patient_id);
                parameters.Add("@user_id", model.user_id);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_records_open", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpPut("ActualizarEstadoExpedienteAPI")]
        public IActionResult ActualizarEstadoExpedienteAPI(ExpedienteUpdateStatusRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@medical_record_id", model.medical_record_id);
                parameters.Add("@status_id", model.status_id);
                parameters.Add("@user_id", model.user_id);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_records_update_status", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpPost("CrearNotaAPI")]
        public IActionResult CrearNotaAPI(ExpedienteNoteCreateRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@medical_record_id", model.medical_record_id);
                parameters.Add("@patient_id", model.patient_id);
                parameters.Add("@staff_member_id", model.staff_member_id);
                parameters.Add("@note_type_id", model.note_type_id);
                parameters.Add("@note_text", model.note_text);
                parameters.Add("@user_id", model.user_id);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_record_notes_create", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpPost("GuardarDiagnosticoAPI")]
        public IActionResult GuardarDiagnosticoAPI(ExpedienteConditionUpsertRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@id", model.id);
                parameters.Add("@patient_id", model.patient_id);
                parameters.Add("@medical_condition_id", model.medical_condition_id);
                parameters.Add("@diagnosed_at", model.diagnosed_at);
                parameters.Add("@status_id", model.status_id);
                parameters.Add("@notes", model.notes);
                parameters.Add("@user_id", model.user_id);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_patient_conditions_upsert", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpPost("GuardarTratamientoAPI")]
        public IActionResult GuardarTratamientoAPI(ExpedienteMedicationUpsertRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@id", model.id);
                parameters.Add("@patient_id", model.patient_id);
                parameters.Add("@medical_medication_id", model.medical_medication_id);
                parameters.Add("@dosage", model.dosage);
                parameters.Add("@frequency", model.frequency);
                parameters.Add("@start_date", model.start_date);
                parameters.Add("@end_date", model.end_date);
                parameters.Add("@notes", model.notes);
                parameters.Add("@user_id", model.user_id);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_patient_medications_upsert", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpGet("DetalleExpedienteAPI")]
        public IActionResult DetalleExpedienteAPI(int? medicalRecordId, int? patientId, int accessedByUserId, int pageNumber = 1, int pageSize = 10)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@medical_record_id", medicalRecordId);
                parameters.Add("@patient_id", patientId);
                parameters.Add("@accessed_by_user_id", accessedByUserId);
                parameters.Add("@access_reason", "Consulta desde módulo de expedientes.");
                parameters.Add("@ip_address", HttpContext.Connection.RemoteIpAddress?.ToString());
                parameters.Add("@device_info", Request.Headers.UserAgent.ToString());
                parameters.Add("@page_number", pageNumber);
                parameters.Add("@page_size", pageSize);

                using var multi = context.QueryMultiple("medical_sp_orc_records_get_detail", parameters, commandType: System.Data.CommandType.StoredProcedure);
                var expediente = multi.Read<ExpedienteHeaderResponseModel>().FirstOrDefault();
                var notas = multi.Read<ExpedienteNoteResponseModel>().ToList();
                var diagnosticos = multi.Read<ExpedienteConditionResponseModel>().ToList();
                var tratamientos = multi.Read<ExpedienteMedicationResponseModel>().ToList();
                var adjuntos = multi.Read<ExpedienteAttachmentResponseModel>().ToList();

                if (expediente == null)
                    return NotFound("El expediente indicado no existe.");

                return Ok(new ExpedienteDetailFullResponseModel
                {
                    expediente = expediente,
                    notas = notas,
                    diagnosticos = diagnosticos,
                    tratamientos = tratamientos,
                    adjuntos = adjuntos
                });
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpGet("BuscarPacientesAPI")]
        public IActionResult BuscarPacientesAPI(string? search)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@search", search);

                var response = context.Query<PatientSearchResponseModel>(
                    "patient_sp_patients_search", parameters, commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        // RF-05 flujo alterno "Paciente no encontrado: se ofrece crearlo".
        [HttpPost("RegistrarPacienteAPI")]
        public IActionResult RegistrarPacienteAPI(PatientRegisterRequestModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@first_name", model.first_name);
                parameters.Add("@last_name", model.last_name);
                parameters.Add("@identification_number", model.identification_number);
                parameters.Add("@birth_date", model.birth_date);
                parameters.Add("@gender_id", model.gender_id);
                parameters.Add("@phone", model.phone);
                parameters.Add("@email", model.email);
                parameters.Add("@address_id", model.address_id);
                parameters.Add("@contacts_json", (string?)null);
                parameters.Add("@open_medical_record", model.open_medical_record);
                parameters.Add("@created_by_user_id", model.created_by_user_id);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "patient_sp_orc_patients_register", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpGet("CatalogoAPI/{catalogName}")]
        public IActionResult CatalogoAPI(string catalogName)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@catalog_name", catalogName);

                var response = context.Query<CatalogItemResponseModel>(
                    "config_sp_catalog_items_list", parameters, commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        // Tipos de documento para adjuntos: config_tbl_document_types es tabla
        // aparte de config_tbl_catalog_items, por eso necesita su propio SP
        // (config_sp_document_types_list) y su propio endpoint, distinto de CatalogoAPI.
        [HttpGet("TiposDocumentoAPI")]
        public IActionResult TiposDocumentoAPI()
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var response = context.Query<DocumentTypeResponseModel>(
                    "config_sp_document_types_list", commandType: System.Data.CommandType.StoredProcedure).ToList();
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        #region Adjuntos (archivo fisico + registro en BD)

        [HttpPost("SubirAdjuntoAPI")]
        public async Task<IActionResult> SubirAdjuntoAPI([FromForm] int medicalRecordId, [FromForm] int patientId,
            [FromForm] int documentTypeId, [FromForm] int uploadedByUserId, [FromForm] IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Debe adjuntar un archivo.");

            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                string carpetaBase = ObtenerRutaAdjuntos(context);
                string carpetaFisica = Path.Combine(AppContext.BaseDirectory, carpetaBase.TrimStart('/', '\\'));
                Directory.CreateDirectory(carpetaFisica);

                string nombreUnico = $"{Guid.NewGuid()}_{Path.GetFileName(file.FileName)}";
                string rutaCompleta = Path.Combine(carpetaFisica, nombreUnico);

                using (var stream = new FileStream(rutaCompleta, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                var parameters = new DynamicParameters();
                parameters.Add("@medical_record_id", medicalRecordId);
                parameters.Add("@patient_id", patientId);
                parameters.Add("@document_type_id", documentTypeId);
                parameters.Add("@file_name", file.FileName);
                parameters.Add("@file_path", Path.Combine(carpetaBase, nombreUnico).Replace('\\', '/'));
                parameters.Add("@content_type", file.ContentType);
                parameters.Add("@file_size", file.Length);
                parameters.Add("@uploaded_by_user_id", uploadedByUserId);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_record_attachments_create", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpGet("DescargarAdjuntoAPI/{id}")]
        public IActionResult DescargarAdjuntoAPI(int id, int userId)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@attachment_id", id);
                parameters.Add("@user_id", userId);
                parameters.Add("@ip_address", HttpContext.Connection.RemoteIpAddress?.ToString());
                parameters.Add("@device_info", Request.Headers.UserAgent.ToString());

                var adjunto = context.QueryFirstOrDefault<ExpedienteAttachmentDownloadModel>(
                    "medical_sp_record_attachments_download", parameters, commandType: System.Data.CommandType.StoredProcedure);

                if (adjunto == null)
                    return NotFound("El adjunto indicado no existe.");

                string rutaFisica = Path.Combine(AppContext.BaseDirectory, adjunto.file_path.TrimStart('/', '\\'));
                if (!System.IO.File.Exists(rutaFisica))
                    return NotFound("El archivo físico no se encuentra en el servidor.");

                var bytes = System.IO.File.ReadAllBytes(rutaFisica);
                return File(bytes, adjunto.content_type ?? "application/octet-stream", adjunto.file_name);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        [HttpDelete("EliminarAdjuntoAPI/{id}")]
        public IActionResult EliminarAdjuntoAPI(int id, int userId)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@attachment_id", id);
                parameters.Add("@user_id", userId);

                var response = context.QueryFirstOrDefault<ExpedienteOperationResponseModel>(
                    "medical_sp_record_attachments_delete", parameters, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(response);
            }
            catch (SqlException ex) { return HandleSqlException(ex); }
            catch (Exception ex) { return HandleUnexpectedException(ex); }
        }

        #endregion
    }
}