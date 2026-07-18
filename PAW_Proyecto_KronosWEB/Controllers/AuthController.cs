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
        #region Login
        [HttpPost]
        public IActionResult Login(UserModel model)
        {
            using var client = _http.CreateClient();
            var url = _config["Valores:UrlApi"] + "Auth/LoginAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var data = response.Content.ReadFromJsonAsync<UserModel>().Result;

                HttpContext.Session.SetString("Authenticated", "1");
                HttpContext.Session.SetString("Name", data!.username);
                HttpContext.Session.SetInt32("Consecutivo", data!.id);
                HttpContext.Session.SetString("Token", data!.Token);
                HttpContext.Session.SetInt32("role_id", data!.role_id);
                HttpContext.Session.SetString("RoleName", data!.RoleName);

                return RedirectToAction("Index", "Home");
            }
            else if (response.StatusCode == HttpStatusCode.NotFound)
            {
                //Mostrar este mensaje en la vista y que al recargar la pagina no se pierda
                TempData["Mensaje"] = response.Content.ReadAsStringAsync().Result;
                return View(model);
            }
            throw new Exception("Error al iniciar sesión");
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
                TempData["Mensaje"] = "Se han enviado instrucciones para restablecer su contraseña.";
                return RedirectToAction("Login", "Auth");
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
                return View();
            }
            throw new Exception("Error al recuperar la contraseña");
        }
    }
}   