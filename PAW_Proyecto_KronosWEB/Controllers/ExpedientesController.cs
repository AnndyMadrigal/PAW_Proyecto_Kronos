using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
using PAW_Proyecto_Kronos.Models;
using System.Net;
using System.Net.Http.Headers;

namespace PAW_Proyecto_Kronos.Controllers
{
    // RF-05 Gestion de Expedientes Clinicos.
    [ActiveSession]
    public class ExpedientesController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        private HttpClient CrearClienteApi()
        {
            var client = _http.CreateClient();
            client.BaseAddress = new Uri(_config["Valores:UrlApi"]!);
            var token = HttpContext.Session.GetString("Token");
            if (!string.IsNullOrEmpty(token))
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return client;
        }

        private int UsuarioActualId => HttpContext.Session.GetInt32("Consecutivo") ?? 0;

        private async Task<List<CatalogOptionModel>> ObtenerCatalogoAsync(HttpClient client, string catalogName)
        {
            var response = await client.GetAsync($"Expedientes/CatalogoAPI/{catalogName}");
            if (response.StatusCode != HttpStatusCode.OK) return new List<CatalogOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<CatalogOptionModel>>() ?? new();
        }

        private async Task<List<DocumentTypeOptionModel>> ObtenerTiposDocumentoAsync(HttpClient client)
        {
            var response = await client.GetAsync("Expedientes/TiposDocumentoAPI");
            if (response.StatusCode != HttpStatusCode.OK) return new List<DocumentTypeOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<DocumentTypeOptionModel>>() ?? new();
        }

        private async Task<List<PatientOptionModel>> ObtenerPacientesAsync(HttpClient client, string? search = null)
        {
            var url = "Expedientes/BuscarPacientesAPI";
            if (!string.IsNullOrWhiteSpace(search)) url += $"?search={Uri.EscapeDataString(search)}";
            var response = await client.GetAsync(url);
            if (response.StatusCode != HttpStatusCode.OK) return new List<PatientOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<PatientOptionModel>>() ?? new();
        }

        // Reutiliza el endpoint de colaboradores de Citas: es un catalogo
        // general de personal, no algo especifico de RF-06.
        private async Task<List<StaffOptionModel>> ObtenerColaboradoresAsync(HttpClient client)
        {
            var response = await client.GetAsync("Citas/BuscarColaboradoresAPI");
            if (response.StatusCode != HttpStatusCode.OK) return new List<StaffOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<StaffOptionModel>>() ?? new();
        }

        #region Busqueda de paciente (punto de entrada del modulo)

