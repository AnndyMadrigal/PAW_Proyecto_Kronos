using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
using PAW_Proyecto_Kronos.Models;
using System.Net;
using System.Net.Http.Headers;

namespace PAW_Proyecto_Kronos.Controllers
{
    public class ProfileController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        [ActiveSession]
        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }
        #region ChangePassword
        [ActiveSession]
        [HttpPost]
        public IActionResult ChangePassword(UserModel model)
        {
            model.id = HttpContext.Session.GetInt32("Consecutivo")!.Value;

            using var client = _http.CreateClient();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
            var url = _config["Valores:UrlApi"] + "Profile/ChangePasswordAPI";
            var response = client.PutAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Contraseña actualizada correctamente. Inicia sesión de nuevo.";
                return RedirectToAction("Logout", "Auth");
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                TempData["MensajeError"] = response.Content.ReadAsStringAsync().Result;
                return RedirectToAction("Index");
            }
            else
            {
                TempData["MensajeError"] = "Error al intentar actualizar la contraseña.";
                return RedirectToAction("Index");
            }
        }
        #endregion

        #region UpdateProfile
        [ActiveSession]
        [HttpPost]
        public IActionResult UpdateProfile(UserModel model)
        {
            if (!string.IsNullOrWhiteSpace(model.username))
            {
                HttpContext.Session.SetString("Name", model.username);
            }
            TempData["MensajeExito"] = "Información del perfil actualizada con éxito.";
            return RedirectToAction("Index");
        }
        #endregion

        #region RegisterUser
        [HttpGet]
        public IActionResult RegisterUser()
        {
            return View();
        }
        
        [HttpPost]
        public IActionResult RegisterUser(UserModel model)

        {
            model.password = BCrypt.Net.BCrypt.HashPassword(model.password);

            using var client = _http.CreateClient();
            var url = _config["Valores:UrlApi"] + "Auth/RegisterUserAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Usuario registrado correctamente.";
                return RedirectToAction("Login", "Auth");
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
                return View();
            }
            throw new Exception("Error al registrar el usuario");
        }
        #endregion

        #region RecoverPassword
        [HttpGet]
        public IActionResult RecoverPassword()
        {
            return View();
        }

        [HttpPost]
        public IActionResult RecoverPassword(UserModel model)
        {
            using var client = _http.CreateClient();
            var url = _config["Valores:UrlApi"] + "Auth/RecoverPasswordAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = response.Content.ReadAsStringAsync().Result;
                return RedirectToAction("Login", "Auth");
            }
            else if (response.StatusCode == HttpStatusCode.NotFound)
            {
                TempData["Mensaje"] = response.Content.ReadAsStringAsync().Result;
                return View();
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                TempData["Mensaje"] = response.Content.ReadAsStringAsync().Result;
                return View();
            }
            throw new Exception("Error al recuperar la contraseña");
        }
        #endregion

        #region Logout
        [HttpGet]
        public IActionResult Logout()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Login", "Auth");
        }
        #endregion
    }
}   