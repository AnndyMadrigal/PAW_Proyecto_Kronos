using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_Kronos.Models;
using System.Diagnostics;

namespace PAW_Proyecto_Kronos.Controllers
{
    public class HomeController : Controller
    {


        public IActionResult Index()
        {
            return View();
        }

    }
}