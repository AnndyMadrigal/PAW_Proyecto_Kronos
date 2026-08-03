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
        private bool EsAdministrador => string.Equals(HttpContext.Session.GetString("RoleName"), "Administrador", StringComparison.OrdinalIgnoreCase);

        private HttpClient CrearClienteApi()
        {
            var client = _http.CreateClient();
            client.BaseAddress = new Uri(_config["Valores:UrlApi"]!);
            var token = HttpContext.Session.GetString("Token");
            if (!string.IsNullOrEmpty(token))
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return client;
        }

        private async Task<List<UserRoleOptionModel>> ObtenerRolesAsync(HttpClient client)
        {
            var response = await client.GetAsync("Users/RolesAPI");
            return response.StatusCode == HttpStatusCode.OK
                ? await response.Content.ReadFromJsonAsync<List<UserRoleOptionModel>>() ?? new()
                : new List<UserRoleOptionModel>();
        }

        [HttpGet]
        public async Task<IActionResult> Index(string? search)
        {
            if (!EsAdministrador) return Forbid();

            var client = CrearClienteApi();
            var response = await client.GetAsync($"Users/ListarUsuariosAPI?search={Uri.EscapeDataString(search ?? string.Empty)}");
            var users = response.StatusCode == HttpStatusCode.OK
                ? await response.Content.ReadFromJsonAsync<List<UserManagementListItemModel>>() ?? new()
                : new List<UserManagementListItemModel>();
            ViewBag.Search = search;
            return View(users);
        }

        [HttpGet]
        public async Task<IActionResult> Editar(int id)
        {
            if (!EsAdministrador) return Forbid();

            var client = CrearClienteApi();
            var response = await client.GetAsync($"Users/UsuarioAPI/{id}");
            if (response.StatusCode != HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "El usuario indicado no existe.";
                return RedirectToAction(nameof(Index));
            }

            var user = await response.Content.ReadFromJsonAsync<UserManagementListItemModel>();
            if (user is null) return RedirectToAction(nameof(Index));
            return View(new UserManagementEditModel
            {
                id = user.id, username = user.username, email = user.email, full_name = user.full_name,
                phone = user.phone, is_active = user.is_active, role_id = user.role_id, role_name = user.role_name,
                Roles = await ObtenerRolesAsync(client)
            });
        }

        [HttpGet]
        public async Task<IActionResult> Crear()
        {
            if (!EsAdministrador) return Forbid();
            var client = CrearClienteApi();
            return View(new UserManagementCreateModel { Roles = await ObtenerRolesAsync(client) });
        }

        [HttpPost]
        public async Task<IActionResult> Crear(UserManagementCreateModel model)
        {
            if (!EsAdministrador) return Forbid();
            var client = CrearClienteApi();
            if (!ModelState.IsValid)
            {
                model.Roles = await ObtenerRolesAsync(client);
                return View(model);
            }

            var response = await client.PostAsJsonAsync("Users/CrearUsuarioAPI", new
            {
                model.username,
                model.email,
                model.full_name,
                model.phone,
                role_id = model.role_id!.Value
            });

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Usuario creado correctamente.";
                return RedirectToAction(nameof(Index));
            }

            ViewBag.Mensaje = await response.Content.ReadAsStringAsync();
            model.Roles = await ObtenerRolesAsync(client);
            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> Editar(UserManagementEditModel model)
        {
            if (!EsAdministrador) return Forbid();

            var client = CrearClienteApi();
            if (!ModelState.IsValid)
            {
                model.Roles = await ObtenerRolesAsync(client);
                return View(model);
            }

            var response = await client.PutAsJsonAsync("Users/ActualizarPerfilAPI", new
            {
                user_id = model.id,
                role_id = model.role_id!.Value,
                model.is_active,
                model.confirm_pending_appointments
            });

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Perfil actualizado correctamente. El usuario debera iniciar sesion nuevamente.";
                return RedirectToAction(nameof(Index));
            }

            if (response.StatusCode == HttpStatusCode.Conflict)
            {
                var warning = await response.Content.ReadFromJsonAsync<UserManagementUpdateResponseModel>();
                model.requires_confirmation = warning?.requires_confirmation ?? false;
                model.pending_appointment_count = warning?.pending_appointment_count ?? 0;
                ViewBag.Mensaje = warning?.message;
            }
            else
            {
                ViewBag.Mensaje = await response.Content.ReadAsStringAsync();
            }

            model.Roles = await ObtenerRolesAsync(client);
            return View(model);
        }
    }
}