        [HttpGet]
        public async Task<IActionResult> Index(string? search)
        {
            var client = CrearClienteApi();
            var model = new ExpedienteSearchViewModel { Search = search };

            try
            {
                model.Pacientes = await ObtenerPacientesAsync(client, search);
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return View(model);
        }

        // RF-05 flujo alterno "Paciente no encontrado: se ofrece crearlo".
        [HttpGet]
        public IActionResult RegistrarPaciente()
        {
            return View(new PatientRegisterFormModel());
        }

        [HttpPost]
        public async Task<IActionResult> RegistrarPaciente(PatientRegisterFormModel model)
        {
            var client = CrearClienteApi();

            if (string.IsNullOrWhiteSpace(model.first_name) || string.IsNullOrWhiteSpace(model.last_name))
            {
                ViewBag.Mensaje = "El nombre y apellido del paciente son requeridos.";
                return View(model);
            }

            var payload = new
            {
                first_name = model.first_name,
                last_name = model.last_name,
                identification_number = model.identification_number,
                birth_date = model.birth_date,
                phone = model.phone,
                email = model.email,
                open_medical_record = model.open_medical_record,
                created_by_user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PostAsJsonAsync("Expedientes/RegistrarPacienteAPI", payload);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    var data = await response.Content.ReadFromJsonAsync<ExpedienteOperationApiModel>();
                    TempData["Mensaje"] = "Paciente registrado correctamente.";

                    if (data?.medical_record_id != null)
                        return RedirectToAction("Detalle", new { medicalRecordId = data.medical_record_id });

                    return RedirectToAction("Index");
                }

                ViewBag.Mensaje = await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                ViewBag.Mensaje = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                ViewBag.Mensaje = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return View(model);
        }

        #endregion

        #region Abrir expediente

        [HttpPost]
        public async Task<IActionResult> AbrirExpediente(int patientId)
        {
            var client = CrearClienteApi();

            var payload = new { patient_id = patientId, user_id = UsuarioActualId };

            try
            {
                var response = await client.PostAsJsonAsync("Expedientes/AbrirExpedienteAPI", payload);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    var data = await response.Content.ReadFromJsonAsync<ExpedienteOperationApiModel>();
                    TempData["Mensaje"] = "Expediente abierto correctamente.";
                    return RedirectToAction("Detalle", new { medicalRecordId = data?.medical_record_id });
                }

                // El paciente ya tiene un expediente abierto/suspendido (codigo 50103
                // del SP -> HTTP 409 Conflict): en vez de mostrar el error, lo
                // llevamos directo a su expediente existente.
                if (response.StatusCode == HttpStatusCode.Conflict)
                {
                    return RedirectToAction("Detalle", new { patientId });
                }

                TempData["Mensaje"] = await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Index");
        }

        #endregion

        #region Detalle (con notas paginadas, diagnosticos, tratamientos, adjuntos)

        [HttpGet]
        public async Task<IActionResult> Detalle(int? medicalRecordId, int? patientId, int page = 1)
        {
            var client = CrearClienteApi();

            try
            {
                var url = $"Expedientes/DetalleExpedienteAPI?accessedByUserId={UsuarioActualId}&pageNumber={page}&pageSize=10";
                if (medicalRecordId.HasValue) url += $"&medicalRecordId={medicalRecordId}";
                if (patientId.HasValue) url += $"&patientId={patientId}";

                var response = await client.GetAsync(url);

                if (response.StatusCode != HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "El expediente indicado no existe.";
                    return RedirectToAction("Index");
                }

                var model = await response.Content.ReadFromJsonAsync<ExpedienteDetailFullModel>() ?? new ExpedienteDetailFullModel();
                model.PageNumber = page;

                model.TiposNota = await ObtenerCatalogoAsync(client, "medical_note_type");
                model.EstadosCondicion = await ObtenerCatalogoAsync(client, "condition_status");
                model.TiposDocumento = await ObtenerTiposDocumentoAsync(client);
                ViewBag.Colaboradores = await ObtenerColaboradoresAsync(client);

                return View(model);
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
                return RedirectToAction("Index");
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
                return RedirectToAction("Index");
            }
        }

        #endregion

        #region Notas clinicas

        [HttpPost]
        public async Task<IActionResult> CrearNota(ExpedienteNoteFormModel model)
        {
            var client = CrearClienteApi();

            if (string.IsNullOrWhiteSpace(model.note_text))
            {
                TempData["Mensaje"] = "El texto de la nota es requerido.";
                return RedirectToAction("Detalle", new { medicalRecordId = model.medical_record_id });
            }

            var payload = new
            {
                medical_record_id = model.medical_record_id,
                patient_id = model.patient_id,
                staff_member_id = model.staff_member_id,
                note_type_id = model.note_type_id,
                note_text = model.note_text,
                user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PostAsJsonAsync("Expedientes/CrearNotaAPI", payload);
                TempData["Mensaje"] = response.StatusCode == HttpStatusCode.OK
                    ? "Nota clínica registrada correctamente."
                    : await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Detalle", new { medicalRecordId = model.medical_record_id });
        }

        #endregion

        #region Diagnostico (condiciones)

        [HttpPost]
        public async Task<IActionResult> GuardarDiagnostico(ExpedienteConditionFormModel model, int medicalRecordId)
        {
            var client = CrearClienteApi();

            var payload = new
            {
                id = model.id,
                patient_id = model.patient_id,
                medical_condition_id = model.medical_condition_id,
                diagnosed_at = model.diagnosed_at,
                status_id = model.status_id,
                notes = model.notes,
                user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PostAsJsonAsync("Expedientes/GuardarDiagnosticoAPI", payload);
                TempData["Mensaje"] = response.StatusCode == HttpStatusCode.OK
                    ? "Diagnóstico guardado correctamente."
                    : await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Detalle", new { medicalRecordId });
        }

        #endregion

        #region Tratamientos (medicamentos)

        [HttpPost]
        public async Task<IActionResult> GuardarTratamiento(ExpedienteMedicationFormModel model, int medicalRecordId)
        {
            var client = CrearClienteApi();

            var payload = new
            {
                id = model.id,
                patient_id = model.patient_id,
                medical_medication_id = model.medical_medication_id,
                dosage = model.dosage,
                frequency = model.frequency,
                start_date = model.start_date,
                end_date = model.end_date,
                notes = model.notes,
                user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PostAsJsonAsync("Expedientes/GuardarTratamientoAPI", payload);
                TempData["Mensaje"] = response.StatusCode == HttpStatusCode.OK
                    ? "Tratamiento guardado correctamente."
                    : await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Detalle", new { medicalRecordId });
        }

        #endregion

        #region Adjuntos

        [HttpPost]
        [RequestSizeLimit(20_000_000)]
        public async Task<IActionResult> SubirAdjunto(int medicalRecordId, int patientId, int documentTypeId, IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                TempData["Mensaje"] = "Debes seleccionar un archivo.";
                return RedirectToAction("Detalle", new { medicalRecordId });
            }

            var client = CrearClienteApi();

            try
            {
                using var content = new MultipartFormDataContent();
                using var fileStream = file.OpenReadStream();
                using var fileContent = new StreamContent(fileStream);
                fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);

                content.Add(new StringContent(medicalRecordId.ToString()), "medicalRecordId");
                content.Add(new StringContent(patientId.ToString()), "patientId");
                content.Add(new StringContent(documentTypeId.ToString()), "documentTypeId");
                content.Add(new StringContent(UsuarioActualId.ToString()), "uploadedByUserId");
                content.Add(fileContent, "file", file.FileName);

                var response = await client.PostAsync("Expedientes/SubirAdjuntoAPI", content);
                TempData["Mensaje"] = response.StatusCode == HttpStatusCode.OK
                    ? "Archivo adjuntado correctamente."
                    : await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Detalle", new { medicalRecordId });
        }

        [HttpGet]
        public async Task<IActionResult> DescargarAdjunto(int id, int medicalRecordId)
        {
            var client = CrearClienteApi();

            try
            {
                var response = await client.GetAsync($"Expedientes/DescargarAdjuntoAPI/{id}?userId={UsuarioActualId}");

                if (response.StatusCode != HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "No se pudo descargar el archivo.";
                    return RedirectToAction("Detalle", new { medicalRecordId });
                }

                var bytes = await response.Content.ReadAsByteArrayAsync();
                var contentType = response.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";
                var fileName = response.Content.Headers.ContentDisposition?.FileNameStar
                               ?? response.Content.Headers.ContentDisposition?.FileName
                               ?? "adjunto";

                return File(bytes, contentType, fileName);
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
                return RedirectToAction("Detalle", new { medicalRecordId });
            }
        }

        [HttpPost]
        public async Task<IActionResult> EliminarAdjunto(int id, int medicalRecordId)
        {
            var client = CrearClienteApi();

            try
            {
                var response = await client.DeleteAsync($"Expedientes/EliminarAdjuntoAPI/{id}?userId={UsuarioActualId}");
                TempData["Mensaje"] = response.StatusCode == HttpStatusCode.OK
                    ? "Archivo adjunto eliminado correctamente."
                    : await response.Content.ReadAsStringAsync();
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Detalle", new { medicalRecordId });
        }

        #endregion
    }

    // Shape minimo para leer la respuesta de operaciones de escritura
    // (success + ids), igual patron que CitaAvailabilityApiModel en Citas.
    public class ExpedienteOperationApiModel
    {
        public bool success { get; set; }
        public int? medical_record_id { get; set; }
        public int? patient_id { get; set; }
        public int? note_id { get; set; }
        public int? patient_condition_id { get; set; }
        public int? patient_medication_id { get; set; }
        public int? attachment_id { get; set; }
    }
}