using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_Kronos.Models;
using PAW_Proyecto_KronosAPI.Models;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController(IConfiguration _config) : Controller
    {

        [HttpPost("LoginAPI")]
        public IActionResult LoginAPI(UserLoginRequestModel model)
        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {

                var parameters = new DynamicParameters();
                parameters.Add("@email", model.email);
                parameters.Add("@password", model.password);

                var response = context.QueryFirstOrDefault<UserResponseModel>("spLoginUser", parameters);
                if (response == null)
                {
                    return NotFound("El correo o contraseña son incorrectos");
                }
                else
                {
                    return Ok(response);
                }

            }
        }

        [HttpPost("RegisterUserAPI")]
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

                var response = context.Execute("spRegisterBasicUser", parameters);
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