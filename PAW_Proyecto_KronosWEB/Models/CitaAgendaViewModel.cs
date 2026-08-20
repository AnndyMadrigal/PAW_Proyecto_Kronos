namespace PAW_Proyecto_Kronos.Models;
public class CitaAgendaViewModel
{
 public DateTime StartDate { get; set; }
 public DateTime EndDate { get; set; }
 public string Mode { get; set; } = "day";
 public int? StaffMemberId { get; set; }
 public List<CitaListItemModel> Citas { get; set; } = [];
 public List<StaffOptionModel> Colaboradores { get; set; } = [];
}
