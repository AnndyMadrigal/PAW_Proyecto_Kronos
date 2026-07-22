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

        #region UserInfo
        [ActiveSession]
        [HttpGet]
        public IActionResult UserInfo()
        {
            var userId = HttpContext.Session.GetInt32("Consecutivo")!.Value;

            using var client = _http.CreateClient();

            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
            var url = _config["Valores:UrlApi"] + "Profile/UserInfoAPI?userId=" + userId;
            var response = client.GetAsync(url).Result;

            if (response.IsSuccessStatusCode)
            {
                var data = response.Content.ReadFromJsonAsync<UserModel>().Result;
                
                return View("UserInfo", data);
            }

            TempData["MensajeError"] = "Error al obtener la información del usuario.";
            return View("UserInfo", new UserModel());
        }
        #endregion

    }
} 