using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;

namespace PAW_Proyecto_Kronos.Controllers;

[ActiveSession]
public class ServicesController : Controller
{
    [HttpGet]
    public IActionResult Index() => View();
}
