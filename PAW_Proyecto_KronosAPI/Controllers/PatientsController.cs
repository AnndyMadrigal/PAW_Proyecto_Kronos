using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;

namespace PAW_Proyecto_KronosAPI.Controllers;

[Authorize(Roles = "Administrador,Médico,Enfermería,Administrativo")]
[Route("api/[controller]")]
[ApiController]
public class PatientsController(IConfiguration config, IHelpersService helpers) : ControllerBase
{
    private SqlConnection Connection() => new(config["ConnectionStrings:DefaultConnection"]);

    [HttpGet]
    public IActionResult Search(string? search)
    {
        using var connection = Connection();
        return Ok(connection.Query<PatientSearchResponseModel>("patient_sp_patients_search", new { search }, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpGet("{id:int}")]
    public IActionResult Get(int id)
    {
        using var connection = Connection();
        var patient = connection.QueryFirstOrDefault<PatientDetailResponseModel>("patient_sp_patients_get_detail", new { patient_id = id }, commandType: System.Data.CommandType.StoredProcedure);
        return patient is null ? NotFound("El paciente indicado no existe.") : Ok(patient);
    }

    [HttpPost]
    public IActionResult Create(PatientRegisterRequestModel model)
    {
        if (string.IsNullOrWhiteSpace(model.first_name) || string.IsNullOrWhiteSpace(model.last_name))
            return BadRequest("El nombre y el apellido del paciente son obligatorios.");

        using var connection = Connection();
        return Ok(connection.QueryFirst("patient_sp_orc_patients_register", new
        {
            model.first_name, model.last_name, model.identification_number, model.birth_date, model.gender_id,
            model.phone, model.email, model.address_id, contacts_json = (string?)null,
            model.open_medical_record, created_by_user_id = helpers.ObtenerConsecutivoToken()
        }, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpPut("{id:int}")]
    public IActionResult Update(int id, PatientUpdateRequestModel model)
    {
        if (string.IsNullOrWhiteSpace(model.first_name) || string.IsNullOrWhiteSpace(model.last_name))
            return BadRequest("El nombre y el apellido del paciente son obligatorios.");

        using var connection = Connection();
        return Ok(connection.QueryFirst("patient_sp_patients_update", new
        {
            patient_id = id, model.first_name, model.last_name, model.identification_number,
            model.birth_date, model.gender_id, model.phone, model.email
        }, commandType: System.Data.CommandType.StoredProcedure));
    }
}
