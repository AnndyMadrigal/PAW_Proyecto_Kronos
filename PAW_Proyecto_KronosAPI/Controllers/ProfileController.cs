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

        [HttpPut("UpdateUserInfoAPI")]
        public IActionResult UpdateUserInfoAPI(UserInfoUpdateRequestModel model)
        {
            using (var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]))
            {
               
                var parameters = new DynamicParameters();
                parameters.Add("@id", model.id);
                parameters.Add("@username", model.username);
                parameters.Add("@full_name", model.full_name);
                parameters.Add("@phone", model.phone);

                var response = context.Execute("spUpdateUserInfo", parameters);
                if (response > 0)
                {
                    return Ok("Información del usuario actualizada correctamente");
                }
                else
                {
                    return BadRequest("No se pudo actualizar la información del usuario");
                }
            }
        }
    }
}