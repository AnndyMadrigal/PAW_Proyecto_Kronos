using Microsoft.AspNetCore.Mvc;
using PAW_Proyecto_KronosAPI.Models;
using Microsoft.Data.SqlClient;
using Dapper;
using Microsoft.Extensions.FileSystemGlobbing.Internal.PathSegments;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController(IConfiguration _config) : Controller
    {
        
        [HttpPost]
        public IActionResult RegisterUserAPI(UserRequestModel model)

        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {

                var parameters = new DynamicParameters();
                parameters.Add("@username", model.username);
                parameters.Add("@email", model.email);
                parameters.Add("@password", model.password);
                parameters.Add("@full_name", model.full_name);
                parameters.Add("@phone", model.phone);

                var response = context.Execute("spRegisterUser", parameters);
                if (response == 0)
                {
                    return BadRequest("Error al registrar el usuario");
                } else
                {
                    return Ok("Usuario registrado correctamente");
                }

            }
        }
    }
}