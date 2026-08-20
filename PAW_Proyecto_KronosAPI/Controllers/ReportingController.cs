using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
namespace PAW_Proyecto_KronosAPI.Controllers;
[Authorize(Roles = "Administrador,Finanzas,Administrativo")]
[Route("api/[controller]")]
[ApiController]
public class ReportingController(IConfiguration config):ControllerBase
{
 private SqlConnection Connection()=>new(config["ConnectionStrings:DefaultConnection"]);
 [HttpGet("Appointments/Summary")] public IActionResult AppointmentSummary(DateTime? from,DateTime? to){using var c=Connection();return Ok(c.QueryFirst<AppointmentReportSummaryModel>("service_sp_report_appointment_summary",new{date_from=from?.Date,date_to=to?.Date},commandType:System.Data.CommandType.StoredProcedure));}
 [HttpGet("Appointments/Workload")] public IActionResult Workload(DateTime? from,DateTime? to){using var c=Connection();return Ok(c.Query<StaffWorkloadReportModel>("service_sp_report_staff_workload",new{date_from=from?.Date,date_to=to?.Date},commandType:System.Data.CommandType.StoredProcedure));}
 [HttpGet("Inventory/LowStock")] public IActionResult LowStock(){using var c=Connection();return Ok(c.Query("inventory_sp_report_low_stock",commandType:System.Data.CommandType.StoredProcedure));}
}
