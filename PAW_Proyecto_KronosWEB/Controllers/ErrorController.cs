using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Models;

namespace PAW_Proyecto_Kronos.Controllers
{
    public class ErrorController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        [HttpGet]
        public async Task<IActionResult> CapturarError()
        {
            var feature = HttpContext.Features.Get<IExceptionHandlerPathFeature>();
            var ex = feature?.Error;

            try
            {
                var client = _http.CreateClient();
                var url = _config["Valores:UrlApi"] + "Error/RegistrarErrorWebAPI";

                var payload = new
                {
                    user_id = HttpContext.Session.GetInt32("Consecutivo"),
                    source = "WEB " + (feature?.Path ?? HttpContext.Request.Path.Value),
                    message = ex?.Message ?? "Error desconocido",
                    detail = ex?.ToString()
                };

                var response = await client.PostAsJsonAsync(url, payload);
                if (response.IsSuccessStatusCode)
                {
                    var resultado = await response.Content.ReadFromJsonAsync<ErrorLogResultModel>();
                    ViewBag.ReferenceId = resultado?.error_log_id;
                }
            }
            catch
            {
                //Sin conexion a la API: no hay donde dejar el registro, pero
                //el usuario igual debe ver la pantalla de error.
            }

            return View();
        }
    }
}
