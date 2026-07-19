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

        [HttpPost("RecoverPasswordAPI")]
        public IActionResult RecoverPasswordAPI(UserEmailRequestModel model)

        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {

                //1. validar primero que el correo exista
                var parameters = new DynamicParameters();
                parameters.Add("@email", model.email);
                
                var emailValidation = context.QueryFirstOrDefault<UserEmailRequestModel>("spValidateEmail", parameters);
                
                if (emailValidation == null)
                    return NotFound("El correo electronico no se encuentra registrado");

                //2. generar contraseña aleatoria
                var tempPassword = _helpers.GenerateRandomPassword();
                var tempPasswordHash = BCrypt.Net.BCrypt.HashPassword(tempPassword);
                
                parameter = new DynamicParameters();
                parameter.Add("@id", emailValidation.id);
                parameter.Add("@password", tempPasswordHash);

                var updatePassword = context.Execute("spUpdatePassword", parameter);
                if (updatePassword > 0)
                {

                    //3. enviar correo electronico con la nueva contraseña
                    string route = Path.Combine(AppContext.BaseDirectory, "Templates", "RecoverPassword.html");
                    string htmlTemplate = System.IO.File.ReadAllText(route);

                    htmlTemplate = htmlTemplate.Replace("{{TEMP}}", tempPassword);
                    htmlTemplate = htmlTemplate.Replace("{{Name}}", emailValidation.full_name);
                    htmlTemplate = htmlTemplate.Replace("{{Year}}", DateTime.Now.Year.ToString());

                    await _helpers.SendMailAsync(emailValidation.email, "Recuperacion de contraseña", htmlTemplate);
                    
                    return Ok("Se ha enviado un correo electronico con la nueva contraseña");
                }
                else
                {
                    return BadRequest("Error al recuperar la contraseña");
                }

            }
        }
    }
}