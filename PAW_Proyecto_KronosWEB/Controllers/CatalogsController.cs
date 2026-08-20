using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
namespace PAW_Proyecto_Kronos.Controllers;
[ActiveSession] public class CatalogsController:Controller { public IActionResult Index()=>View(); }
