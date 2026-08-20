using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;

namespace PAW_Proyecto_KronosAPI.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class ServicesController(IConfiguration config, IHelpersService helpers) : ControllerBase
{
    private SqlConnection Connection() => new(config["ConnectionStrings:DefaultConnection"]);

    [HttpGet]
    public IActionResult List() { using var c = Connection(); return Ok(c.Query<ServiceDefinitionResponseModel>("service_sp_services_list", commandType: System.Data.CommandType.StoredProcedure)); }

    [HttpGet("CompletionReferences")]
    public IActionResult CompletionReferences()
    {
        using var c = Connection();
        using var results = c.QueryMultiple("service_sp_completion_reference_data_get", commandType: System.Data.CommandType.StoredProcedure);
        return Ok(new ServiceCompletionReferenceDataModel { events = results.Read<ServiceReferenceOptionModel>().ToList(), staff_members = results.Read<ServiceReferenceOptionModel>().ToList() });
    }

    [HttpPost]
    public IActionResult Create(ServiceDefinitionRequestModel model) => Save(model);

    [HttpPut("{id:int}")]
    public IActionResult Update(int id, ServiceDefinitionRequestModel model) { model.id = id; return Save(model); }

    [HttpDelete("{id:int}")]
    public IActionResult Delete(int id) { using var c = Connection(); return Ok(c.QueryFirst("service_sp_service_delete", new { id }, commandType: System.Data.CommandType.StoredProcedure)); }

    [HttpPost("Events/Notes")]
    public IActionResult AddNote(ServiceEventNoteRequestModel model)
    {
        if (model.service_event_id <= 0 || model.note_type_id <= 0 || string.IsNullOrWhiteSpace(model.note_text))
            return BadRequest("La cita, el tipo y el texto de la nota son requeridos.");
        using var c = Connection();
        return Ok(c.QueryFirst("service_sp_event_note_add", model, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpGet("Events/{id:int}/Notes")]
    public IActionResult Notes(int id)
    {
        using var c = Connection();
        return Ok(c.Query<ServiceEventNoteResponseModel>("service_sp_event_notes_list", new { service_event_id = id }, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpPost("Events/Complete")]
    public IActionResult Complete(ServiceEventCompleteRequestModel model)
    {
        if (model.service_event_id <= 0) return BadRequest("La cita es requerida.");
        if (model.actual_end_at.HasValue && model.actual_start_at.HasValue && model.actual_end_at <= model.actual_start_at)
            return BadRequest("La hora final debe ser posterior a la hora inicial.");
        using var c = Connection();
        return Ok(c.QueryFirst("service_sp_event_complete", new
        {
            model.service_event_id,
            completed_by_user_id = helpers.ObtenerConsecutivoToken(),
            model.completed_by_staff_member_id,
            model.completion_summary,
            model.actual_start_at,
            model.actual_end_at
        }, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpPost("Events/{serviceEventId:int}/InventoryUsage")]
    public IActionResult RegisterInventoryUsage(int serviceEventId, ServiceEventInventoryUsageRequestModel model)
    {
        if (model.inventory_item_id <= 0 || model.location_id <= 0 || model.quantity_used <= 0)
            return BadRequest("Seleccione el producto, la ubicación y una cantidad válida.");
        using var c = Connection();
        return Ok(c.QueryFirst("service_sp_event_inventory_usage_add", new
        {
            service_event_id = serviceEventId,
            model.inventory_item_id,
            model.location_id,
            model.quantity_used,
            model.notes,
            created_by_user_id = helpers.ObtenerConsecutivoToken()
        }, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpGet("EquipmentLoans")]
    public IActionResult EquipmentLoans() { using var c = Connection(); return Ok(c.Query<EquipmentLoanResponseModel>("service_sp_equipment_loans_list", commandType: System.Data.CommandType.StoredProcedure)); }

    [HttpGet("EquipmentLoans/References")]
    public IActionResult EquipmentLoanReferences() { using var c = Connection(); using var r = c.QueryMultiple("service_sp_equipment_loan_reference_data_get", commandType: System.Data.CommandType.StoredProcedure); return Ok(new EquipmentLoanReferenceDataModel { patients = r.Read<ServiceReferenceOptionModel>().ToList(), equipment = r.Read<ServiceReferenceOptionModel>().ToList(), locations = r.Read<ServiceReferenceOptionModel>().ToList() }); }

    [HttpPost("EquipmentLoans")]
    public IActionResult CreateEquipmentLoan(EquipmentLoanRequestModel model)
    {
        if (model.patient_id <= 0 || model.inventory_item_id <= 0 || model.location_id <= 0) return BadRequest("Seleccione el paciente, el equipo y la ubicación.");
        using var c = Connection(); return Ok(c.QueryFirst("service_sp_equipment_loan_create", new { model.patient_id, model.inventory_item_id, model.location_id, model.loan_type, model.loaned_at, model.expected_return_at, model.amount, model.notes, created_by_user_id = helpers.ObtenerConsecutivoToken() }, commandType: System.Data.CommandType.StoredProcedure));
    }

    [HttpPost("EquipmentLoans/{id:int}/Return")]
    public IActionResult ReturnEquipmentLoan(int id, string? notes) { using var c = Connection(); return Ok(c.QueryFirst("service_sp_equipment_loan_return", new { id, notes, returned_by_user_id = helpers.ObtenerConsecutivoToken() }, commandType: System.Data.CommandType.StoredProcedure)); }

    private IActionResult Save(ServiceDefinitionRequestModel model)
    {
        if (string.IsNullOrWhiteSpace(model.name)) return BadRequest("El nombre del servicio es requerido.");
        if (model.default_price < 0) return BadRequest("El precio no puede ser negativo.");
        using var c = Connection();
        return Ok(c.QueryFirst("service_sp_service_save", model, commandType: System.Data.CommandType.StoredProcedure));
    }
}
