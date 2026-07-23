using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
using PAW_Proyecto_Kronos.Models;
using System.Net;
using System.Net.Http.Headers;

namespace PAW_Proyecto_Kronos.Controllers
{
    [ActiveSession]
    public class UsersController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        private HttpClient CrearClienteApi()
        {
            var client = _http.CreateClient();
            client.BaseAddress = new Uri(_config["Valores:UrlApi"]!);
            var token = HttpContext.Session.GetString("Token");
            if (!string.IsNullOrEmpty(token))
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            }
            return client;
        }

        private bool EsAdministrador()
        {
            return string.Equals(HttpContext.Session.GetString("RoleName"), "Administrador", StringComparison.OrdinalIgnoreCase);
        }

        [HttpGet]
        public async Task<IActionResult> Index(string? q)
        {
            if (!EsAdministrador())
            {
                return Forbid();
            }

            using var client = CrearClienteApi();
            var url = string.IsNullOrWhiteSpace(q)
                ? "Users/SearchAPI"
                : $"Users/SearchAPI?searchTerm={Uri.EscapeDataString(q)}";

            var response = await client.GetAsync(url);
            var data = response.IsSuccessStatusCode
                ? await response.Content.ReadFromJsonAsync<List<UserModel>>() ?? new List<UserModel>()
                : new List<UserModel>();

            ViewBag.Query = q ?? string.Empty;
            if (!response.IsSuccessStatusCode && response.StatusCode == HttpStatusCode.Unauthorized)
            {
                TempData["MensajeError"] = "Tu sesión ya no es válida. Inicia sesión nuevamente.";
                return RedirectToAction("Logout", "Auth");
            }

            return View(data);
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            if (!EsAdministrador())
            {
                return Forbid();
            }

            using var client = CrearClienteApi();
            var response = await client.GetAsync($"Users/DetailAPI?id={id}");
            if (response.StatusCode == HttpStatusCode.Unauthorized)
            {
                TempData["MensajeError"] = "Tu sesión ya no es válida. Inicia sesión nuevamente.";
                return RedirectToAction("Logout", "Auth");
            }

            if (!response.IsSuccessStatusCode)
            {
                TempData["MensajeError"] = await response.Content.ReadAsStringAsync();
                return RedirectToAction("Index");
            }

            var model = await response.Content.ReadFromJsonAsync<UserModel>() ?? new UserModel();

            var precheck = await client.GetAsync($"Users/PrecheckAPI?id={model.id}&roleName={Uri.EscapeDataString(model.role_name)}&isActive={model.is_active}");
            if (precheck.IsSuccessStatusCode)
            {
                var info = await precheck.Content.ReadFromJsonAsync<UserModel>();
                if (info != null)
                {
                    model.pending_appointments_count = info.pending_appointments_count;
                    model.has_pending_appointments = info.has_pending_appointments;
                    model.is_unique_admin = info.is_unique_admin;
                    model.warning_message = info.warning_message;
                    model.profile_stamp_at = info.profile_stamp_at;
                }
            }

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(UserModel model)
        {
            if (!EsAdministrador())
            {
                return Forbid();
            }

            if (string.IsNullOrWhiteSpace(model.role_name))
            {
                ModelState.AddModelError(nameof(model.role_name), "Debes seleccionar un perfil.");
            }

            if (!ModelState.IsValid)
            {
                using var reloadClient = CrearClienteApi();
                var reload = await reloadClient.GetAsync($"Users/DetailAPI?id={model.id}");
                if (reload.IsSuccessStatusCode)
                {
                    var current = await reload.Content.ReadFromJsonAsync<UserModel>() ?? new UserModel();
                    current.allow_pending_appointments = model.allow_pending_appointments;
                    current.role_name = model.role_name;
                    current.is_active = model.is_active;
                    return View(current);
                }

                return View(model);
            }

            using var client = CrearClienteApi();
            var payload = new
            {
                id = model.id,
                role_name = model.role_name,
                is_active = model.is_active,
                allow_pending_appointments = model.allow_pending_appointments
            };

            var response = await client.PutAsJsonAsync("Users/UpdateProfileAPI", payload);
            var message = await response.Content.ReadAsStringAsync();

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = message;
                return RedirectToAction(nameof(Index));
            }

            if (response.StatusCode == HttpStatusCode.Conflict)
            {
                TempData["MensajeError"] = message;
            }
            else if (response.StatusCode == HttpStatusCode.Unauthorized)
            {
                TempData["MensajeError"] = "Tu sesión ya no es válida. Inicia sesión nuevamente.";
                return RedirectToAction("Logout", "Auth");
            }
            else
            {
                TempData["MensajeError"] = string.IsNullOrWhiteSpace(message)
                    ? "No se pudo actualizar el perfil del usuario."
                    : message;
            }

            return RedirectToAction(nameof(Edit), new { id = model.id });
        }
    }
}
