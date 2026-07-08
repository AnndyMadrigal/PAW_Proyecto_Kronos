using Microsoft.AspNetCore.Mvc;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    public class AuthController : Controller
    {
        public IActionResult RegisterUser()
        {
            return View();
        }
    }
}
