using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
using PAW_Proyecto_Kronos.Models;
using System.Net.Http.Headers;

namespace PAW_Proyecto_Kronos.Controllers;

[ActiveSession]
public class InventoryController(IHttpClientFactory http, IConfiguration config) : Controller
{
    private HttpClient Client()
    {
        var client = http.CreateClient();
        client.BaseAddress = new Uri(config["Valores:UrlApi"]!);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
        return client;
    }

    [HttpGet]
    public async Task<IActionResult> Index(string? search)
    {
        using var client = Client();
        var response = await client.GetAsync("Inventory/Stock");
        ViewBag.Search = search;
        if (response.IsSuccessStatusCode)
        {
            var stock = await response.Content.ReadFromJsonAsync<List<InventoryStockViewModel>>() ?? [];
            if (!string.IsNullOrWhiteSpace(search)) stock = stock.Where(x => x.name.Contains(search, StringComparison.OrdinalIgnoreCase) || x.category_name.Contains(search, StringComparison.OrdinalIgnoreCase)).ToList();
            return View(stock);
        }
        TempData["MensajeError"] = "No se pudo cargar el inventario.";
        return View(new List<InventoryStockViewModel>());
    }

    private bool IsAdministrator() => string.Equals(HttpContext.Session.GetString("RoleName"), "Administrador", StringComparison.OrdinalIgnoreCase);
    [HttpGet] public async Task<IActionResult> Crear() => IsAdministrator() ? View("Editar", await LoadReferences(new InventoryItemViewModel())) : Forbid();
    [HttpGet] public IActionResult Movimientos() => View();
    [HttpGet]
    public async Task<IActionResult> Editar(int id)
    {
        if (!IsAdministrator()) return Forbid();
        using var client = Client(); var response = await client.GetAsync($"Inventory/Items/{id}");
        if (!response.IsSuccessStatusCode) { TempData["MensajeError"] = "El producto indicado no existe."; return RedirectToAction(nameof(Index)); }
        return View(await LoadReferences((await response.Content.ReadFromJsonAsync<InventoryItemViewModel>())!));
    }

    [HttpPost]
    public async Task<IActionResult> Guardar(InventoryItemViewModel model)
    {
        if (!IsAdministrator()) return Forbid();
        if (!ModelState.IsValid) return View("Editar", await LoadReferences(model));
        using var client = Client();
        var response = model.id == 0 ? await client.PostAsJsonAsync("Inventory/Items", model) : await client.PutAsJsonAsync($"Inventory/Items/{model.id}", model);
        if (response.IsSuccessStatusCode) { TempData["Mensaje"] = model.id == 0 ? "Producto creado correctamente." : "Producto actualizado correctamente."; return RedirectToAction(nameof(Index)); }
        ModelState.AddModelError(string.Empty, await response.Content.ReadAsStringAsync());
        return View("Editar", await LoadReferences(model));
    }

    [HttpPost]
    public async Task<IActionResult> Eliminar(int id)
    {
        if (!IsAdministrator()) return Forbid();
        using var client = Client(); var response = await client.DeleteAsync($"Inventory/Items/{id}");
        TempData[response.IsSuccessStatusCode ? "Mensaje" : "MensajeError"] = response.IsSuccessStatusCode ? "Producto eliminado correctamente." : await response.Content.ReadAsStringAsync();
        return RedirectToAction(nameof(Index));
    }

    private async Task<InventoryItemViewModel> LoadReferences(InventoryItemViewModel model)
    {
        using var client = Client(); var response = await client.GetAsync("Inventory/References");
        if (response.IsSuccessStatusCode) { var data = await response.Content.ReadFromJsonAsync<InventoryReferencesViewModel>(); ViewBag.Categories = data?.categories ?? []; ViewBag.Units = data?.units ?? []; }
        return model;
    }
}
