namespace PAW_Proyecto_Kronos.Models
{
    public class ExpedienteHeaderModel
    {
        public int id { get; set; }
        public int patient_id { get; set; }
        public string first_name { get; set; } = string.Empty;
        public string last_name { get; set; } = string.Empty;
        public string? identification_number { get; set; }
        public DateTime? birth_date { get; set; }
        public string? phone { get; set; }
        public string? email { get; set; }
        public string record_number { get; set; } = string.Empty;
        public DateTime opened_at { get; set; }
        public DateTime? closed_at { get; set; }
        public int status_id { get; set; }
        public string status_name { get; set; } = string.Empty;
        public string status_value { get; set; } = string.Empty;
        public DateTime created_at { get; set; }
        public DateTime? updated_at { get; set; }
    }

    public class ExpedienteNoteModel
    {
        public int id { get; set; }
        public int medical_record_id { get; set; }
        public int patient_id { get; set; }
        public int staff_member_id { get; set; }
        public string staff_first_name { get; set; } = string.Empty;
        public string staff_last_name { get; set; } = string.Empty;
        public int note_type_id { get; set; }
        public string note_type_name { get; set; } = string.Empty;
        public string note_text { get; set; } = string.Empty;
        public DateTime created_at { get; set; }
        public int total_count { get; set; }
    }

    public class ExpedienteConditionModel
    {
        public int id { get; set; }
        public int patient_id { get; set; }
        public int medical_condition_id { get; set; }
        public string condition_name { get; set; } = string.Empty;
        public DateTime? diagnosed_at { get; set; }
        public int? status_id { get; set; }
        public string? status_name { get; set; }
        public string? notes { get; set; }
        public DateTime created_at { get; set; }
        public DateTime? updated_at { get; set; }
    }

    public class ExpedienteMedicationModel
    {
        public int id { get; set; }
        public int patient_id { get; set; }
        public int medical_medication_id { get; set; }
        public string medication_name { get; set; } = string.Empty;
        public string? dosage { get; set; }
        public string? frequency { get; set; }
        public DateTime? start_date { get; set; }
        public DateTime? end_date { get; set; }
        public string? notes { get; set; }
        public DateTime created_at { get; set; }
        public DateTime? updated_at { get; set; }
    }

    public class ExpedienteAttachmentModel
    {
        public int id { get; set; }
        public int medical_record_id { get; set; }
        public int document_type_id { get; set; }
        public string document_type_name { get; set; } = string.Empty;
        public string file_name { get; set; } = string.Empty;
        public string? content_type { get; set; }
        public long? file_size { get; set; }
        public int uploaded_by_user_id { get; set; }
        public DateTime uploaded_at { get; set; }
    }

    public class ExpedienteDetailFullModel
    {
        public ExpedienteHeaderModel? expediente { get; set; }
        public List<ExpedienteNoteModel> notas { get; set; } = new();
        public List<ExpedienteConditionModel> diagnosticos { get; set; } = new();
        public List<ExpedienteMedicationModel> tratamientos { get; set; } = new();
        public List<ExpedienteAttachmentModel> adjuntos { get; set; } = new();

        public List<CatalogOptionModel> TiposNota { get; set; } = new();
        public List<CatalogOptionModel> EstadosCondicion { get; set; } = new();
        public List<DocumentTypeOptionModel> TiposDocumento { get; set; } = new();

        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public int TotalCount => notas.FirstOrDefault()?.total_count ?? 0;
        public int TotalPages => TotalCount == 0 ? 1 : (int)Math.Ceiling(TotalCount / (double)PageSize);
    }

    public class DocumentTypeOptionModel
    {
        public int id { get; set; }
        public string name { get; set; } = string.Empty;
        public string? description { get; set; }
    }
}