namespace PAW_Proyecto_Kronos.Models
{
    public class CitaCalendarViewModel
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public string MonthName { get; set; } = string.Empty;

        public List<CitaCalendarWeekModel> Semanas { get; set; } = new();

        
        public int? PatientId { get; set; }
        public int? StaffMemberId { get; set; }
        public int? StatusId { get; set; }
        public int? EventTypeId { get; set; }

        public List<StaffOptionModel> Colaboradores { get; set; } = new();
        public List<CatalogOptionModel> Estados { get; set; } = new();
        public List<CatalogOptionModel> TiposCita { get; set; } = new();
    }

    public class CitaCalendarWeekModel
    {
        public List<CitaCalendarDayModel> Dias { get; set; } = new();
    }

    public class CitaCalendarDayModel
    {
        public DateTime Fecha { get; set; }
        public bool EsDelMesActual { get; set; }
        public bool EsHoy { get; set; }
        public List<CitaListItemModel> Citas { get; set; } = new();
    }
}
