using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
using PAW_Proyecto_Kronos.Models;
using System.Net;
using System.Net.Http.Headers;

namespace PAW_Proyecto_Kronos.Controllers
{
    // RF-06 Gestion de Citas.
    [ActiveSession]
    public class CitasController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        // El CitasController de la API exige JWT ([Authorize]), asi que toda
        // llamada tiene que llevar el token que se guardo en la Sesion al
        // hacer login (Auth/Login).
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
            var response = await client.GetAsync($"Citas/CatalogoAPI/{catalogName}");
            if (response.StatusCode != HttpStatusCode.OK) return new List<CatalogOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<CatalogOptionModel>>() ?? new();
        }

        private async Task<List<PatientOptionModel>> ObtenerPacientesAsync(HttpClient client)
        {
            var response = await client.GetAsync("Citas/BuscarPacientesAPI");
            if (response.StatusCode != HttpStatusCode.OK) return new List<PatientOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<PatientOptionModel>>() ?? new();
        }

        private async Task<List<StaffOptionModel>> ObtenerColaboradoresAsync(HttpClient client)
        {
            var response = await client.GetAsync("Citas/BuscarColaboradoresAPI");
            if (response.StatusCode != HttpStatusCode.OK) return new List<StaffOptionModel>();
            return await response.Content.ReadFromJsonAsync<List<StaffOptionModel>>() ?? new();
        }

        private async Task LlenarListasFormularioAsync(HttpClient client, CitaFormModel model)
        {
            model.Pacientes = await ObtenerPacientesAsync(client);
            model.Colaboradores = await ObtenerColaboradoresAsync(client);
            model.TiposCita = await ObtenerCatalogoAsync(client, "service_event_type");
            model.TiposUbicacion = await ObtenerCatalogoAsync(client, "service_event_location_type");
        }

        // RF-06 Paso 5: validaciones minimas antes de llamar a la API. El
        // detalle fino (paciente/colaborador existen, disponibilidad,
        // catalogos validos, sede/direccion obligatoria segun tipo de
        // ubicacion) lo sigue validando el SP; esto solo evita mandar una
        // peticion claramente incompleta y da un mensaje mas directo.
        private static string? ValidarCamposObligatorios(CitaFormModel model)
        {
            if (model.patient_id is null or 0)
                return "Debes seleccionar un paciente.";
            if (model.event_type_id <= 0)
                return "Debes seleccionar el tipo de cita.";
            if (model.location_type_id <= 0)
                return "Debes seleccionar el tipo de ubicación.";
            if (model.scheduled_start_at is null || model.scheduled_end_at is null)
                return "Debes indicar la fecha y hora de inicio y fin.";
            if (model.scheduled_end_at <= model.scheduled_start_at)
                return "La hora de fin debe ser mayor que la hora de inicio.";
            return null;
        }

        #region Calendario (Index)

        [HttpGet]
        public async Task<IActionResult> Index(int? year, int? month, int? patientId, int? staffMemberId, int? statusId, int? eventTypeId)
        {
            var hoy = DateTime.Today;
            int anio = year ?? hoy.Year;
            int mes = month ?? hoy.Month;

            var primerDiaMes = new DateTime(anio, mes, 1);
            var ultimoDiaMes = primerDiaMes.AddMonths(1).AddDays(-1);

            // El calendario siempre muestra semanas completas (domingo a sabado).
            var inicioCalendario = primerDiaMes.AddDays(-(int)primerDiaMes.DayOfWeek);
            var finCalendario = ultimoDiaMes.AddDays(6 - (int)ultimoDiaMes.DayOfWeek);

            var model = new CitaCalendarViewModel
            {
                Year = anio,
                Month = mes,
                MonthName = primerDiaMes.ToString("MMMM yyyy", new System.Globalization.CultureInfo("es-CR")),
                PatientId = patientId,
                StaffMemberId = staffMemberId,
                StatusId = statusId,
                EventTypeId = eventTypeId
            };

            List<CitaListItemModel> citas = new();

            try
            {
                var client = CrearClienteApi();

                var query = $"Citas/ListarCitasAPI?dateFrom={inicioCalendario:yyyy-MM-dd}&dateTo={finCalendario:yyyy-MM-dd}";
                if (patientId.HasValue) query += $"&patientId={patientId}";
                if (staffMemberId.HasValue) query += $"&staffMemberId={staffMemberId}";
                if (statusId.HasValue) query += $"&statusId={statusId}";
                if (eventTypeId.HasValue) query += $"&eventTypeId={eventTypeId}";

                var response = await client.GetAsync(query);
                citas = response.StatusCode == HttpStatusCode.OK
                    ? await response.Content.ReadFromJsonAsync<List<CitaListItemModel>>() ?? new()
                    : new List<CitaListItemModel>();

                model.Colaboradores = await ObtenerColaboradoresAsync(client);
                model.Estados = await ObtenerCatalogoAsync(client, "service_event_status");
                model.TiposCita = await ObtenerCatalogoAsync(client, "service_event_type");
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            for (var dia = inicioCalendario; dia <= finCalendario; dia = dia.AddDays(7))
            {
                var semana = new CitaCalendarWeekModel();
                for (int i = 0; i < 7; i++)
                {
                    var fecha = dia.AddDays(i);
                    semana.Dias.Add(new CitaCalendarDayModel
                    {
                        Fecha = fecha,
                        EsDelMesActual = fecha.Month == mes,
                        EsHoy = fecha.Date == hoy,
                        Citas = citas.Where(c => c.scheduled_start_at.Date == fecha.Date)
                                     .OrderBy(c => c.scheduled_start_at)
                                     .ToList()
                    });
                }
                model.Semanas.Add(semana);
            }

            return View(model);
        }

        #endregion

        #region Crear

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            var client = CrearClienteApi();
            var model = new CitaFormModel
            {
                scheduled_start_at = DateTime.Today.AddHours(9),
                scheduled_end_at = DateTime.Today.AddHours(10)
            };
            await LlenarListasFormularioAsync(client, model);
            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> Crear(CitaFormModel model)
        {
            var client = CrearClienteApi();

            var errorValidacion = ValidarCamposObligatorios(model);
            if (errorValidacion != null)
            {
                ViewBag.Mensaje = errorValidacion;
                await LlenarListasFormularioAsync(client, model);
                return View(model);
            }

            var payload = new
            {
                patient_id = model.patient_id,
                event_type_id = model.event_type_id,
                scheduled_start_at = model.scheduled_start_at,
                scheduled_end_at = model.scheduled_end_at,
                location_type_id = model.location_type_id,
                location_id = model.location_id,
                address_id = model.address_id,
                location_description = model.location_description,
                main_staff_member_id = model.main_staff_member_id,
                summary = model.summary,
                created_by_user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PostAsJsonAsync("Citas/CrearCitaAPI", payload);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "Cita registrada correctamente. Se notificará por correo al paciente y al colaborador.";
                    return RedirectToAction("Index");
                }

                ViewBag.Mensaje = await response.Content.ReadAsStringAsync();

                if (response.StatusCode == HttpStatusCode.Conflict && model.main_staff_member_id.HasValue
                    && model.scheduled_start_at.HasValue && model.scheduled_end_at.HasValue)
                {
                    var disponibilidad = await client.GetAsync(
                        $"Citas/VerificarDisponibilidadAPI?staffMemberId={model.main_staff_member_id}" +
                        $"&scheduledStartAt={model.scheduled_start_at:o}&scheduledEndAt={model.scheduled_end_at:o}");

                    if (disponibilidad.StatusCode == HttpStatusCode.OK)
                    {
                        var disponibilidadModel = await disponibilidad.Content.ReadFromJsonAsync<CitaAvailabilityApiModel>();
                        model.HorariosSugeridos = disponibilidadModel?.suggested_slots ?? new();
                    }
                }
            }
            catch (HttpRequestException)
            {
                ViewBag.Mensaje = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                ViewBag.Mensaje = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            await LlenarListasFormularioAsync(client, model);
            return View(model);
        }

        #endregion

        #region Editar

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            var client = CrearClienteApi();
            try
            {
                var response = await client.GetAsync($"Citas/DetalleCitaAPI/{id}");

                if (response.StatusCode != HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "La cita indicada no existe.";
                    return RedirectToAction("Index");
                }

                var detalle = await response.Content.ReadFromJsonAsync<CitaDetailFullModel>();
                if (detalle?.cita == null)
                    return RedirectToAction("Index");

                var model = new CitaFormModel
                {
                    service_event_id = detalle.cita.id,
                    patient_id = detalle.cita.patient_id,
                    event_type_id = detalle.cita.event_type_id,
                    scheduled_start_at = detalle.cita.scheduled_start_at,
                    scheduled_end_at = detalle.cita.scheduled_end_at,
                    location_type_id = detalle.cita.location_type_id,
                    location_id = detalle.cita.location_id,
                    address_id = detalle.cita.address_id,
                    location_description = detalle.cita.location_description,
                    main_staff_member_id = detalle.cita.main_staff_member_id,
                    summary = detalle.cita.summary
                };

                await LlenarListasFormularioAsync(client, model);
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

        [HttpPost]
        public async Task<IActionResult> Editar(CitaFormModel model)
        {
            var client = CrearClienteApi();

            var errorValidacion = ValidarCamposObligatorios(model);
            if (errorValidacion != null)
            {
                ViewBag.Mensaje = errorValidacion;
                await LlenarListasFormularioAsync(client, model);
                return View(model);
            }

            var payload = new
            {
                service_event_id = model.service_event_id,
                patient_id = model.patient_id,
                event_type_id = model.event_type_id,
                scheduled_start_at = model.scheduled_start_at,
                scheduled_end_at = model.scheduled_end_at,
                location_type_id = model.location_type_id,
                location_id = model.location_id,
                address_id = model.address_id,
                location_description = model.location_description,
                main_staff_member_id = model.main_staff_member_id,
                summary = model.summary,
                reason = model.reason,
                changed_by_user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PutAsJsonAsync("Citas/ActualizarCitaAPI", payload);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "Cita actualizada correctamente.";
                    return RedirectToAction("Detalle", new { id = model.service_event_id });
                }

                ViewBag.Mensaje = await response.Content.ReadAsStringAsync();

                if (response.StatusCode == HttpStatusCode.Conflict && model.main_staff_member_id.HasValue
                    && model.scheduled_start_at.HasValue && model.scheduled_end_at.HasValue)
                {
                    var disponibilidad = await client.GetAsync(
                        $"Citas/VerificarDisponibilidadAPI?staffMemberId={model.main_staff_member_id}" +
                        $"&scheduledStartAt={model.scheduled_start_at:o}&scheduledEndAt={model.scheduled_end_at:o}" +
                        $"&excludeEventId={model.service_event_id}");

                    if (disponibilidad.StatusCode == HttpStatusCode.OK)
                    {
                        var disponibilidadModel = await disponibilidad.Content.ReadFromJsonAsync<CitaAvailabilityApiModel>();
                        model.HorariosSugeridos = disponibilidadModel?.suggested_slots ?? new();
                    }
                }
            }
            catch (HttpRequestException)
            {
                ViewBag.Mensaje = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                ViewBag.Mensaje = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            await LlenarListasFormularioAsync(client, model);
            return View(model);
        }

        #endregion

        #region Detalle y Cancelar

        [HttpGet]
        public async Task<IActionResult> Detalle(int id)
        {
            var client = CrearClienteApi();
            try
            {
                var response = await client.GetAsync($"Citas/DetalleCitaAPI/{id}");

                if (response.StatusCode != HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "La cita indicada no existe.";
                    return RedirectToAction("Index");
                }

                var model = await response.Content.ReadFromJsonAsync<CitaDetailFullModel>();
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

        [HttpPost]
        public async Task<IActionResult> Cancelar(int id, string reason)
        {
            if (string.IsNullOrWhiteSpace(reason))
            {
                TempData["Mensaje"] = "Debes indicar el motivo de la cancelación.";
                return RedirectToAction("Detalle", new { id });
            }

            var client = CrearClienteApi();

            var payload = new
            {
                service_event_id = id,
                reason = reason,
                changed_by_user_id = UsuarioActualId
            };

            try
            {
                var response = await client.PutAsJsonAsync("Citas/CancelarCitaAPI", payload);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    TempData["Mensaje"] = "Cita cancelada correctamente. Se notificará por correo al paciente y al colaborador.";
                }
                else
                {
                    TempData["Mensaje"] = await response.Content.ReadAsStringAsync();
                }
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] = "No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.";
            }
            catch (TaskCanceledException)
            {
                TempData["Mensaje"] = "El servidor tardó demasiado en responder. Intenta de nuevo.";
            }

            return RedirectToAction("Detalle", new { id });
        }

        #endregion
    }

    // Shape minimo para deserializar la respuesta de VerificarDisponibilidadAPI
    // sin depender de un Model dedicado (solo se usa aqui, dentro del controller).
    public class CitaAvailabilityApiModel
    {
        public bool is_available { get; set; }
        public List<CitaSuggestedSlotModel> suggested_slots { get; set; } = new();
    }
}