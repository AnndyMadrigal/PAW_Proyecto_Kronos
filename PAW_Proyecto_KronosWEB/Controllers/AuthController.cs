using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Models;
using System.Net;

namespace PAW_Proyecto_Kronos.Controllers
{
    public class AuthController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Login(UserModel model)
        {
            using var client = _http.CreateClient();
            var url = _config["Valores:UrlApi"] + "Auth/LoginAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                return RedirectToAction("Index", "Home");
            }
            else if (response.StatusCode == HttpStatusCode.NotFound)
            {
                ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
                return View();
            }
            throw new Exception("Error al iniciar sesión");
        }
        #region RegisterUser
        [HttpGet]
        public IActionResult RegisterUser()
        {
            return View();
        }
        
        [HttpPost]
        public IActionResult RegisterUser(UserModel model)

        {
            using var client = _http.CreateClient();
            var url = _config["Valores:UrlApi"] + "Auth/RegisterUserAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
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

        [HttpGet]
        public IActionResult RecoverPassword()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult RecoverPassword(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                ModelState.AddModelError(string.Empty, "Ingresa un correo electrónico válido.");
                return View();
            }

            TempData["SuccessMessage"] = "Si el correo existe, recibirás instrucciones para restablecer tu contraseña.";

            return RedirectToAction(nameof(RecoverPassword));
        }
    }
}