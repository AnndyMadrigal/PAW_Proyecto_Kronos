using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;

namespace PAW_Proyecto_KronosAPI.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class StaffController(IConfiguration config) : ControllerBase
{
    private SqlConnection Connection() => new(config["ConnectionStrings:DefaultConnection"]);
    [HttpGet] public IActionResult Search(string? search) { using var c=Connection(); return Ok(c.Query<StaffSearchResponseModel>("staff_sp_members_search",new {search,staff_role_id=(int?)null},commandType:System.Data.CommandType.StoredProcedure)); }
    [HttpGet("{id:int}")] public IActionResult Get(int id) { using var c=Connection(); var member=c.Query<StaffSearchResponseModel>("staff_sp_members_search",new {search=(string?)null,staff_role_id=(int?)null},commandType:System.Data.CommandType.StoredProcedure).FirstOrDefault(x=>x.id==id); return member is null ? NotFound("El colaborador indicado no existe.") : Ok(member); }
    [HttpGet("References")] public IActionResult References() { using var c=Connection(); using var m=c.QueryMultiple("staff_sp_reference_data_get",commandType:System.Data.CommandType.StoredProcedure); return Ok(new StaffReferenceDataModel { roles=m.Read<CatalogItemResponseModel>().ToList(), specialties=m.Read<CatalogItemResponseModel>().ToList() }); }
    [HttpPost] public IActionResult Create(StaffMemberRequestModel m) => Save(m);
    [HttpPut("{id:int}")] public IActionResult Update(int id, StaffMemberRequestModel m) {m.id=id; return Save(m);}
    [HttpDelete("{id:int}")] public IActionResult Delete(int id) {using var c=Connection(); return Ok(c.QueryFirst("staff_sp_member_delete",new{id},commandType:System.Data.CommandType.StoredProcedure));}
    [HttpGet("{id:int}/Availability")] public IActionResult Availability(int id, DateTime? from, DateTime? to) {using var c=Connection();return Ok(c.Query<StaffAvailabilityResponseModel>("staff_sp_availability_list",new{staff_member_id=id,date_from=from,date_to=to},commandType:System.Data.CommandType.StoredProcedure));}
    [HttpPost("Availability")] public IActionResult SaveAvailability(StaffAvailabilityRequestModel m) {if(m.end_time<=m.start_time)return BadRequest("La hora final debe ser posterior a la inicial.");using var c=Connection();return Ok(c.QueryFirst("staff_sp_availability_save",m,commandType:System.Data.CommandType.StoredProcedure));}
    private IActionResult Save(StaffMemberRequestModel m) {if(string.IsNullOrWhiteSpace(m.first_name)||string.IsNullOrWhiteSpace(m.last_name)||m.staff_role_id<=0)return BadRequest("Nombre, apellido y rol son requeridos.");using var c=Connection();return Ok(c.QueryFirst("staff_sp_member_save",new{m.id,m.staff_role_id,m.first_name,m.last_name,m.identification_number,m.phone,m.email,specialties_json=System.Text.Json.JsonSerializer.Serialize(m.specialty_ids)},commandType:System.Data.CommandType.StoredProcedure));}
}
