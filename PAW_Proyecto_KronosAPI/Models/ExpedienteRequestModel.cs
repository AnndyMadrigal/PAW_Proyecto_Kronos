namespace PAW_Proyecto_KronosAPI.Models
{
    public class ExpedienteOpenRequestModel
    {
        public int patient_id { get; set; }
        public int user_id { get; set; }
    }

    public class ExpedienteUpdateStatusRequestModel
    {
        public int medical_record_id { get; set; }
        public int status_id { get; set; }
        public int user_id { get; set; }
    }

    public class ExpedienteNoteCreateRequestModel
    {
        public int medical_record_id { get; set; }
        public int patient_id { get; set; }
        public int staff_member_id { get; set; }
        public int note_type_id { get; set; }
        public string note_text { get; set; } = string.Empty;
        public int user_id { get; set; }
    }

    public class ExpedienteConditionUpsertRequestModel
    {
        public int? id { get; set; }
        public int patient_id { get; set; }
        public int medical_condition_id { get; set; }
        public DateTime? diagnosed_at { get; set; }
        public int? status_id { get; set; }
        public string? notes { get; set; }
        public int user_id { get; set; }
    }

    public class ExpedienteMedicationUpsertRequestModel
    {
        public int? id { get; set; }
        public int patient_id { get; set; }
        public int medical_medication_id { get; set; }
        public string? dosage { get; set; }
        public string? frequency { get; set; }
        public DateTime? start_date { get; set; }
        public DateTime? end_date { get; set; }
        public string? notes { get; set; }
        public int user_id { get; set; }
    }

    public class PatientRegisterRequestModel
    {
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? identification_number { get; set; }
        public DateTime? birth_date { get; set; }
        public int? gender_id { get; set; }
        public string? phone { get; set; }
        public string? email { get; set; }
        public int? address_id { get; set; }
        public bool open_medical_record { get; set; }
        public int created_by_user_id { get; set; }
    }

    public class PatientUpdateRequestModel
    {
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? identification_number { get; set; }
        public DateTime? birth_date { get; set; }
        public int? gender_id { get; set; }
        public string? phone { get; set; }
        public string? email { get; set; }
    }

    public class ClinicalVitalRequestModel { public int patient_id { get; set; } public int? staff_member_id { get; set; } public string? blood_pressure { get; set; } public int? heart_rate { get; set; } public decimal? temperature { get; set; } public decimal? oxygen_saturation { get; set; } public int? respiratory_rate { get; set; } public string? notes { get; set; } }
    public class ClinicalAllergyRequestModel { public int? id { get; set; } public int patient_id { get; set; } public int medical_allergy_id { get; set; } public string? reaction { get; set; } public int? severity_id { get; set; } public string? notes { get; set; } }
    public class ClinicalCarePlanRequestModel { public int patient_id { get; set; } public string title { get; set; } = string.Empty; public string? description { get; set; } public DateTime? start_date { get; set; } public DateTime? end_date { get; set; } public int status_id { get; set; } public int? created_by_staff_id { get; set; } }
    public class ClinicalCareActivityRequestModel { public int patient_care_plan_id { get; set; } public string title { get; set; } = string.Empty; public string? description { get; set; } public DateTime? due_date { get; set; } public int status_id { get; set; } }

    public class PatientDetailResponseModel : PatientSearchResponseModel
    {
        public DateTime? birth_date { get; set; }
        public int? gender_id { get; set; }
        public int? status_id { get; set; }
    }
}
