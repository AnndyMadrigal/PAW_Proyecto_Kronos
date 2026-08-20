namespace PAW_Proyecto_KronosAPI.Models;
public class AppointmentReportSummaryModel { public int scheduled { get; set; } public int completed { get; set; } public int cancelled { get; set; } public int total { get; set; } }
public class StaffWorkloadReportModel { public int staff_member_id { get; set; } public string staff_name { get; set; } = string.Empty; public int appointment_count { get; set; } }
