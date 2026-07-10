using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Models;

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
        public IActionResult Login(string email, string password)
        {
            return RedirectToAction("Index");
        }

        [HttpGet]
        public IActionResult RegisterUser()
        {
            return View();
        }

        [HttpPost]
        public IActionResult RegisterUser(UserModel model)

        { using (var client = _http.CreateClient())
            {
                var url = _config["Valores:UrlApi"] + "Auth/RegisterUserAPI";

                var response = client.PostAsJsonAsync(url, model).Result;
                
                ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
                return RedirectToAction("Login");
            }
        }

public IActionResult Index()
        {
            return View();
        }

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