namespace PAW_Proyecto_Kronos.Models
{
    public class ExpedienteNoteFormModel
    {
        public int medical_record_id { get; set; }
        public int patient_id { get; set; }
        public int staff_member_id { get; set; }
        public int note_type_id { get; set; }
        public string note_text { get; set; } = string.Empty;
    }

    public class ExpedienteConditionFormModel
    {
        public int? id { get; set; }
        public int patient_id { get; set; }
        public int medical_condition_id { get; set; }
        public DateTime? diagnosed_at { get; set; }
        public int? status_id { get; set; }
        public string? notes { get; set; }
    }

    public class ExpedienteMedicationFormModel
    {
        public int? id { get; set; }
        public int patient_id { get; set; }
        public int medical_medication_id { get; set; }
        public string? dosage { get; set; }
        public string? frequency { get; set; }
        public DateTime? start_date { get; set; }
        public DateTime? end_date { get; set; }
        public string? notes { get; set; }
    }

    public class PatientRegisterFormModel
    {
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? identification_number { get; set; }
        public DateTime? birth_date { get; set; }
        public string? phone { get; set; }
        public string? email { get; set; }
        public bool open_medical_record { get; set; } = true;
    }

    public class ExpedienteSearchViewModel
    {
        public string? Search { get; set; }
        public List<PatientOptionModel> Pacientes { get; set; } = new();
    }
}