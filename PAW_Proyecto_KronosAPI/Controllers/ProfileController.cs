using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_Kronos.Models;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
using Microsoft.AspNetCore.Authorization;

namespace PAW_Proyecto_KronosAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class ProfileController(IConfiguration _config, IHelpersService _helpers) : Controller
    {

        [HttpPut("ChangePasswordAPI")]
        public IActionResult ChangePasswordAPI(ChangePasswordRequestModel model)
        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {
                model.password = BCrypt.Net.BCrypt.HashPassword(model.password);

                var parameters = new DynamicParameters();
                parameters.Add("@id", model.id);
                parameters.Add("@password", model.password);

                var response = context.Execute("spUpdatePassword", parameters);
                if (response > 0)
                {
                    return Ok("Contraseña actualizada correctamente");
                }
                else
                {
                    return BadRequest("No se pudo actualizar la contraseña");
                }
            }
        }

        [HttpGet("UserInfoAPI")]
        public IActionResult UserInfoAPI(int userId)

        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {

                var parameters = new DynamicParameters();
                parameters.Add("@id", userId);
                
                var response = context.QueryFirstOrDefault<UserResponseModel>("spGetUserByID", parameters);
                if (response != null)
                {
                    return Ok(response);
                    
                } else
                {
                    return NotFound("No se ha podido obtener la informacion del usuario");
                }

            }
        }

        [HttpPost("RecoverPasswordAPI")]
        public async Task<IActionResult> RecoverPasswordAPI(UserEmailRequestModel model)

        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {

                //1. validar primero que el correo exista
                var parameters = new DynamicParameters();
                parameters.Add("@email", model.email);
                
                var emailValidation = context.QueryFirstOrDefault<UserResponseModel>("spValidateEmail", parameters);
                
                if (emailValidation == null)
                    return NotFound("El correo electronico no se encuentra registrado");

                //2. generar contraseña aleatoria
                var tempPassword = _helpers.GenerateRandomPassword();
                var tempPasswordHash = BCrypt.Net.BCrypt.HashPassword(tempPassword);
                
                parameters = new DynamicParameters();
                parameters.Add("@id", emailValidation.id);
                parameters.Add("@password", tempPasswordHash);

                var updatePassword = context.Execute("spUpdatePassword", parameters);
                if (updatePassword > 0)
                {

                    //3. enviar correo electronico con la nueva contraseña
                    string route = Path.Combine(AppContext.BaseDirectory, "Templates", "RecoverPassword.html");
                    string htmlTemplate = System.IO.File.ReadAllText(route);

                    htmlTemplate = htmlTemplate.Replace("{{TEMP}}", tempPassword);
                    htmlTemplate = htmlTemplate.Replace("{{Name}}", emailValidation.full_name);
                    htmlTemplate = htmlTemplate.Replace("{{Year}}", DateTime.Now.Year.ToString());

                    await _helpers.SendEmail(emailValidation.email, "Recuperacion de contraseña", htmlTemplate);
                    
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