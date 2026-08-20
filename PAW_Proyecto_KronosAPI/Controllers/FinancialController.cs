using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using PAW_Proyecto_KronosAPI.Models;
using PAW_Proyecto_KronosAPI.Services;
namespace PAW_Proyecto_KronosAPI.Controllers;
[Authorize(Roles = "Administrador,Finanzas")][Route("api/[controller]")][ApiController]
public class FinancialController(IConfiguration config,IHelpersService helpers):ControllerBase {
 private SqlConnection Connection()=>new(config["ConnectionStrings:DefaultConnection"]);
 [HttpGet("Summary")] public IActionResult Summary(){using var c=Connection();return Ok(c.QueryFirst<FinancialSummaryModel>("financial_sp_report_summary",commandType:System.Data.CommandType.StoredProcedure));}
 [HttpGet("Transactions")] public IActionResult Transactions(DateTime? from,DateTime? to){using var c=Connection();return Ok(c.Query<FinancialTransactionModel>("financial_sp_report_transactions",new{date_from=from,date_to=to},commandType:System.Data.CommandType.StoredProcedure));}
 [HttpGet("References")] public IActionResult References(){using var c=Connection();using var results=c.QueryMultiple("financial_sp_reference_data_get",commandType:System.Data.CommandType.StoredProcedure);return Ok(new FinancialReferenceDataModel{categories=results.Read<FinancialCategoryOptionModel>().ToList(),payment_methods=results.Read<FinancialOptionModel>().ToList()});}
 [HttpPost("Transactions")] public IActionResult Create(FinancialTransactionRequestModel m){if((m.transaction_type!="income"&&m.transaction_type!="expense")||m.amount<=0)return BadRequest("Tipo y monto válidos son requeridos.");using var c=Connection();return Ok(c.QueryFirst("financial_sp_transaction_create",new{m.transaction_type,m.financial_category_id,m.financial_payment_method_id,m.amount,m.transaction_date,m.description,m.financial_donor_id,m.supplier_id,created_by_user_id=helpers.ObtenerConsecutivoToken()},commandType:System.Data.CommandType.StoredProcedure));}
}
