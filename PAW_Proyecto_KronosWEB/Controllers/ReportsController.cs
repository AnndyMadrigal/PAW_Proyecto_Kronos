using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Filter;
namespace PAW_Proyecto_Kronos.Controllers;
[ActiveSession] public class ReportsController:Controller { public IActionResult Index()=>View(); }
