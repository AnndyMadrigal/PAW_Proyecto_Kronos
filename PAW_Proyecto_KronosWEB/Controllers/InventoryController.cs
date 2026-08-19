using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
using PAW_Proyecto_Kronos.Models;
using System.Net;
using System.Net.Http.Headers;

namespace PAW_Proyecto_Kronos.Controllers
{
    public class InventoryController(IHttpClientFactory _http, IConfiguration _config) : Controller
    {
        [ActiveSession]

        #region Index
        [HttpGet]
        public IActionResult Index(string? search)
        {
            using var client = _http.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

            var url = _config["Valores:UrlApi"] + "Inventory/ListarInventarioAPI";
            if (!string.IsNullOrWhiteSpace(search))
            {
                url += "?search=" + Uri.EscapeDataString(search.Trim());
            }

            var response = client.GetAsync(url).Result;

            if (response.IsSuccessStatusCode)
            {
                var data = response.Content.ReadFromJsonAsync<List<InventoryModel>>().Result;
                ViewBag.Search = search;
                return View(data ?? new List<InventoryModel>());
            }

            TempData["MensajeError"] = "Error al obtener el inventario.";
            return View(new List<InventoryModel>());
        }
        #endregion

        #region Crear
        [HttpGet]
        public IActionResult Crear()
        {
            var model = new InventoryModel();
            CargarCatalogos(model);
            return View(model);
        }

        [HttpPost]
        public IActionResult Crear(InventoryModel model)
        {
            using var client = _http.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

            var url = _config["Valores:UrlApi"] + "Inventory/CrearItemAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Producto creado correctamente.";
                return RedirectToAction("Index");
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
                CargarCatalogos(model);
                return View(model);
            }
            else
            {
                ViewBag.Mensaje = "Error al registrar el producto.";
                CargarCatalogos(model);
                return View(model);
            }
        }
        #endregion

        #region Editar
        [HttpGet]
        public IActionResult Editar(int id)
        {
            using var client = _http.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

            var url = _config["Valores:UrlApi"] + "Inventory/ItemAPI/" + id;
            var response = client.GetAsync(url).Result;

            if (response.IsSuccessStatusCode)
            {
                var model = response.Content.ReadFromJsonAsync<InventoryModel>().Result;
                if (model != null)
                {
                    CargarCatalogos(model);
                    return View(model);
                }
            }

            TempData["MensajeError"] = "El producto indicado no existe.";
            return RedirectToAction("Index");
        }

        [HttpPost]
        public IActionResult Editar(InventoryModel model)
        {
            using var client = _http.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

            var url = _config["Valores:UrlApi"] + "Inventory/ActualizarItemAPI/" + model.id;
            var response = client.PutAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Producto actualizado correctamente.";
                return RedirectToAction("Index");
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
                CargarCatalogos(model);
                return View(model);
            }
            else
            {
                ViewBag.Mensaje = "Error al actualizar el producto.";
                CargarCatalogos(model);
                return View(model);
            }
        }
        #endregion

        #region Eliminar
        [HttpPost]
        public IActionResult Eliminar(InventoryModel model)
        {
            using var client = _http.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

            var url = _config["Valores:UrlApi"] + "Inventory/EliminarItemAPI/" + model.id;
            var response = client.DeleteAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                TempData["Mensaje"] = "Producto eliminado correctamente.";
            }
            else if (response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == HttpStatusCode.NotFound)
            {
                TempData["MensajeError"] = response.Content.ReadAsStringAsync().Result;
            }
            else
            {
                TempData["MensajeError"] = "Error al eliminar el producto.";
            }

            return RedirectToAction("Index");
        }
        #endregion

        #region Helpers
        private void CargarCatalogos(InventoryModel model)
        {
            using var client = _http.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

            var catUrl = _config["Valores:UrlApi"] + "Inventory/CategoriasAPI";
            var catResponse = client.GetAsync(catUrl).Result;
            if (catResponse.IsSuccessStatusCode)
            {
                model.Categories = catResponse.Content.ReadFromJsonAsync<List<CategoryModel>>().Result ?? new();
            }

            var unitUrl = _config["Valores:UrlApi"] + "Inventory/UnidadesAPI";
            var unitResponse = client.GetAsync(unitUrl).Result;
            if (unitResponse.IsSuccessStatusCode)
            {
                model.Units = unitResponse.Content.ReadFromJsonAsync<List<UnitModel>>().Result ?? new();
            }
        }
        #endregion
    }
}
