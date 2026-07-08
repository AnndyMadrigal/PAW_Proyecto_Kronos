//using Microsoft.AspNetCore.Mvc;
//using PAW_Proyecto_Kronos.Models;
//using System.Diagnostics;

//namespace PAW_Proyecto_Kronos.Controllers
//{
//    public class HomeController : Controller
//    {
//        [HttpGet]
//        public IActionResult Login()
//        {
//            return View();
//        }

//        [HttpPost]
//        public IActionResult Login(string email, string password)
//        {
//            return RedirectToAction("Index");
//        }

//        public IActionResult Register()
//        {
//            return View();
//        }

//        public IActionResult Index()
//        {
//            return View();
//        }

//        [HttpGet]
//        public IActionResult RecoverPassword()
//        {
//            return View();
//        }

//        [HttpPost]
//        [ValidateAntiForgeryToken]
//        public IActionResult RecoverPassword(string email)
//        {
//            if (string.IsNullOrWhiteSpace(email))
//            {
//                ModelState.AddModelError(string.Empty, "Ingresa un correo electrónico válido.");
//                return View();
//            }

//            TempData["SuccessMessage"] = "Si el correo existe, recibirás instrucciones para restablecer tu contraseña.";

//            return RedirectToAction(nameof(RecoverPassword));
//        }

        
    

//        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
//        public IActionResult Error()
//        {
//            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
//        }
//    }
//}