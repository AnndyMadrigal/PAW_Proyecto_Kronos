using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_Kronos.Models;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
using Microsoft.AspNetCore.Authorization;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    [AllowAnonymous]
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController(IConfiguration _config, IHelpersService _helpers) : Controller
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
                if (response != null && BCrypt.Net.BCrypt.Verify(model.password, response.password))
                {
                    response.Token = _helpers.GenerateToken(response.id);
                    return Ok(response);
                }
                else
                {
                    return NotFound("El correo o contraseña son incorrectos");
                    
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
                if (response > 0)
                {
                    return Ok("Usuario registrado correctamente");
                    
                } else
                {
                    return BadRequest("El correo electronico ya se encuentra registrado");
                }

            }
        }
    }
}