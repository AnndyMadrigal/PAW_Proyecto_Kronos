using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;

namespace PAW_Proyecto_Kronos.Controllers;

[ActiveSession]
public class PatientsController : Controller
{
    public IActionResult Index() => View();
    [HttpGet] public IActionResult Crear() => View();
    [HttpGet] public IActionResult Editar(int id) => View(model: id);
}
