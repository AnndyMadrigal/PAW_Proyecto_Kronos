USE [Kronos]
GO
/****** Objeto: User [KronosReader] Fecha de script: 23/7/2026 18:22:29 ******/
CREATE USER [KronosReader] FOR LOGIN [KronosReader] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Objeto: User [SysAdKronos] Fecha de script: 23/7/2026 18:22:29 ******/
CREATE USER [SysAdKronos] FOR LOGIN [SysAdKronos] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [SysAdKronos]
GO
/****** Objeto: UserDefinedFunction [dbo].[config_fn_catalog_item_value] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[config_fn_catalog_item_value](@catalog_item_id int)
RETURNS nvarchar(150)
AS
BEGIN
    DECLARE @value nvarchar(150);

    SELECT @value = value
    FROM config_tbl_catalog_items
    WHERE id = @catalog_item_id;

    RETURN @value;
END;

GO
/****** Objeto: UserDefinedFunction [dbo].[inventory_fn_batch_stock] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[inventory_fn_batch_stock](@inventory_batch_id int)
RETURNS decimal(18,4)
AS
BEGIN
    DECLARE @stock decimal(18,4);

    SELECT @stock = quantity_available
    FROM inventory_tbl_batches
    WHERE id = @inventory_batch_id
      AND deleted = 0;

    RETURN ISNULL(@stock, 0);
END;

GO
/****** Objeto: UserDefinedFunction [dbo].[inventory_fn_item_stock] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[inventory_fn_item_stock](@inventory_item_id int)
RETURNS decimal(18,4)
AS
BEGIN
    DECLARE @stock decimal(18,4);

    SELECT @stock = SUM(quantity_available)
    FROM inventory_tbl_batches
    WHERE inventory_item_id = @inventory_item_id
      AND deleted = 0;

    RETURN ISNULL(@stock, 0);
END;

GO
/****** Objeto: UserDefinedFunction [dbo].[patient_fn_age] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[patient_fn_age](@birth_date date)
RETURNS int
AS
BEGIN
    DECLARE @age int;

    IF @birth_date IS NULL
        RETURN NULL;

    SET @age = DATEDIFF(year, @birth_date, CAST(SYSDATETIME() AS date));

    IF DATEADD(year, @age, @birth_date) > CAST(SYSDATETIME() AS date)
        SET @age = @age - 1;

    RETURN @age;
END;

GO
/****** Objeto: UserDefinedFunction [dbo].[staff_fn_is_available] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[staff_fn_is_available]
(
    @staff_member_id int,
    @start_at datetime2(0),
    @end_at datetime2(0)
)
RETURNS bit
AS
BEGIN
    DECLARE @available bit = 0;

    IF EXISTS (
        SELECT 1
        FROM staff_tbl_availability
        WHERE staff_member_id = @staff_member_id
          AND available_date = CAST(@start_at AS date)
          AND start_time <= CAST(@start_at AS time(0))
          AND end_time >= CAST(@end_at AS time(0))
          AND is_available = 1
          AND deleted = 0
    )
    BEGIN
        SET @available = 1;
    END;

    RETURN @available;
END;

GO
/****** Objeto: Table [dbo].[access_tbl_roles] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_roles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_access_tbl_roles] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[access_tbl_user_roles] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_user_roles](
	[user_id] [int] NOT NULL,
	[role_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_access_tbl_user_roles] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC,
	[role_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[access_tbl_users] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](100) NOT NULL,
	[email] [nvarchar](256) NOT NULL,
	[password] [nvarchar](500) NOT NULL,
	[full_name] [nvarchar](200) NOT NULL,
	[phone] [nvarchar](30) NULL,
	[failed_login_attempts] [int] NOT NULL,
	[lockout_until] [datetime2](0) NULL,
	[last_login_at] [datetime2](0) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_access_tbl_users] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[access_vw_users_with_roles] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[access_vw_users_with_roles] AS
SELECT
    u.id AS user_id,
    u.username,
    u.email,
    u.full_name,
    u.phone,
    u.is_active,
    u.deleted,
    STRING_AGG(r.name, ', ') AS roles
FROM access_tbl_users u
LEFT JOIN access_tbl_user_roles ur ON ur.user_id = u.id
LEFT JOIN access_tbl_roles r ON r.id = ur.role_id
GROUP BY u.id, u.username, u.email, u.full_name, u.phone, u.is_active, u.deleted;

GO
/****** Objeto: Table [dbo].[access_tbl_audit_logs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_audit_logs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[action] [nvarchar](100) NOT NULL,
	[entity_name] [nvarchar](150) NOT NULL,
	[entity_id] [int] NULL,
	[old_value] [nvarchar](max) NULL,
	[new_value] [nvarchar](max) NULL,
	[ip_address] [nvarchar](45) NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_access_tbl_audit_logs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[access_vw_audit_log_search] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[access_vw_audit_log_search] AS
SELECT
    a.id,
    a.user_id,
    u.full_name AS user_name,
    a.action,
    a.entity_name,
    a.entity_id,
    a.ip_address,
    a.created_at
FROM access_tbl_audit_logs a
LEFT JOIN access_tbl_users u ON u.id = a.user_id;

GO
/****** Objeto: Table [dbo].[patient_tbl_patients] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_tbl_patients](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[address_id] [int] NULL,
	[first_name] [nvarchar](100) NOT NULL,
	[last_name] [nvarchar](150) NOT NULL,
	[identification_number] [nvarchar](50) NULL,
	[birth_date] [date] NULL,
	[gender_id] [int] NULL,
	[phone] [nvarchar](30) NULL,
	[email] [nvarchar](256) NULL,
	[status_id] [int] NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_patient_tbl_patients] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[config_tbl_catalog_items] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[config_tbl_catalog_items](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[catalog_id] [int] NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[value] [nvarchar](150) NOT NULL,
	[sort_order] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_config_tbl_catalog_items] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[patient_vw_active_patients] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[patient_vw_active_patients] AS
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.identification_number,
    p.birth_date,
    p.phone,
    p.email,
    p.status_id,
    status_item.name AS status_name,
    p.created_at
FROM patient_tbl_patients p
LEFT JOIN config_tbl_catalog_items status_item ON status_item.id = p.status_id
WHERE p.deleted = 0 AND p.is_active = 1;

GO
/****** Objeto: Table [dbo].[location_tbl_provinces] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[location_tbl_provinces](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
 CONSTRAINT [pk_location_tbl_provinces] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[location_tbl_cantons] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[location_tbl_cantons](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[location_province_id] [int] NOT NULL,
	[name] [nvarchar](100) NOT NULL,
 CONSTRAINT [pk_location_tbl_cantons] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[location_tbl_districts] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[location_tbl_districts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[location_canton_id] [int] NOT NULL,
	[name] [nvarchar](100) NOT NULL,
 CONSTRAINT [pk_location_tbl_districts] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[location_tbl_addresses] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[location_tbl_addresses](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[location_district_id] [int] NOT NULL,
	[address_line] [nvarchar](500) NOT NULL,
	[reference] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_location_tbl_addresses] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[patient_vw_summary] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[patient_vw_summary] AS
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.identification_number,
    p.birth_date,
    p.phone,
    p.email,
    p.status_id,
    status_item.name AS status_name,
    d.name AS district_name,
    c.name AS canton_name,
    pr.name AS province_name
FROM patient_tbl_patients p
LEFT JOIN config_tbl_catalog_items status_item ON status_item.id = p.status_id
LEFT JOIN location_tbl_addresses a ON a.id = p.address_id
LEFT JOIN location_tbl_districts d ON d.id = a.location_district_id
LEFT JOIN location_tbl_cantons c ON c.id = d.location_canton_id
LEFT JOIN location_tbl_provinces pr ON pr.id = c.location_province_id
WHERE p.deleted = 0;

GO
/****** Objeto: Table [dbo].[medical_tbl_record_notes] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_record_notes](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[medical_record_id] [int] NOT NULL,
	[patient_id] [int] NOT NULL,
	[staff_member_id] [int] NOT NULL,
	[note_type_id] [int] NOT NULL,
	[note_text] [nvarchar](max) NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_record_notes] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_patient_conditions] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_patient_conditions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[medical_condition_id] [int] NOT NULL,
	[diagnosed_at] [date] NULL,
	[status_id] [int] NULL,
	[notes] [nvarchar](max) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_patient_conditions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_patient_medications] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_patient_medications](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[medical_medication_id] [int] NOT NULL,
	[dosage] [nvarchar](100) NULL,
	[frequency] [nvarchar](100) NULL,
	[start_date] [date] NULL,
	[end_date] [date] NULL,
	[notes] [nvarchar](max) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_patient_medications] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_patient_allergies] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_patient_allergies](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[medical_allergy_id] [int] NOT NULL,
	[reaction] [nvarchar](300) NULL,
	[severity_id] [int] NULL,
	[notes] [nvarchar](max) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_patient_allergies] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_patient_vital_signs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_patient_vital_signs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[staff_member_id] [int] NULL,
	[blood_pressure] [nvarchar](20) NULL,
	[heart_rate] [int] NULL,
	[temperature] [decimal](5, 2) NULL,
	[oxygen_saturation] [decimal](5, 2) NULL,
	[respiratory_rate] [int] NULL,
	[recorded_at] [datetime2](0) NOT NULL,
	[notes] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_medical_tbl_patient_vital_signs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[patient_vw_medical_activity] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[patient_vw_medical_activity] AS
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT n.id) AS note_count,
    COUNT(DISTINCT pc.id) AS condition_count,
    COUNT(DISTINCT pm.id) AS medication_count,
    COUNT(DISTINCT pa.id) AS allergy_count,
    COUNT(DISTINCT vs.id) AS vital_sign_count
FROM patient_tbl_patients p
LEFT JOIN medical_tbl_record_notes n ON n.patient_id = p.id AND n.deleted = 0
LEFT JOIN medical_tbl_patient_conditions pc ON pc.patient_id = p.id AND pc.deleted = 0
LEFT JOIN medical_tbl_patient_medications pm ON pm.patient_id = p.id AND pm.deleted = 0
LEFT JOIN medical_tbl_patient_allergies pa ON pa.patient_id = p.id AND pa.deleted = 0
LEFT JOIN medical_tbl_patient_vital_signs vs ON vs.patient_id = p.id
WHERE p.deleted = 0
GROUP BY p.id, p.first_name, p.last_name;

GO
/****** Objeto: Table [dbo].[medical_tbl_record_access_logs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_record_access_logs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[medical_record_id] [int] NOT NULL,
	[patient_id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[staff_member_id] [int] NULL,
	[access_type_id] [int] NOT NULL,
	[access_reason] [nvarchar](500) NULL,
	[ip_address] [nvarchar](45) NULL,
	[device_info] [nvarchar](500) NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_medical_tbl_record_access_logs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[medical_vw_record_access_logs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[medical_vw_record_access_logs] AS
SELECT
    l.id,
    l.medical_record_id,
    l.patient_id,
    p.first_name,
    p.last_name,
    l.user_id,
    u.full_name AS user_name,
    l.access_type_id,
    t.name AS access_type_name,
    l.access_reason,
    l.ip_address,
    l.device_info,
    l.created_at
FROM medical_tbl_record_access_logs l
INNER JOIN patient_tbl_patients p ON p.id = l.patient_id
INNER JOIN access_tbl_users u ON u.id = l.user_id
INNER JOIN config_tbl_catalog_items t ON t.id = l.access_type_id;

GO
/****** Objeto: Table [dbo].[staff_tbl_members] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[staff_tbl_members](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[staff_role_id] [int] NOT NULL,
	[first_name] [nvarchar](100) NOT NULL,
	[last_name] [nvarchar](150) NOT NULL,
	[identification_number] [nvarchar](50) NULL,
	[phone] [nvarchar](30) NULL,
	[email] [nvarchar](256) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_staff_tbl_members] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[staff_tbl_availability] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[staff_tbl_availability](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[staff_member_id] [int] NOT NULL,
	[available_date] [date] NOT NULL,
	[start_time] [time](0) NOT NULL,
	[end_time] [time](0) NOT NULL,
	[is_available] [bit] NOT NULL,
	[source_type_id] [int] NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_staff_tbl_availability] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[staff_vw_schedule] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[staff_vw_schedule] AS
SELECT
    a.id,
    a.staff_member_id,
    s.first_name,
    s.last_name,
    a.available_date,
    a.start_time,
    a.end_time,
    a.is_available
FROM staff_tbl_availability a
INNER JOIN staff_tbl_members s ON s.id = a.staff_member_id
WHERE a.deleted = 0;

GO
/****** Objeto: Table [dbo].[service_tbl_events] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_events](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NULL,
	[event_type_id] [int] NOT NULL,
	[status_id] [int] NOT NULL,
	[scheduled_start_at] [datetime2](0) NOT NULL,
	[scheduled_end_at] [datetime2](0) NOT NULL,
	[actual_start_at] [datetime2](0) NULL,
	[actual_end_at] [datetime2](0) NULL,
	[location_type_id] [int] NOT NULL,
	[location_id] [int] NULL,
	[address_id] [int] NULL,
	[location_description] [nvarchar](500) NULL,
	[main_staff_member_id] [int] NULL,
	[summary] [nvarchar](max) NULL,
	[created_by_user_id] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_service_tbl_events] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[service_vw_event_calendar] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[service_vw_event_calendar] AS
SELECT
    e.id,
    e.patient_id,
    p.first_name AS patient_first_name,
    p.last_name AS patient_last_name,
    e.event_type_id,
    et.name AS event_type_name,
    e.status_id,
    st.name AS status_name,
    e.scheduled_start_at,
    e.scheduled_end_at,
    e.main_staff_member_id,
    sm.first_name AS staff_first_name,
    sm.last_name AS staff_last_name
FROM service_tbl_events e
LEFT JOIN patient_tbl_patients p ON p.id = e.patient_id
LEFT JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
LEFT JOIN config_tbl_catalog_items et ON et.id = e.event_type_id
LEFT JOIN config_tbl_catalog_items st ON st.id = e.status_id
WHERE e.deleted = 0;

GO
/****** Objeto: View [dbo].[service_vw_event_detail] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[service_vw_event_detail] AS
SELECT
    e.*
FROM service_tbl_events e
WHERE e.deleted = 0;

GO
/****** Objeto: View [dbo].[service_vw_report_events] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[service_vw_report_events] AS
SELECT * FROM service_vw_event_calendar;

GO
/****** Objeto: Table [dbo].[service_tbl_event_inventory_usage] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_event_inventory_usage](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[service_event_id] [int] NOT NULL,
	[inventory_item_id] [int] NOT NULL,
	[inventory_batch_id] [int] NULL,
	[quantity_used] [decimal](18, 4) NOT NULL,
	[notes] [nvarchar](max) NULL,
	[created_by_user_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_service_tbl_event_inventory_usage] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[inventory_tbl_items] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inventory_tbl_items](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[inventory_category_id] [int] NOT NULL,
	[inventory_unit_id] [int] NOT NULL,
	[name] [nvarchar](200) NOT NULL,
	[description] [nvarchar](500) NULL,
	[minimum_stock] [decimal](18, 4) NOT NULL,
	[requires_expiration_date] [bit] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_inventory_tbl_items] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[service_vw_inventory_usage] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[service_vw_inventory_usage] AS
SELECT
    u.id,
    u.service_event_id,
    u.inventory_item_id,
    i.name AS inventory_item_name,
    u.inventory_batch_id,
    u.quantity_used,
    u.created_at
FROM service_tbl_event_inventory_usage u
INNER JOIN inventory_tbl_items i ON i.id = u.inventory_item_id;

GO
/****** Objeto: Table [dbo].[inventory_tbl_categories] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inventory_tbl_categories](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_inventory_tbl_categories] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[inventory_tbl_units] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inventory_tbl_units](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[abbreviation] [nvarchar](20) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_inventory_tbl_units] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[inventory_tbl_batches] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inventory_tbl_batches](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[inventory_item_id] [int] NOT NULL,
	[location_id] [int] NOT NULL,
	[batch_number] [nvarchar](100) NULL,
	[expiration_date] [date] NULL,
	[unit_cost] [decimal](18, 2) NULL,
	[quantity_initial] [decimal](18, 4) NOT NULL,
	[quantity_available] [decimal](18, 4) NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_inventory_tbl_batches] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[inventory_vw_stock_by_item] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[inventory_vw_stock_by_item] AS
SELECT
    i.id AS inventory_item_id,
    i.name,
    c.name AS category_name,
    u.name AS unit_name,
    i.minimum_stock,
    SUM(ISNULL(b.quantity_available, 0)) AS quantity_available
FROM inventory_tbl_items i
INNER JOIN inventory_tbl_categories c ON c.id = i.inventory_category_id
INNER JOIN inventory_tbl_units u ON u.id = i.inventory_unit_id
LEFT JOIN inventory_tbl_batches b ON b.inventory_item_id = i.id AND b.deleted = 0
WHERE i.deleted = 0
GROUP BY i.id, i.name, c.name, u.name, i.minimum_stock;

GO
/****** Objeto: Table [dbo].[location_tbl_locations] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[location_tbl_locations](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[address_id] [int] NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_location_tbl_locations] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[inventory_vw_stock_by_location] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[inventory_vw_stock_by_location] AS
SELECT
    i.id AS inventory_item_id,
    i.name AS inventory_item_name,
    l.id AS location_id,
    l.name AS location_name,
    SUM(ISNULL(b.quantity_available, 0)) AS quantity_available
FROM inventory_tbl_items i
LEFT JOIN inventory_tbl_batches b ON b.inventory_item_id = i.id AND b.deleted = 0
LEFT JOIN location_tbl_locations l ON l.id = b.location_id
WHERE i.deleted = 0
GROUP BY i.id, i.name, l.id, l.name;

GO
/****** Objeto: View [dbo].[inventory_vw_low_stock] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[inventory_vw_low_stock] AS
SELECT *
FROM inventory_vw_stock_by_item
WHERE quantity_available <= minimum_stock;

GO
/****** Objeto: View [dbo].[inventory_vw_expiring_batches] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[inventory_vw_expiring_batches] AS
SELECT
    b.id,
    b.inventory_item_id,
    i.name AS inventory_item_name,
    b.location_id,
    l.name AS location_name,
    b.batch_number,
    b.expiration_date,
    b.quantity_available
FROM inventory_tbl_batches b
INNER JOIN inventory_tbl_items i ON i.id = b.inventory_item_id
INNER JOIN location_tbl_locations l ON l.id = b.location_id
WHERE b.deleted = 0 AND b.quantity_available > 0 AND b.expiration_date IS NOT NULL;

GO
/****** Objeto: Table [dbo].[inventory_tbl_movements] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inventory_tbl_movements](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[inventory_item_id] [int] NOT NULL,
	[inventory_batch_id] [int] NULL,
	[location_id] [int] NOT NULL,
	[movement_type_id] [int] NOT NULL,
	[source_type_id] [int] NOT NULL,
	[supplier_id] [int] NULL,
	[financial_donor_id] [int] NULL,
	[quantity] [decimal](18, 4) NOT NULL,
	[unit_cost] [decimal](18, 2) NULL,
	[total_cost] [decimal](18, 2) NULL,
	[movement_date] [datetime2](0) NOT NULL,
	[notes] [nvarchar](max) NULL,
	[created_by_user_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_inventory_tbl_movements] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[inventory_vw_report_movements] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[inventory_vw_report_movements] AS
SELECT
    m.id,
    m.inventory_item_id,
    i.name AS inventory_item_name,
    m.location_id,
    l.name AS location_name,
    mt.name AS movement_type_name,
    st.name AS source_type_name,
    m.quantity,
    m.unit_cost,
    m.total_cost,
    m.movement_date,
    m.created_by_user_id
FROM inventory_tbl_movements m
INNER JOIN inventory_tbl_items i ON i.id = m.inventory_item_id
INNER JOIN location_tbl_locations l ON l.id = m.location_id
INNER JOIN config_tbl_catalog_items mt ON mt.id = m.movement_type_id
INNER JOIN config_tbl_catalog_items st ON st.id = m.source_type_id;

GO
/****** Objeto: Table [dbo].[financial_tbl_transactions] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_transactions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[transaction_type] [nvarchar](20) NOT NULL,
	[financial_category_id] [int] NOT NULL,
	[financial_payment_method_id] [int] NULL,
	[amount] [decimal](18, 2) NOT NULL,
	[transaction_date] [datetime2](0) NOT NULL,
	[description] [nvarchar](max) NULL,
	[financial_donor_id] [int] NULL,
	[supplier_id] [int] NULL,
	[patient_id] [int] NULL,
	[inventory_movement_id] [int] NULL,
	[service_event_id] [int] NULL,
	[financial_invoice_id] [int] NULL,
	[financial_receipt_id] [int] NULL,
	[created_by_user_id] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_financial_tbl_transactions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[financial_vw_transactions_summary] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[financial_vw_transactions_summary] AS
SELECT
    transaction_type,
    CAST(transaction_date AS date) AS transaction_day,
    SUM(amount) AS total_amount
FROM financial_tbl_transactions
WHERE deleted = 0
GROUP BY transaction_type, CAST(transaction_date AS date);

GO
/****** Objeto: View [dbo].[financial_vw_balance_by_period] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[financial_vw_balance_by_period] AS
SELECT
    YEAR(transaction_date) AS year_number,
    MONTH(transaction_date) AS month_number,
    SUM(CASE WHEN transaction_type = N'income' THEN amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN transaction_type = N'expense' THEN amount ELSE 0 END) AS total_expense,
    SUM(CASE WHEN transaction_type = N'income' THEN amount WHEN transaction_type = N'expense' THEN -amount ELSE 0 END) AS balance
FROM financial_tbl_transactions
WHERE deleted = 0
GROUP BY YEAR(transaction_date), MONTH(transaction_date);

GO
/****** Objeto: Table [dbo].[financial_tbl_invoices] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_invoices](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[invoice_number] [nvarchar](50) NOT NULL,
	[patient_id] [int] NULL,
	[issue_date] [date] NOT NULL,
	[due_date] [date] NULL,
	[status_id] [int] NOT NULL,
	[subtotal] [decimal](18, 2) NOT NULL,
	[tax_amount] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 2) NOT NULL,
	[notes] [nvarchar](max) NULL,
	[created_by_user_id] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_financial_tbl_invoices] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[financial_vw_invoice_status] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[financial_vw_invoice_status] AS
SELECT
    i.id,
    i.invoice_number,
    i.patient_id,
    p.first_name,
    p.last_name,
    i.issue_date,
    i.due_date,
    i.status_id,
    s.name AS status_name,
    i.total_amount
FROM financial_tbl_invoices i
LEFT JOIN patient_tbl_patients p ON p.id = i.patient_id
INNER JOIN config_tbl_catalog_items s ON s.id = i.status_id
WHERE i.deleted = 0;

GO
/****** Objeto: Table [dbo].[notification_tbl_logs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[notification_tbl_logs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[patient_id] [int] NULL,
	[service_event_id] [int] NULL,
	[notification_type_id] [int] NOT NULL,
	[recipient] [nvarchar](256) NULL,
	[subject] [nvarchar](250) NULL,
	[message] [nvarchar](max) NULL,
	[status_id] [int] NOT NULL,
	[sent_at] [datetime2](0) NULL,
	[error_message] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_notification_tbl_logs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[notification_vw_pending] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[notification_vw_pending] AS
SELECT *
FROM notification_tbl_logs
WHERE sent_at IS NULL;

GO
/****** Objeto: Table [dbo].[system_tbl_error_logs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[system_tbl_error_logs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NULL,
	[source] [nvarchar](150) NULL,
	[message] [nvarchar](max) NOT NULL,
	[detail] [nvarchar](max) NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_system_tbl_error_logs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: View [dbo].[system_vw_error_summary] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[system_vw_error_summary] AS
SELECT
    id,
    user_id,
    source,
    message,
    created_at
FROM system_tbl_error_logs;

GO
/****** Objeto: Table [dbo].[access_tbl_password_reset_tokens] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_password_reset_tokens](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[token] [nvarchar](500) NOT NULL,
	[expires_at] [datetime2](0) NOT NULL,
	[used_at] [datetime2](0) NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_access_tbl_password_reset_tokens] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[access_tbl_permissions] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_permissions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_access_tbl_permissions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[access_tbl_role_permissions] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_role_permissions](
	[role_id] [int] NOT NULL,
	[permission_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_access_tbl_role_permissions] PRIMARY KEY CLUSTERED 
(
	[role_id] ASC,
	[permission_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[access_tbl_user_sessions] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[access_tbl_user_sessions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[login_at] [datetime2](0) NOT NULL,
	[logout_at] [datetime2](0) NULL,
	[token_id] [nvarchar](100) NULL,
	[ip_address] [nvarchar](45) NULL,
	[device_info] [nvarchar](500) NULL,
	[is_revoked] [bit] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_access_tbl_user_sessions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[config_tbl_catalogs] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[config_tbl_catalogs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_config_tbl_catalogs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[config_tbl_document_types] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[config_tbl_document_types](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_config_tbl_document_types] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[config_tbl_settings] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[config_tbl_settings](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[setting_type] [nvarchar](100) NOT NULL,
	[setting_name] [nvarchar](150) NOT NULL,
	[setting_value] [nvarchar](max) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_config_tbl_settings] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[financial_tbl_categories] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_categories](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[transaction_type] [nvarchar](20) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_financial_tbl_categories] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[financial_tbl_donors] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_donors](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](200) NOT NULL,
	[contact_name] [nvarchar](200) NULL,
	[phone] [nvarchar](30) NULL,
	[email] [nvarchar](256) NULL,
	[notes] [nvarchar](max) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_financial_tbl_donors] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[financial_tbl_invoice_items] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_invoice_items](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[financial_invoice_id] [int] NOT NULL,
	[service_id] [int] NULL,
	[description] [nvarchar](500) NOT NULL,
	[quantity] [decimal](18, 4) NOT NULL,
	[unit_price] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 2) NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_financial_tbl_invoice_items] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[financial_tbl_payment_methods] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_payment_methods](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_financial_tbl_payment_methods] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[financial_tbl_receipt_items] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_receipt_items](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[financial_receipt_id] [int] NOT NULL,
	[inventory_item_id] [int] NULL,
	[description] [nvarchar](500) NOT NULL,
	[quantity] [decimal](18, 4) NOT NULL,
	[unit_cost] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 2) NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_financial_tbl_receipt_items] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[financial_tbl_receipts] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[financial_tbl_receipts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[receipt_number] [nvarchar](50) NOT NULL,
	[supplier_id] [int] NULL,
	[financial_donor_id] [int] NULL,
	[receipt_date] [date] NOT NULL,
	[status_id] [int] NOT NULL,
	[subtotal] [decimal](18, 2) NOT NULL,
	[tax_amount] [decimal](18, 2) NOT NULL,
	[total_amount] [decimal](18, 2) NOT NULL,
	[notes] [nvarchar](max) NULL,
	[created_by_user_id] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_financial_tbl_receipts] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[inventory_tbl_suppliers] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[inventory_tbl_suppliers](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](200) NOT NULL,
	[contact_name] [nvarchar](200) NULL,
	[phone] [nvarchar](30) NULL,
	[email] [nvarchar](256) NULL,
	[notes] [nvarchar](max) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_inventory_tbl_suppliers] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_allergies] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_allergies](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_allergies] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_conditions] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_conditions](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_conditions] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_medications] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_medications](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_medications] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_patient_care_plan_activities] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_patient_care_plan_activities](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_care_plan_id] [int] NOT NULL,
	[title] [nvarchar](200) NOT NULL,
	[description] [nvarchar](max) NULL,
	[due_date] [date] NULL,
	[completed_at] [datetime2](0) NULL,
	[status_id] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_patient_care_plan_activities] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_patient_care_plans] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_patient_care_plans](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[title] [nvarchar](200) NOT NULL,
	[description] [nvarchar](max) NULL,
	[start_date] [date] NULL,
	[end_date] [date] NULL,
	[status_id] [int] NOT NULL,
	[created_by_staff_id] [int] NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_patient_care_plans] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_record_attachments] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_record_attachments](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[medical_record_id] [int] NOT NULL,
	[patient_id] [int] NOT NULL,
	[document_type_id] [int] NOT NULL,
	[file_name] [nvarchar](255) NOT NULL,
	[file_path] [nvarchar](1000) NOT NULL,
	[content_type] [nvarchar](100) NULL,
	[file_size] [bigint] NULL,
	[uploaded_by_user_id] [int] NOT NULL,
	[uploaded_at] [datetime2](0) NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
 CONSTRAINT [pk_medical_tbl_record_attachments] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[medical_tbl_records] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[medical_tbl_records](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[record_number] [nvarchar](50) NOT NULL,
	[opened_at] [datetime2](0) NOT NULL,
	[closed_at] [datetime2](0) NULL,
	[status_id] [int] NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_medical_tbl_records] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[patient_tbl_contacts] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[patient_tbl_contacts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[patient_id] [int] NOT NULL,
	[contact_type_id] [int] NOT NULL,
	[full_name] [nvarchar](200) NOT NULL,
	[relationship] [nvarchar](100) NULL,
	[phone] [nvarchar](30) NULL,
	[email] [nvarchar](256) NULL,
	[is_primary_contact] [bit] NOT NULL,
	[is_emergency_contact] [bit] NOT NULL,
	[notes] [nvarchar](max) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_patient_tbl_contacts] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[service_tbl_event_notes] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_event_notes](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[service_event_id] [int] NOT NULL,
	[staff_member_id] [int] NULL,
	[note_type_id] [int] NOT NULL,
	[note_text] [nvarchar](max) NOT NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_service_tbl_event_notes] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[service_tbl_event_services] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_event_services](
	[service_event_id] [int] NOT NULL,
	[service_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_service_tbl_event_services] PRIMARY KEY CLUSTERED 
(
	[service_event_id] ASC,
	[service_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[service_tbl_event_staff] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_event_staff](
	[service_event_id] [int] NOT NULL,
	[staff_member_id] [int] NOT NULL,
	[role_in_event_id] [int] NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_service_tbl_event_staff] PRIMARY KEY CLUSTERED 
(
	[service_event_id] ASC,
	[staff_member_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[service_tbl_event_status_history] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_event_status_history](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[service_event_id] [int] NOT NULL,
	[old_status_id] [int] NULL,
	[new_status_id] [int] NOT NULL,
	[reason] [nvarchar](500) NULL,
	[changed_by_user_id] [int] NOT NULL,
	[changed_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_service_tbl_event_status_history] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[service_tbl_services] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[service_tbl_services](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_billable] [bit] NOT NULL,
	[default_price] [decimal](18, 2) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_service_tbl_services] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[staff_tbl_member_specialties] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[staff_tbl_member_specialties](
	[staff_member_id] [int] NOT NULL,
	[staff_specialty_id] [int] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
 CONSTRAINT [pk_staff_tbl_member_specialties] PRIMARY KEY CLUSTERED 
(
	[staff_member_id] ASC,
	[staff_specialty_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[staff_tbl_roles] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[staff_tbl_roles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](100) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_staff_tbl_roles] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[staff_tbl_specialties] Fecha de script: 23/7/2026 18:22:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[staff_tbl_specialties](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[description] [nvarchar](500) NULL,
	[is_active] [bit] NOT NULL,
	[deleted] [bit] NOT NULL,
	[created_at] [datetime2](0) NOT NULL,
	[updated_at] [datetime2](0) NULL,
 CONSTRAINT [pk_staff_tbl_specialties] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[access_tbl_permissions] ON 
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'access.users.read', N'Consultar usuarios.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'access.users.create', N'Crear usuarios.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'access.users.update', N'Actualizar usuarios.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'access.users.delete', N'Eliminar lógicamente usuarios.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'access.roles.manage', N'Gestionar roles y permisos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'access.audit.read', N'Consultar auditoría general del sistema.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'patients.read', N'Consultar pacientes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'patients.create', N'Crear pacientes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'patients.update', N'Actualizar pacientes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'patients.delete', N'Eliminar lógicamente pacientes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (11, N'patients.reports.read', N'Consultar reportes de pacientes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (12, N'staff.read', N'Consultar personal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (13, N'staff.create', N'Crear personal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (14, N'staff.update', N'Actualizar personal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (15, N'staff.delete', N'Eliminar lógicamente personal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (16, N'staff.availability.manage', N'Gestionar disponibilidad del personal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (17, N'medical.records.read', N'Ver resumen y detalle de expedientes médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (18, N'medical.records.create', N'Abrir expedientes médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (19, N'medical.records.update', N'Actualizar estado o metadatos del expediente médico.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (20, N'medical.notes.read', N'Ver notas clínicas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (21, N'medical.notes.create', N'Crear notas clínicas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (22, N'medical.conditions.manage', N'Gestionar condiciones médicas del paciente.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (23, N'medical.medications.manage', N'Gestionar medicamentos del paciente.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (24, N'medical.allergies.manage', N'Gestionar alergias del paciente.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (25, N'medical.vital_signs.read', N'Ver signos vitales.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (26, N'medical.vital_signs.create', N'Registrar signos vitales.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (27, N'medical.attachments.read', N'Ver o descargar adjuntos clínicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (28, N'medical.attachments.create', N'Cargar adjuntos clínicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (29, N'medical.reports.read', N'Consultar reportes médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (30, N'medical.access_audit.read', N'Consultar auditoría de acceso a expedientes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (31, N'service.events.read', N'Consultar agenda, citas y visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (32, N'service.events.create', N'Crear citas o visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (33, N'service.events.update', N'Actualizar citas o visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (34, N'service.events.cancel', N'Cancelar citas o visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (35, N'service.events.complete', N'Completar citas o visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (36, N'service.reports.read', N'Consultar reportes de citas y visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (37, N'inventory.items.read', N'Consultar inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (38, N'inventory.items.create', N'Crear insumos o recursos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (39, N'inventory.items.update', N'Actualizar insumos o recursos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (40, N'inventory.items.delete', N'Eliminar lógicamente insumos o recursos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (41, N'inventory.movements.create', N'Registrar movimientos de inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (42, N'inventory.reports.read', N'Consultar reportes de inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (43, N'financial.transactions.read', N'Consultar movimientos financieros.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (44, N'financial.transactions.create', N'Crear movimientos financieros.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (45, N'financial.invoices.create', N'Crear facturas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (46, N'financial.invoices.update', N'Actualizar facturas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (47, N'financial.receipts.create', N'Crear recibos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (48, N'financial.donors.manage', N'Gestionar donantes.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (49, N'financial.reports.read', N'Consultar reportes financieros.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (50, N'config.catalogs.manage', N'Gestionar catálogos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (51, N'config.settings.manage', N'Gestionar configuración general.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (52, N'config.document_types.manage', N'Gestionar tipos de documento.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (53, N'notifications.read', N'Consultar notificaciones.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_permissions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (54, N'system.errors.read', N'Consultar errores del sistema.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[access_tbl_permissions] OFF
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 1, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 2, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 3, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 4, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 5, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 6, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 7, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 8, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 9, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 10, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 11, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 12, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 13, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 14, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 15, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 16, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 17, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 18, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 19, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 20, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 21, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 22, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 23, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 24, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 25, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 26, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 27, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 28, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 29, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 30, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 31, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 32, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 33, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 34, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 35, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 36, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 37, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 38, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 39, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 40, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 41, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 42, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 43, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 44, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 45, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 46, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 47, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 48, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 49, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 50, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 51, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 52, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 53, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (1, 54, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 7, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 9, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 17, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 18, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 19, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 20, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 21, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 22, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 23, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 24, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 25, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 26, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 27, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 28, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 29, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 31, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (2, 35, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 7, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 17, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 20, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 21, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 25, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 26, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 27, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 31, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 33, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 35, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 37, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (3, 41, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (4, 37, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (4, 38, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (4, 39, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (4, 40, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (4, 41, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (4, 42, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 43, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 44, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 45, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 46, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 47, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 48, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (5, 49, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 7, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 8, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 9, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 11, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 12, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 31, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 32, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 33, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 34, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 36, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (6, 53, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_role_permissions] ([role_id], [permission_id], [created_at]) VALUES (7, 31, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
SET IDENTITY_INSERT [dbo].[access_tbl_roles] ON 
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Administrador', N'Acceso completo a configuración, seguridad, operación, reportes y auditoría.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Médico', N'Acceso clínico para expedientes, notas, diagnósticos, tratamientos y reportes médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Enfermería', N'Acceso clínico operativo para notas, signos vitales, visitas y consumo de insumos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Inventario', N'Gestión de insumos, lotes, existencias, entradas, salidas y reportes de inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Finanzas', N'Gestión de ingresos, egresos, donaciones, facturas, recibos y reportes financieros.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Administrativo', N'Gestión de pacientes, agenda, personal operativo y reportes generales.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Voluntario', N'Acceso limitado a agenda y actividades asignadas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Usuario', N'Acceso limitado', 1, 0, CAST(N'2026-07-16T08:56:01.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[access_tbl_roles] OFF
GO
INSERT [dbo].[access_tbl_user_roles] ([user_id], [role_id], [created_at]) VALUES (1, 1, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_user_roles] ([user_id], [role_id], [created_at]) VALUES (2, 2, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_user_roles] ([user_id], [role_id], [created_at]) VALUES (3, 6, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_user_roles] ([user_id], [role_id], [created_at]) VALUES (5, 8, CAST(N'2026-07-17T14:57:26.0000000' AS DateTime2))
GO
INSERT [dbo].[access_tbl_user_roles] ([user_id], [role_id], [created_at]) VALUES (6, 8, CAST(N'2026-07-19T11:26:18.0000000' AS DateTime2))
GO
SET IDENTITY_INSERT [dbo].[access_tbl_users] ON 
GO
INSERT [dbo].[access_tbl_users] ([id], [username], [email], [password], [full_name], [phone], [failed_login_attempts], [lockout_until], [last_login_at], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'admin.kronos', N'admin@kronos.local', N'Kronos2026!', N'Administrador Kronos', N'8888-0001', 0, NULL, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_users] ([id], [username], [email], [password], [full_name], [phone], [failed_login_attempts], [lockout_until], [last_login_at], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'medico.demo', N'medico@kronos.local', N'Kronos2026!', N'Médico de Prueba', N'8888-0002', 0, NULL, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_users] ([id], [username], [email], [password], [full_name], [phone], [failed_login_attempts], [lockout_until], [last_login_at], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'admin.operativo', N'operativo@kronos.local', N'Kronos2026!', N'Administrativo de Prueba', N'8888-0003', 0, NULL, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_users] ([id], [username], [email], [password], [full_name], [phone], [failed_login_attempts], [lockout_until], [last_login_at], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'anndy_madrigal26', N'anndymadrigal@gmail.com', N'$2a$11$KPU0JRa/QcCZ26/t/VOv.ebYc7CCsFRtW2fTYDKC7biFNpiMqdlfi', N'Anndy Madrigal Delgado', N'86927703', 0, NULL, CAST(N'2026-07-23T18:20:15.0000000' AS DateTime2), 1, 0, CAST(N'2026-07-17T14:57:26.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[access_tbl_users] ([id], [username], [email], [password], [full_name], [phone], [failed_login_attempts], [lockout_until], [last_login_at], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'totomancito', N'anndypandi86@gmail.com', N'$2a$11$udlNfxd18gDUI8y.jecZS.a8qx1poU3HqFiZVaFzzrKuGEnBT6D16', N'Josue Madrigal', N'89390153', 0, NULL, CAST(N'2026-07-19T11:42:42.0000000' AS DateTime2), 1, 0, CAST(N'2026-07-19T11:26:18.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[access_tbl_users] OFF
GO
SET IDENTITY_INSERT [dbo].[config_tbl_catalog_items] ON 
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, 1, N'Activo', N'active', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, 1, N'Inactivo', N'inactive', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, 1, N'Bloqueado', N'locked', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, 2, N'Activo', N'active', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, 2, N'Pendiente de valoración', N'pending_assessment', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, 2, N'En seguimiento', N'in_follow_up', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, 2, N'Egresado', N'discharged', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, 2, N'Suspendido', N'suspended', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, 2, N'Fallecido', N'deceased', 60, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, 2, N'Inactivo', N'inactive', 70, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (11, 3, N'Femenino', N'female', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (12, 3, N'Masculino', N'male', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (13, 3, N'Otro', N'other', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (14, 3, N'No especificado', N'unspecified', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (15, 4, N'Familiar', N'family', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (16, 4, N'Responsable legal', N'legal_guardian', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (17, 4, N'Cuidador principal', N'primary_caregiver', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (18, 4, N'Contacto de emergencia', N'emergency_contact', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (19, 4, N'Profesional externo', N'external_professional', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (20, 4, N'Otro', N'other', 60, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (21, 5, N'Manual', N'manual', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (22, 5, N'Horario laboral', N'work_schedule', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (23, 5, N'Permiso', N'leave', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (24, 5, N'Ausencia', N'absence', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (25, 6, N'Entrada', N'in', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (26, 6, N'Salida', N'out', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (27, 6, N'Ajuste', N'adjustment', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (28, 7, N'Compra', N'purchase', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (29, 7, N'Donación', N'donation', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (30, 7, N'Cita o visita', N'service_event', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (31, 7, N'Corrección de inventario', N'correction', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (32, 7, N'Traslado interno', N'internal_transfer', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (33, 7, N'Vencimiento', N'expiration', 60, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (34, 7, N'Daño o pérdida', N'damage_loss', 70, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (35, 8, N'Abierto', N'open', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (36, 8, N'Cerrado', N'closed', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (37, 8, N'Suspendido', N'suspended', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (38, 9, N'Visualización', N'view', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (39, 9, N'Exportación', N'export', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (40, 9, N'Descarga de adjunto', N'download', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (41, 9, N'Impresión', N'print', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (42, 10, N'Observación general', N'general_observation', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (43, 10, N'Evolución clínica', N'clinical_evolution', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (44, 10, N'Indicación médica', N'medical_instruction', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (45, 10, N'Nota de enfermería', N'nursing_note', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (46, 10, N'Resultado de visita', N'visit_result', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (47, 10, N'Otro', N'other', 60, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (48, 11, N'Activa', N'active', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (49, 11, N'Controlada', N'controlled', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (50, 11, N'Resuelta', N'resolved', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (51, 11, N'En observación', N'under_observation', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (52, 12, N'Leve', N'mild', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (53, 12, N'Moderada', N'moderate', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (54, 12, N'Severa', N'severe', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (55, 12, N'Crítica', N'critical', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (56, 12, N'Desconocida', N'unknown', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (57, 13, N'Activo', N'active', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (58, 13, N'En pausa', N'paused', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (59, 13, N'Finalizado', N'completed', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (60, 13, N'Cancelado', N'cancelled', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (61, 14, N'Pendiente', N'pending', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (62, 14, N'En proceso', N'in_progress', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (63, 14, N'Completada', N'completed', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (64, 14, N'Vencida', N'overdue', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (65, 14, N'Cancelada', N'cancelled', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (66, 15, N'Cita presencial', N'onsite_appointment', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (67, 15, N'Visita domiciliar', N'home_visit', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (68, 15, N'Control telefónico', N'phone_follow_up', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (69, 15, N'Actividad interna', N'internal_activity', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (70, 15, N'Otro', N'other', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (71, 16, N'Programada', N'scheduled', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (72, 16, N'Reprogramada', N'rescheduled', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (73, 16, N'En proceso', N'in_progress', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (74, 16, N'Completada', N'completed', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (75, 16, N'Cancelada', N'cancelled', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (76, 16, N'No se presentó', N'no_show', 60, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (77, 17, N'En sede', N'onsite', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (78, 17, N'Domicilio', N'home', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (79, 17, N'Externo', N'external', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (80, 17, N'Telefónico', N'phone', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (81, 17, N'Virtual', N'virtual', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (82, 18, N'Responsable principal', N'primary_responsible', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (83, 18, N'Médico', N'doctor', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (84, 18, N'Enfermería', N'nursing', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (85, 18, N'Voluntario', N'volunteer', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (86, 18, N'Apoyo administrativo', N'administrative_support', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (87, 19, N'Nota general', N'general', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (88, 19, N'Resultado', N'result', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (89, 19, N'Cancelación', N'cancellation', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (90, 19, N'Reprogramación', N'reschedule', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (91, 19, N'Seguimiento', N'follow_up', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (92, 20, N'Borrador', N'draft', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (93, 20, N'Emitida', N'issued', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (94, 20, N'Parcialmente pagada', N'partially_paid', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (95, 20, N'Pagada', N'paid', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (96, 20, N'Vencida', N'overdue', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (97, 20, N'Anulada', N'voided', 60, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (98, 21, N'Borrador', N'draft', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (99, 21, N'Registrado', N'registered', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (100, 21, N'Anulado', N'voided', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (101, 22, N'Ingreso', N'income', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (102, 22, N'Egreso', N'expense', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (103, 22, N'Ajuste', N'adjustment', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (104, 23, N'Correo electrónico', N'email', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (105, 23, N'Sistema', N'system', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (106, 23, N'Recordatorio', N'reminder', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (107, 23, N'Alerta de inventario', N'inventory_alert', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (108, 23, N'Recuperación de contraseña', N'password_reset', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (109, 24, N'Pendiente', N'pending', 10, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (110, 24, N'Enviada', N'sent', 20, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (111, 24, N'Fallida', N'failed', 30, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (112, 24, N'Reintentando', N'retrying', 40, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalog_items] ([id], [catalog_id], [name], [value], [sort_order], [is_active], [deleted], [created_at], [updated_at]) VALUES (113, 24, N'Cancelada', N'cancelled', 50, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[config_tbl_catalog_items] OFF
GO
SET IDENTITY_INSERT [dbo].[config_tbl_catalogs] ON 
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'user_status', N'Estados de usuarios del sistema.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'patient_status', N'Estados administrativos del paciente.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'gender', N'Opciones de género para formularios.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'contact_type', N'Tipos de contacto del paciente.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'staff_availability_source_type', N'Origen de disponibilidad del personal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'inventory_movement_type', N'Tipos de movimiento de inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'inventory_source_type', N'Origen operativo del movimiento de inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'medical_record_status', N'Estados de expediente médico.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'medical_record_access_type', N'Tipos de acceso a expedientes médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'medical_note_type', N'Tipos de notas clínicas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (11, N'condition_status', N'Estados de condición médica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (12, N'allergy_severity', N'Severidad de alergias.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (13, N'care_plan_status', N'Estados del plan de cuidado.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (14, N'care_plan_activity_status', N'Estados de actividades del plan de cuidado.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (15, N'service_event_type', N'Tipos de citas, visitas o eventos de servicio.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (16, N'service_event_status', N'Estados de citas, visitas o eventos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (17, N'service_event_location_type', N'Tipos de ubicación para citas o visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (18, N'service_event_staff_role', N'Rol del personal dentro de una cita o visita.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (19, N'service_event_note_type', N'Tipos de nota en citas o visitas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (20, N'financial_invoice_status', N'Estados de facturas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (21, N'financial_receipt_status', N'Estados de recibos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (22, N'financial_transaction_type', N'Tipos generales de movimientos financieros.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (23, N'notification_type', N'Tipos de notificación.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_catalogs] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (24, N'notification_status', N'Estados de notificación.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[config_tbl_catalogs] OFF
GO
SET IDENTITY_INSERT [dbo].[config_tbl_document_types] ON 
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Identificación', N'Cédula, documento de identidad o pasaporte.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Receta médica', N'Receta o indicación farmacológica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Resultado de laboratorio', N'Resultados de laboratorio clínico.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Epicrisis', N'Resumen clínico o documento de egreso.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Consentimiento informado', N'Documento de autorización o consentimiento.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Nota clínica externa', N'Documento clínico emitido fuera de la institución.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Comprobante financiero', N'Respaldo de pago, ingreso o egreso.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Factura o recibo', N'Documento tributario o comprobante.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Imagen médica', N'Imagen, fotografía clínica o estudio visual.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_document_types] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'Otro', N'Documento no clasificado.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[config_tbl_document_types] OFF
GO
SET IDENTITY_INSERT [dbo].[config_tbl_settings] ON 
GO
INSERT [dbo].[config_tbl_settings] ([id], [setting_type], [setting_name], [setting_value], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'site', N'app_name', N'Kronos', N'Nombre visible del sistema.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_settings] ([id], [setting_type], [setting_name], [setting_value], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'site', N'organization_name', N'Asociación de Cuidados Paliativos', N'Nombre institucional mostrado en reportes y encabezados.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_settings] ([id], [setting_type], [setting_name], [setting_value], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'files', N'medical_attachments_root', N'/uploads/medical-records', N'Ruta base para adjuntos de expedientes médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_settings] ([id], [setting_type], [setting_name], [setting_value], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'security', N'max_failed_login_attempts', N'3', N'Cantidad de intentos fallidos antes de bloqueo temporal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_settings] ([id], [setting_type], [setting_name], [setting_value], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'security', N'lockout_minutes', N'15', N'Minutos de bloqueo tras exceder intentos fallidos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[config_tbl_settings] ([id], [setting_type], [setting_name], [setting_value], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'financial', N'invoice_due_days', N'30', N'Días por defecto para vencimiento de facturas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[config_tbl_settings] OFF
GO
SET IDENTITY_INSERT [dbo].[financial_tbl_categories] ON 
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Donación monetaria', N'income', N'Aportes económicos recibidos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Pago de factura', N'income', N'Ingresos por facturas emitidas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Actividad de recaudación', N'income', N'Ingresos por actividades institucionales.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Alquiler de equipo', N'income', N'Ingresos por alquiler de equipo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Compra de medicamentos', N'expense', N'Egresos por compra de medicamentos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Compra de insumos', N'expense', N'Egresos por compra de insumos médicos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Gasto operativo', N'expense', N'Gastos generales de operación.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Gasto administrativo', N'expense', N'Gastos administrativos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Transporte', N'expense', N'Gastos de transporte para visitas o gestiones.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_categories] ([id], [name], [transaction_type], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'Ajuste financiero', N'adjustment', N'Ajustes o correcciones financieras.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[financial_tbl_categories] OFF
GO
SET IDENTITY_INSERT [dbo].[financial_tbl_payment_methods] ON 
GO
INSERT [dbo].[financial_tbl_payment_methods] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Efectivo', N'Pago o movimiento en efectivo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_payment_methods] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Transferencia bancaria', N'Transferencia bancaria o SINPE.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_payment_methods] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Tarjeta', N'Pago con tarjeta.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_payment_methods] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Cheque', N'Pago con cheque.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_payment_methods] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Depósito bancario', N'Depósito bancario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[financial_tbl_payment_methods] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Otro', N'Otro método de pago.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[financial_tbl_payment_methods] OFF
GO
SET IDENTITY_INSERT [dbo].[inventory_tbl_categories] ON 
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Medicamentos', N'Medicamentos de uso clínico o paliativo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Insumos médicos', N'Insumos consumibles para atención médica o de enfermería.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Material de curación', N'Gasas, apósitos, vendas y material similar.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Equipo médico', N'Equipos disponibles para uso, préstamo o alquiler.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Higiene y cuidado personal', N'Productos de higiene, confort y cuidado del paciente.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Oficina y administración', N'Insumos administrativos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Alimentos y suplementos', N'Alimentos, fórmulas o suplementos nutricionales.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_categories] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Otros', N'Otros recursos no clasificados.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[inventory_tbl_categories] OFF
GO
SET IDENTITY_INSERT [dbo].[inventory_tbl_items] ON 
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, 1, 2, N'Guantes de látex', N'Protección de manos', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, 1, 2, N'Mascarilla quirúrgica', N'Protección respiratoria', CAST(200.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, 1, 1, N'Jeringa 5ml', N'Aplicación de medicamentos', CAST(150.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, 1, 1, N'Jeringa 10ml', N'Aplicación de medicamentos', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, 1, 3, N'Gasas estériles', N'Curación de heridas', CAST(300.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, 1, 8, N'Venda elástica', N'Soporte y compresión', CAST(50.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, 1, 12, N'Algodón médico', N'Limpieza y curación', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, 1, 5, N'Alcohol 70%', N'Desinfección', CAST(80.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, 1, 4, N'Suero fisiológico', N'Lavado e hidratación', CAST(60.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, 1, 2, N'Curitas adhesivas', N'Cobertura de heridas', CAST(200.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (11, 1, 1, N'Termómetro digital', N'Medición de temperatura', CAST(20.0000 AS Decimal(18, 4)), 0, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (12, 1, 3, N'Baja lenguas', N'Examen oral', CAST(100.0000 AS Decimal(18, 4)), 0, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (13, 1, 1, N'Catéter intravenoso', N'Acceso venoso', CAST(50.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (14, 1, 1, N'Equipo de venoclisis', N'Administración de sueros', CAST(40.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (15, 1, 3, N'Apósito estéril', N'Protección de heridas', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (16, 1, 3, N'Hisopos estériles', N'Toma de muestras', CAST(150.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (17, 1, 2, N'Lancetas', N'Punción capilar', CAST(200.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (18, 1, 8, N'Micropore', N'Fijación de apósitos', CAST(50.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (19, 1, 8, N'Esparadrapo', N'Fijación médica', CAST(50.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (20, 1, 2, N'Gorro desechable', N'Protección sanitaria', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (21, 1, 2, N'Cubrezapatos', N'Protección sanitaria', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (22, 1, 1, N'Tijera quirúrgica', N'Corte de material médico', CAST(10.0000 AS Decimal(18, 4)), 0, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (23, 1, 1, N'Pinza clínica', N'Manipulación de material', CAST(10.0000 AS Decimal(18, 4)), 0, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (24, 1, 3, N'Compresas estériles', N'Curación de heridas', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (25, 1, 5, N'Agua oxigenada', N'Desinfección', CAST(30.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (26, 1, 5, N'Yodo povidona', N'Antisepsia de piel', CAST(30.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (27, 1, 4, N'Gel antibacterial', N'Higiene de manos', CAST(40.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (28, 1, 2, N'Toallas con alcohol', N'Desinfección rápida', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (29, 1, 7, N'Guantes estériles', N'Procedimientos médicos', CAST(50.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_items] ([id], [inventory_category_id], [inventory_unit_id], [name], [description], [minimum_stock], [requires_expiration_date], [is_active], [deleted], [created_at], [updated_at]) VALUES (30, 1, 3, N'Mascarilla N95', N'Protección respiratoria', CAST(100.0000 AS Decimal(18, 4)), 1, 1, 0, CAST(N'2026-07-23T17:54:19.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[inventory_tbl_items] OFF
GO
SET IDENTITY_INSERT [dbo].[inventory_tbl_units] ON 
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Unidad', N'unid', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Caja', N'caja', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Paquete', N'paq', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Frasco', N'frasco', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Botella', N'bot', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Bolsa', N'bolsa', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Par', N'par', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Rollo', N'rollo', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Mililitro', N'ml', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'Litro', N'l', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (11, N'Miligramo', N'mg', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (12, N'Gramo', N'g', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[inventory_tbl_units] ([id], [name], [abbreviation], [is_active], [deleted], [created_at], [updated_at]) VALUES (13, N'Kilogramo', N'kg', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[inventory_tbl_units] OFF
GO
SET IDENTITY_INSERT [dbo].[location_tbl_addresses] ON 
GO
INSERT [dbo].[location_tbl_addresses] ([id], [location_district_id], [address_line], [reference], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, 1, N'Dirección institucional pendiente de configurar', N'Dato inicial para configuración de sede.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[location_tbl_addresses] OFF
GO
SET IDENTITY_INSERT [dbo].[location_tbl_cantons] ON 
GO
INSERT [dbo].[location_tbl_cantons] ([id], [location_province_id], [name]) VALUES (1, 1, N'San José')
GO
SET IDENTITY_INSERT [dbo].[location_tbl_cantons] OFF
GO
SET IDENTITY_INSERT [dbo].[location_tbl_districts] ON 
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (1, 1, N'Carmen')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (4, 1, N'Catedral')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (10, 1, N'Hatillo')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (3, 1, N'Hospital')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (8, 1, N'Mata Redonda')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (2, 1, N'Merced')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (9, 1, N'Pavas')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (6, 1, N'San Francisco de Dos Ríos')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (11, 1, N'San Sebastián')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (7, 1, N'Uruca')
GO
INSERT [dbo].[location_tbl_districts] ([id], [location_canton_id], [name]) VALUES (5, 1, N'Zapote')
GO
SET IDENTITY_INSERT [dbo].[location_tbl_districts] OFF
GO
SET IDENTITY_INSERT [dbo].[location_tbl_locations] ON 
GO
INSERT [dbo].[location_tbl_locations] ([id], [name], [description], [address_id], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Sede principal', N'Ubicación principal de la organización.', 1, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[location_tbl_locations] ([id], [name], [description], [address_id], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Bodega principal', N'Almacenamiento principal de inventario.', 1, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[location_tbl_locations] ([id], [name], [description], [address_id], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Consultorio', N'Espacio para atención presencial.', 1, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[location_tbl_locations] OFF
GO
SET IDENTITY_INSERT [dbo].[location_tbl_provinces] ON 
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (2, N'Alajuela')
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (3, N'Cartago')
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (5, N'Guanacaste')
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (4, N'Heredia')
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (7, N'Limón')
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (6, N'Puntarenas')
GO
INSERT [dbo].[location_tbl_provinces] ([id], [name]) VALUES (1, N'San José')
GO
SET IDENTITY_INSERT [dbo].[location_tbl_provinces] OFF
GO
SET IDENTITY_INSERT [dbo].[medical_tbl_allergies] ON 
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Penicilina', N'Alergia a penicilina o derivados.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'AINEs', N'Alergia o sensibilidad a antiinflamatorios no esteroideos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Opioides', N'Alergia o reacción adversa a opioides.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Látex', N'Alergia al látex.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Alimentos', N'Alergias alimentarias.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Otra', N'Otra alergia no clasificada.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_allergies] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Desconocida', N'No se conoce alergia específica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[medical_tbl_allergies] OFF
GO
SET IDENTITY_INSERT [dbo].[medical_tbl_conditions] ON 
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Cáncer', N'Enfermedad oncológica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Insuficiencia cardíaca', N'Condición cardíaca avanzada.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Enfermedad pulmonar obstructiva crónica', N'Condición respiratoria crónica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Insuficiencia renal crónica', N'Condición renal crónica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Demencia', N'Deterioro cognitivo progresivo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Diabetes mellitus', N'Condición metabólica crónica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Hipertensión arterial', N'Presión arterial elevada.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Dolor crónico', N'Dolor persistente que requiere seguimiento.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_conditions] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Otra', N'Condición no clasificada.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[medical_tbl_conditions] OFF
GO
SET IDENTITY_INSERT [dbo].[medical_tbl_medications] ON 
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Morfina', N'Analgésico opioide de uso paliativo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Tramadol', N'Analgésico opioide.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Paracetamol', N'Analgésico y antipirético.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Ibuprofeno', N'Antiinflamatorio no esteroideo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Metoclopramida', N'Antiemético/procinético.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Omeprazol', N'Protector gástrico.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Lactulosa', N'Laxante.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Haloperidol', N'Antipsicótico/antiemético en contexto paliativo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Midazolam', N'Benzodiacepina.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[medical_tbl_medications] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'Otro', N'Medicamento no clasificado.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[medical_tbl_medications] OFF
GO
SET IDENTITY_INSERT [dbo].[service_tbl_services] ON 
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Consulta médica', N'Atención médica presencial o programada.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Visita domiciliar', N'Seguimiento en domicilio del paciente.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Control de signos vitales', N'Registro y revisión de signos vitales.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Curación', N'Atención de heridas o cambio de apósitos.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Entrega de medicamentos', N'Entrega controlada de medicamentos al paciente.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Apoyo psicológico', N'Acompañamiento psicológico.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Apoyo social', N'Gestión social o familiar.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Alquiler de equipo médico', N'Alquiler de equipo disponible.', 1, CAST(0.00 AS Decimal(18, 2)), 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Préstamo de equipo médico', N'Préstamo sin cobro de equipo disponible.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[service_tbl_services] ([id], [name], [description], [is_billable], [default_price], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'Otro servicio', N'Servicio no clasificado.', 0, NULL, 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[service_tbl_services] OFF
GO
SET IDENTITY_INSERT [dbo].[staff_tbl_roles] ON 
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Médico', N'Profesional médico responsable de atención clínica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Enfermería', N'Personal de enfermería para atención y seguimiento.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Psicología', N'Profesional de apoyo psicológico.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Trabajo social', N'Profesional de apoyo social y familiar.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Administrativo', N'Personal administrativo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Inventario', N'Personal responsable de inventario.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Finanzas', N'Personal responsable de finanzas.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_roles] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Voluntario', N'Persona voluntaria de apoyo operativo.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[staff_tbl_roles] OFF
GO
SET IDENTITY_INSERT [dbo].[staff_tbl_specialties] ON 
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (1, N'Cuidados paliativos', N'Atención integral para pacientes con enfermedad avanzada o terminal.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (2, N'Medicina general', N'Atención médica general.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (3, N'Enfermería paliativa', N'Cuidado de enfermería enfocado en control de síntomas y confort.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (4, N'Psicología clínica', N'Acompañamiento emocional y psicológico.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (5, N'Trabajo social', N'Acompañamiento social, familiar e institucional.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (6, N'Nutrición', N'Apoyo nutricional.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (7, N'Terapia física', N'Apoyo físico y funcional.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (8, N'Administración', N'Gestión administrativa.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (9, N'Gestión de inventario', N'Control de insumos, medicamentos y recursos.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
INSERT [dbo].[staff_tbl_specialties] ([id], [name], [description], [is_active], [deleted], [created_at], [updated_at]) VALUES (10, N'Finanzas', N'Gestión financiera y contable básica.', 1, 0, CAST(N'2026-07-09T22:54:06.0000000' AS DateTime2), NULL)
GO
SET IDENTITY_INSERT [dbo].[staff_tbl_specialties] OFF
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_access_tbl_password_reset_tokens_token] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[access_tbl_password_reset_tokens] ADD  CONSTRAINT [uq_access_tbl_password_reset_tokens_token] UNIQUE NONCLUSTERED 
(
	[token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_access_tbl_permissions_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[access_tbl_permissions] ADD  CONSTRAINT [uq_access_tbl_permissions_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_access_tbl_roles_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[access_tbl_roles] ADD  CONSTRAINT [uq_access_tbl_roles_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_access_tbl_users_email] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[access_tbl_users] ADD  CONSTRAINT [uq_access_tbl_users_email] UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_access_tbl_users_username] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[access_tbl_users] ADD  CONSTRAINT [uq_access_tbl_users_username] UNIQUE NONCLUSTERED 
(
	[username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_config_tbl_catalog_items_catalog_value] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[config_tbl_catalog_items] ADD  CONSTRAINT [uq_config_tbl_catalog_items_catalog_value] UNIQUE NONCLUSTERED 
(
	[catalog_id] ASC,
	[value] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_config_tbl_catalogs_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[config_tbl_catalogs] ADD  CONSTRAINT [uq_config_tbl_catalogs_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_config_tbl_document_types_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[config_tbl_document_types] ADD  CONSTRAINT [uq_config_tbl_document_types_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_config_tbl_settings_type_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[config_tbl_settings] ADD  CONSTRAINT [uq_config_tbl_settings_type_name] UNIQUE NONCLUSTERED 
(
	[setting_type] ASC,
	[setting_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_financial_tbl_categories_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[financial_tbl_categories] ADD  CONSTRAINT [uq_financial_tbl_categories_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_financial_tbl_donors_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[financial_tbl_donors] ADD  CONSTRAINT [uq_financial_tbl_donors_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_financial_tbl_invoices_number] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[financial_tbl_invoices] ADD  CONSTRAINT [uq_financial_tbl_invoices_number] UNIQUE NONCLUSTERED 
(
	[invoice_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_financial_tbl_payment_methods_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[financial_tbl_payment_methods] ADD  CONSTRAINT [uq_financial_tbl_payment_methods_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_financial_tbl_receipts_number] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[financial_tbl_receipts] ADD  CONSTRAINT [uq_financial_tbl_receipts_number] UNIQUE NONCLUSTERED 
(
	[receipt_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_inventory_tbl_categories_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[inventory_tbl_categories] ADD  CONSTRAINT [uq_inventory_tbl_categories_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_inventory_tbl_suppliers_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[inventory_tbl_suppliers] ADD  CONSTRAINT [uq_inventory_tbl_suppliers_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_inventory_tbl_units_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[inventory_tbl_units] ADD  CONSTRAINT [uq_inventory_tbl_units_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_location_tbl_cantons_province_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[location_tbl_cantons] ADD  CONSTRAINT [uq_location_tbl_cantons_province_name] UNIQUE NONCLUSTERED 
(
	[location_province_id] ASC,
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_location_tbl_districts_canton_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[location_tbl_districts] ADD  CONSTRAINT [uq_location_tbl_districts_canton_name] UNIQUE NONCLUSTERED 
(
	[location_canton_id] ASC,
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_location_tbl_locations_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[location_tbl_locations] ADD  CONSTRAINT [uq_location_tbl_locations_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_location_tbl_provinces_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[location_tbl_provinces] ADD  CONSTRAINT [uq_location_tbl_provinces_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_medical_tbl_allergies_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[medical_tbl_allergies] ADD  CONSTRAINT [uq_medical_tbl_allergies_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_medical_tbl_conditions_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[medical_tbl_conditions] ADD  CONSTRAINT [uq_medical_tbl_conditions_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_medical_tbl_medications_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[medical_tbl_medications] ADD  CONSTRAINT [uq_medical_tbl_medications_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_medical_tbl_records_number] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[medical_tbl_records] ADD  CONSTRAINT [uq_medical_tbl_records_number] UNIQUE NONCLUSTERED 
(
	[record_number] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_service_tbl_services_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[service_tbl_services] ADD  CONSTRAINT [uq_service_tbl_services_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_staff_tbl_roles_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[staff_tbl_roles] ADD  CONSTRAINT [uq_staff_tbl_roles_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [uq_staff_tbl_specialties_name] Fecha de script: 23/7/2026 18:22:30 ******/
ALTER TABLE [dbo].[staff_tbl_specialties] ADD  CONSTRAINT [uq_staff_tbl_specialties_name] UNIQUE NONCLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[access_tbl_audit_logs] ADD  CONSTRAINT [df_access_tbl_audit_logs_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_password_reset_tokens] ADD  CONSTRAINT [df_access_tbl_password_reset_tokens_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[access_tbl_password_reset_tokens] ADD  CONSTRAINT [df_access_tbl_password_reset_tokens_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_permissions] ADD  CONSTRAINT [df_access_tbl_permissions_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[access_tbl_permissions] ADD  CONSTRAINT [df_access_tbl_permissions_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[access_tbl_permissions] ADD  CONSTRAINT [df_access_tbl_permissions_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_role_permissions] ADD  CONSTRAINT [df_access_tbl_role_permissions_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_roles] ADD  CONSTRAINT [df_access_tbl_roles_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[access_tbl_roles] ADD  CONSTRAINT [df_access_tbl_roles_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[access_tbl_roles] ADD  CONSTRAINT [df_access_tbl_roles_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_user_roles] ADD  CONSTRAINT [df_access_tbl_user_roles_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_user_sessions] ADD  CONSTRAINT [df_access_tbl_user_sessions_is_revoked]  DEFAULT ((0)) FOR [is_revoked]
GO
ALTER TABLE [dbo].[access_tbl_user_sessions] ADD  CONSTRAINT [df_access_tbl_user_sessions_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[access_tbl_user_sessions] ADD  CONSTRAINT [df_access_tbl_user_sessions_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[access_tbl_user_sessions] ADD  CONSTRAINT [df_access_tbl_user_sessions_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_users] ADD  CONSTRAINT [df_access_tbl_users_failed_login_attempts]  DEFAULT ((0)) FOR [failed_login_attempts]
GO
ALTER TABLE [dbo].[access_tbl_users] ADD  CONSTRAINT [df_access_tbl_users_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[access_tbl_users] ADD  CONSTRAINT [df_access_tbl_users_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[access_tbl_users] ADD  CONSTRAINT [df_access_tbl_users_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[config_tbl_catalog_items] ADD  CONSTRAINT [df_config_tbl_catalog_items_sort_order]  DEFAULT ((0)) FOR [sort_order]
GO
ALTER TABLE [dbo].[config_tbl_catalog_items] ADD  CONSTRAINT [df_config_tbl_catalog_items_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[config_tbl_catalog_items] ADD  CONSTRAINT [df_config_tbl_catalog_items_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[config_tbl_catalog_items] ADD  CONSTRAINT [df_config_tbl_catalog_items_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[config_tbl_catalogs] ADD  CONSTRAINT [df_config_tbl_catalogs_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[config_tbl_catalogs] ADD  CONSTRAINT [df_config_tbl_catalogs_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[config_tbl_catalogs] ADD  CONSTRAINT [df_config_tbl_catalogs_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[config_tbl_document_types] ADD  CONSTRAINT [df_config_tbl_document_types_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[config_tbl_document_types] ADD  CONSTRAINT [df_config_tbl_document_types_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[config_tbl_document_types] ADD  CONSTRAINT [df_config_tbl_document_types_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[config_tbl_settings] ADD  CONSTRAINT [df_config_tbl_settings_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[config_tbl_settings] ADD  CONSTRAINT [df_config_tbl_settings_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[config_tbl_settings] ADD  CONSTRAINT [df_config_tbl_settings_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_categories] ADD  CONSTRAINT [df_financial_tbl_categories_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[financial_tbl_categories] ADD  CONSTRAINT [df_financial_tbl_categories_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[financial_tbl_categories] ADD  CONSTRAINT [df_financial_tbl_categories_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_donors] ADD  CONSTRAINT [df_financial_tbl_donors_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[financial_tbl_donors] ADD  CONSTRAINT [df_financial_tbl_donors_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[financial_tbl_donors] ADD  CONSTRAINT [df_financial_tbl_donors_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items] ADD  CONSTRAINT [df_financial_tbl_invoice_items_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_invoices] ADD  CONSTRAINT [df_financial_tbl_invoices_tax]  DEFAULT ((0)) FOR [tax_amount]
GO
ALTER TABLE [dbo].[financial_tbl_invoices] ADD  CONSTRAINT [df_financial_tbl_invoices_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[financial_tbl_invoices] ADD  CONSTRAINT [df_financial_tbl_invoices_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[financial_tbl_invoices] ADD  CONSTRAINT [df_financial_tbl_invoices_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_payment_methods] ADD  CONSTRAINT [df_financial_tbl_payment_methods_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[financial_tbl_payment_methods] ADD  CONSTRAINT [df_financial_tbl_payment_methods_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[financial_tbl_payment_methods] ADD  CONSTRAINT [df_financial_tbl_payment_methods_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items] ADD  CONSTRAINT [df_financial_tbl_receipt_items_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_receipts] ADD  CONSTRAINT [df_financial_tbl_receipts_tax]  DEFAULT ((0)) FOR [tax_amount]
GO
ALTER TABLE [dbo].[financial_tbl_receipts] ADD  CONSTRAINT [df_financial_tbl_receipts_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[financial_tbl_receipts] ADD  CONSTRAINT [df_financial_tbl_receipts_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[financial_tbl_receipts] ADD  CONSTRAINT [df_financial_tbl_receipts_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[financial_tbl_transactions] ADD  CONSTRAINT [df_financial_tbl_transactions_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[financial_tbl_transactions] ADD  CONSTRAINT [df_financial_tbl_transactions_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[financial_tbl_transactions] ADD  CONSTRAINT [df_financial_tbl_transactions_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inventory_tbl_batches] ADD  CONSTRAINT [df_inventory_tbl_batches_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[inventory_tbl_batches] ADD  CONSTRAINT [df_inventory_tbl_batches_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[inventory_tbl_batches] ADD  CONSTRAINT [df_inventory_tbl_batches_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inventory_tbl_categories] ADD  CONSTRAINT [df_inventory_tbl_categories_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[inventory_tbl_categories] ADD  CONSTRAINT [df_inventory_tbl_categories_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[inventory_tbl_categories] ADD  CONSTRAINT [df_inventory_tbl_categories_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inventory_tbl_items] ADD  CONSTRAINT [df_inventory_tbl_items_minimum_stock]  DEFAULT ((0)) FOR [minimum_stock]
GO
ALTER TABLE [dbo].[inventory_tbl_items] ADD  CONSTRAINT [df_inventory_tbl_items_requires_expiration]  DEFAULT ((0)) FOR [requires_expiration_date]
GO
ALTER TABLE [dbo].[inventory_tbl_items] ADD  CONSTRAINT [df_inventory_tbl_items_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[inventory_tbl_items] ADD  CONSTRAINT [df_inventory_tbl_items_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[inventory_tbl_items] ADD  CONSTRAINT [df_inventory_tbl_items_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inventory_tbl_movements] ADD  CONSTRAINT [df_inventory_tbl_movements_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inventory_tbl_suppliers] ADD  CONSTRAINT [df_inventory_tbl_suppliers_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[inventory_tbl_suppliers] ADD  CONSTRAINT [df_inventory_tbl_suppliers_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[inventory_tbl_suppliers] ADD  CONSTRAINT [df_inventory_tbl_suppliers_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[inventory_tbl_units] ADD  CONSTRAINT [df_inventory_tbl_units_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[inventory_tbl_units] ADD  CONSTRAINT [df_inventory_tbl_units_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[inventory_tbl_units] ADD  CONSTRAINT [df_inventory_tbl_units_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[location_tbl_addresses] ADD  CONSTRAINT [df_location_tbl_addresses_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[location_tbl_addresses] ADD  CONSTRAINT [df_location_tbl_addresses_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[location_tbl_addresses] ADD  CONSTRAINT [df_location_tbl_addresses_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[location_tbl_locations] ADD  CONSTRAINT [df_location_tbl_locations_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[location_tbl_locations] ADD  CONSTRAINT [df_location_tbl_locations_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[location_tbl_locations] ADD  CONSTRAINT [df_location_tbl_locations_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_allergies] ADD  CONSTRAINT [df_medical_tbl_allergies_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_allergies] ADD  CONSTRAINT [df_medical_tbl_allergies_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_allergies] ADD  CONSTRAINT [df_medical_tbl_allergies_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_conditions] ADD  CONSTRAINT [df_medical_tbl_conditions_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_conditions] ADD  CONSTRAINT [df_medical_tbl_conditions_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_conditions] ADD  CONSTRAINT [df_medical_tbl_conditions_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_medications] ADD  CONSTRAINT [df_medical_tbl_medications_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_medications] ADD  CONSTRAINT [df_medical_tbl_medications_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_medications] ADD  CONSTRAINT [df_medical_tbl_medications_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies] ADD  CONSTRAINT [df_medical_tbl_patient_allergies_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies] ADD  CONSTRAINT [df_medical_tbl_patient_allergies_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies] ADD  CONSTRAINT [df_medical_tbl_patient_allergies_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities] ADD  CONSTRAINT [df_medical_tbl_patient_care_plan_activities_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities] ADD  CONSTRAINT [df_medical_tbl_patient_care_plan_activities_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities] ADD  CONSTRAINT [df_medical_tbl_patient_care_plan_activities_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans] ADD  CONSTRAINT [df_medical_tbl_patient_care_plans_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans] ADD  CONSTRAINT [df_medical_tbl_patient_care_plans_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans] ADD  CONSTRAINT [df_medical_tbl_patient_care_plans_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions] ADD  CONSTRAINT [df_medical_tbl_patient_conditions_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions] ADD  CONSTRAINT [df_medical_tbl_patient_conditions_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions] ADD  CONSTRAINT [df_medical_tbl_patient_conditions_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications] ADD  CONSTRAINT [df_medical_tbl_patient_medications_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications] ADD  CONSTRAINT [df_medical_tbl_patient_medications_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications] ADD  CONSTRAINT [df_medical_tbl_patient_medications_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_patient_vital_signs] ADD  CONSTRAINT [df_medical_tbl_patient_vital_signs_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs] ADD  CONSTRAINT [df_medical_tbl_record_access_logs_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments] ADD  CONSTRAINT [df_medical_tbl_record_attachments_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments] ADD  CONSTRAINT [df_medical_tbl_record_attachments_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] ADD  CONSTRAINT [df_medical_tbl_record_notes_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] ADD  CONSTRAINT [df_medical_tbl_record_notes_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] ADD  CONSTRAINT [df_medical_tbl_record_notes_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[medical_tbl_records] ADD  CONSTRAINT [df_medical_tbl_records_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[medical_tbl_records] ADD  CONSTRAINT [df_medical_tbl_records_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[medical_tbl_records] ADD  CONSTRAINT [df_medical_tbl_records_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[notification_tbl_logs] ADD  CONSTRAINT [df_notification_tbl_logs_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[patient_tbl_contacts] ADD  CONSTRAINT [df_patient_tbl_contacts_is_primary]  DEFAULT ((0)) FOR [is_primary_contact]
GO
ALTER TABLE [dbo].[patient_tbl_contacts] ADD  CONSTRAINT [df_patient_tbl_contacts_is_emergency]  DEFAULT ((0)) FOR [is_emergency_contact]
GO
ALTER TABLE [dbo].[patient_tbl_contacts] ADD  CONSTRAINT [df_patient_tbl_contacts_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[patient_tbl_contacts] ADD  CONSTRAINT [df_patient_tbl_contacts_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[patient_tbl_contacts] ADD  CONSTRAINT [df_patient_tbl_contacts_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[patient_tbl_patients] ADD  CONSTRAINT [df_patient_tbl_patients_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[patient_tbl_patients] ADD  CONSTRAINT [df_patient_tbl_patients_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[patient_tbl_patients] ADD  CONSTRAINT [df_patient_tbl_patients_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage] ADD  CONSTRAINT [df_service_tbl_event_inventory_usage_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[service_tbl_event_notes] ADD  CONSTRAINT [df_service_tbl_event_notes_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[service_tbl_event_notes] ADD  CONSTRAINT [df_service_tbl_event_notes_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[service_tbl_event_notes] ADD  CONSTRAINT [df_service_tbl_event_notes_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[service_tbl_event_services] ADD  CONSTRAINT [df_service_tbl_event_services_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[service_tbl_event_staff] ADD  CONSTRAINT [df_service_tbl_event_staff_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[service_tbl_events] ADD  CONSTRAINT [df_service_tbl_events_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[service_tbl_events] ADD  CONSTRAINT [df_service_tbl_events_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[service_tbl_events] ADD  CONSTRAINT [df_service_tbl_events_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[service_tbl_services] ADD  CONSTRAINT [df_service_tbl_services_is_billable]  DEFAULT ((0)) FOR [is_billable]
GO
ALTER TABLE [dbo].[service_tbl_services] ADD  CONSTRAINT [df_service_tbl_services_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[service_tbl_services] ADD  CONSTRAINT [df_service_tbl_services_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[service_tbl_services] ADD  CONSTRAINT [df_service_tbl_services_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[staff_tbl_availability] ADD  CONSTRAINT [df_staff_tbl_availability_is_available]  DEFAULT ((1)) FOR [is_available]
GO
ALTER TABLE [dbo].[staff_tbl_availability] ADD  CONSTRAINT [df_staff_tbl_availability_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[staff_tbl_availability] ADD  CONSTRAINT [df_staff_tbl_availability_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[staff_tbl_member_specialties] ADD  CONSTRAINT [df_staff_tbl_member_specialties_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[staff_tbl_members] ADD  CONSTRAINT [df_staff_tbl_members_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[staff_tbl_members] ADD  CONSTRAINT [df_staff_tbl_members_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[staff_tbl_members] ADD  CONSTRAINT [df_staff_tbl_members_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[staff_tbl_roles] ADD  CONSTRAINT [df_staff_tbl_roles_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[staff_tbl_roles] ADD  CONSTRAINT [df_staff_tbl_roles_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[staff_tbl_roles] ADD  CONSTRAINT [df_staff_tbl_roles_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[staff_tbl_specialties] ADD  CONSTRAINT [df_staff_tbl_specialties_is_active]  DEFAULT ((1)) FOR [is_active]
GO
ALTER TABLE [dbo].[staff_tbl_specialties] ADD  CONSTRAINT [df_staff_tbl_specialties_deleted]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[staff_tbl_specialties] ADD  CONSTRAINT [df_staff_tbl_specialties_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[system_tbl_error_logs] ADD  CONSTRAINT [df_system_tbl_error_logs_created_at]  DEFAULT (sysdatetime()) FOR [created_at]
GO
ALTER TABLE [dbo].[access_tbl_audit_logs]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_audit_logs_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[access_tbl_audit_logs] CHECK CONSTRAINT [fk_access_tbl_audit_logs_user]
GO
ALTER TABLE [dbo].[access_tbl_password_reset_tokens]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_password_reset_tokens_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[access_tbl_password_reset_tokens] CHECK CONSTRAINT [fk_access_tbl_password_reset_tokens_user]
GO
ALTER TABLE [dbo].[access_tbl_role_permissions]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_role_permissions_permission] FOREIGN KEY([permission_id])
REFERENCES [dbo].[access_tbl_permissions] ([id])
GO
ALTER TABLE [dbo].[access_tbl_role_permissions] CHECK CONSTRAINT [fk_access_tbl_role_permissions_permission]
GO
ALTER TABLE [dbo].[access_tbl_role_permissions]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_role_permissions_role] FOREIGN KEY([role_id])
REFERENCES [dbo].[access_tbl_roles] ([id])
GO
ALTER TABLE [dbo].[access_tbl_role_permissions] CHECK CONSTRAINT [fk_access_tbl_role_permissions_role]
GO
ALTER TABLE [dbo].[access_tbl_user_roles]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_user_roles_role] FOREIGN KEY([role_id])
REFERENCES [dbo].[access_tbl_roles] ([id])
GO
ALTER TABLE [dbo].[access_tbl_user_roles] CHECK CONSTRAINT [fk_access_tbl_user_roles_role]
GO
ALTER TABLE [dbo].[access_tbl_user_roles]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_user_roles_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[access_tbl_user_roles] CHECK CONSTRAINT [fk_access_tbl_user_roles_user]
GO
ALTER TABLE [dbo].[access_tbl_user_sessions]  WITH CHECK ADD  CONSTRAINT [fk_access_tbl_user_sessions_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[access_tbl_user_sessions] CHECK CONSTRAINT [fk_access_tbl_user_sessions_user]
GO
ALTER TABLE [dbo].[config_tbl_catalog_items]  WITH CHECK ADD  CONSTRAINT [fk_config_tbl_catalog_items_catalog] FOREIGN KEY([catalog_id])
REFERENCES [dbo].[config_tbl_catalogs] ([id])
GO
ALTER TABLE [dbo].[config_tbl_catalog_items] CHECK CONSTRAINT [fk_config_tbl_catalog_items_catalog]
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_invoice_items_invoice] FOREIGN KEY([financial_invoice_id])
REFERENCES [dbo].[financial_tbl_invoices] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items] CHECK CONSTRAINT [fk_financial_tbl_invoice_items_invoice]
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_invoice_items_service] FOREIGN KEY([service_id])
REFERENCES [dbo].[service_tbl_services] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items] CHECK CONSTRAINT [fk_financial_tbl_invoice_items_service]
GO
ALTER TABLE [dbo].[financial_tbl_invoices]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_invoices_created_by] FOREIGN KEY([created_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_invoices] CHECK CONSTRAINT [fk_financial_tbl_invoices_created_by]
GO
ALTER TABLE [dbo].[financial_tbl_invoices]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_invoices_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_invoices] CHECK CONSTRAINT [fk_financial_tbl_invoices_patient]
GO
ALTER TABLE [dbo].[financial_tbl_invoices]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_invoices_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_invoices] CHECK CONSTRAINT [fk_financial_tbl_invoices_status]
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_receipt_items_item] FOREIGN KEY([inventory_item_id])
REFERENCES [dbo].[inventory_tbl_items] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items] CHECK CONSTRAINT [fk_financial_tbl_receipt_items_item]
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_receipt_items_receipt] FOREIGN KEY([financial_receipt_id])
REFERENCES [dbo].[financial_tbl_receipts] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items] CHECK CONSTRAINT [fk_financial_tbl_receipt_items_receipt]
GO
ALTER TABLE [dbo].[financial_tbl_receipts]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_receipts_created_by] FOREIGN KEY([created_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_receipts] CHECK CONSTRAINT [fk_financial_tbl_receipts_created_by]
GO
ALTER TABLE [dbo].[financial_tbl_receipts]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_receipts_donor] FOREIGN KEY([financial_donor_id])
REFERENCES [dbo].[financial_tbl_donors] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_receipts] CHECK CONSTRAINT [fk_financial_tbl_receipts_donor]
GO
ALTER TABLE [dbo].[financial_tbl_receipts]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_receipts_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_receipts] CHECK CONSTRAINT [fk_financial_tbl_receipts_status]
GO
ALTER TABLE [dbo].[financial_tbl_receipts]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_receipts_supplier] FOREIGN KEY([supplier_id])
REFERENCES [dbo].[inventory_tbl_suppliers] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_receipts] CHECK CONSTRAINT [fk_financial_tbl_receipts_supplier]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_category] FOREIGN KEY([financial_category_id])
REFERENCES [dbo].[financial_tbl_categories] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_category]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_created_by] FOREIGN KEY([created_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_created_by]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_donor] FOREIGN KEY([financial_donor_id])
REFERENCES [dbo].[financial_tbl_donors] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_donor]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_inventory_movement] FOREIGN KEY([inventory_movement_id])
REFERENCES [dbo].[inventory_tbl_movements] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_inventory_movement]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_invoice] FOREIGN KEY([financial_invoice_id])
REFERENCES [dbo].[financial_tbl_invoices] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_invoice]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_patient]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_payment_method] FOREIGN KEY([financial_payment_method_id])
REFERENCES [dbo].[financial_tbl_payment_methods] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_payment_method]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_receipt] FOREIGN KEY([financial_receipt_id])
REFERENCES [dbo].[financial_tbl_receipts] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_receipt]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_service_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_service_event]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [fk_financial_tbl_transactions_supplier] FOREIGN KEY([supplier_id])
REFERENCES [dbo].[inventory_tbl_suppliers] ([id])
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [fk_financial_tbl_transactions_supplier]
GO
ALTER TABLE [dbo].[inventory_tbl_batches]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_batches_item] FOREIGN KEY([inventory_item_id])
REFERENCES [dbo].[inventory_tbl_items] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_batches] CHECK CONSTRAINT [fk_inventory_tbl_batches_item]
GO
ALTER TABLE [dbo].[inventory_tbl_batches]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_batches_location] FOREIGN KEY([location_id])
REFERENCES [dbo].[location_tbl_locations] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_batches] CHECK CONSTRAINT [fk_inventory_tbl_batches_location]
GO
ALTER TABLE [dbo].[inventory_tbl_items]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_items_category] FOREIGN KEY([inventory_category_id])
REFERENCES [dbo].[inventory_tbl_categories] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_items] CHECK CONSTRAINT [fk_inventory_tbl_items_category]
GO
ALTER TABLE [dbo].[inventory_tbl_items]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_items_unit] FOREIGN KEY([inventory_unit_id])
REFERENCES [dbo].[inventory_tbl_units] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_items] CHECK CONSTRAINT [fk_inventory_tbl_items_unit]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_batch] FOREIGN KEY([inventory_batch_id])
REFERENCES [dbo].[inventory_tbl_batches] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_batch]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_donor] FOREIGN KEY([financial_donor_id])
REFERENCES [dbo].[financial_tbl_donors] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_donor]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_item] FOREIGN KEY([inventory_item_id])
REFERENCES [dbo].[inventory_tbl_items] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_item]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_location] FOREIGN KEY([location_id])
REFERENCES [dbo].[location_tbl_locations] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_location]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_source] FOREIGN KEY([source_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_source]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_supplier] FOREIGN KEY([supplier_id])
REFERENCES [dbo].[inventory_tbl_suppliers] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_supplier]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_type] FOREIGN KEY([movement_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_type]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [fk_inventory_tbl_movements_user] FOREIGN KEY([created_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [fk_inventory_tbl_movements_user]
GO
ALTER TABLE [dbo].[location_tbl_addresses]  WITH CHECK ADD  CONSTRAINT [fk_location_tbl_addresses_district] FOREIGN KEY([location_district_id])
REFERENCES [dbo].[location_tbl_districts] ([id])
GO
ALTER TABLE [dbo].[location_tbl_addresses] CHECK CONSTRAINT [fk_location_tbl_addresses_district]
GO
ALTER TABLE [dbo].[location_tbl_cantons]  WITH CHECK ADD  CONSTRAINT [fk_location_tbl_cantons_province] FOREIGN KEY([location_province_id])
REFERENCES [dbo].[location_tbl_provinces] ([id])
GO
ALTER TABLE [dbo].[location_tbl_cantons] CHECK CONSTRAINT [fk_location_tbl_cantons_province]
GO
ALTER TABLE [dbo].[location_tbl_districts]  WITH CHECK ADD  CONSTRAINT [fk_location_tbl_districts_canton] FOREIGN KEY([location_canton_id])
REFERENCES [dbo].[location_tbl_cantons] ([id])
GO
ALTER TABLE [dbo].[location_tbl_districts] CHECK CONSTRAINT [fk_location_tbl_districts_canton]
GO
ALTER TABLE [dbo].[location_tbl_locations]  WITH CHECK ADD  CONSTRAINT [fk_location_tbl_locations_address] FOREIGN KEY([address_id])
REFERENCES [dbo].[location_tbl_addresses] ([id])
GO
ALTER TABLE [dbo].[location_tbl_locations] CHECK CONSTRAINT [fk_location_tbl_locations_address]
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_allergies_allergy] FOREIGN KEY([medical_allergy_id])
REFERENCES [dbo].[medical_tbl_allergies] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies] CHECK CONSTRAINT [fk_medical_tbl_patient_allergies_allergy]
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_allergies_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies] CHECK CONSTRAINT [fk_medical_tbl_patient_allergies_patient]
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_allergies_severity] FOREIGN KEY([severity_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_allergies] CHECK CONSTRAINT [fk_medical_tbl_patient_allergies_severity]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_care_plan_activities_plan] FOREIGN KEY([patient_care_plan_id])
REFERENCES [dbo].[medical_tbl_patient_care_plans] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities] CHECK CONSTRAINT [fk_medical_tbl_patient_care_plan_activities_plan]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_care_plan_activities_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plan_activities] CHECK CONSTRAINT [fk_medical_tbl_patient_care_plan_activities_status]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_care_plans_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans] CHECK CONSTRAINT [fk_medical_tbl_patient_care_plans_patient]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_care_plans_staff] FOREIGN KEY([created_by_staff_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans] CHECK CONSTRAINT [fk_medical_tbl_patient_care_plans_staff]
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_care_plans_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_care_plans] CHECK CONSTRAINT [fk_medical_tbl_patient_care_plans_status]
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_conditions_condition] FOREIGN KEY([medical_condition_id])
REFERENCES [dbo].[medical_tbl_conditions] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions] CHECK CONSTRAINT [fk_medical_tbl_patient_conditions_condition]
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_conditions_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions] CHECK CONSTRAINT [fk_medical_tbl_patient_conditions_patient]
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_conditions_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_conditions] CHECK CONSTRAINT [fk_medical_tbl_patient_conditions_status]
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_medications_medication] FOREIGN KEY([medical_medication_id])
REFERENCES [dbo].[medical_tbl_medications] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications] CHECK CONSTRAINT [fk_medical_tbl_patient_medications_medication]
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_medications_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_medications] CHECK CONSTRAINT [fk_medical_tbl_patient_medications_patient]
GO
ALTER TABLE [dbo].[medical_tbl_patient_vital_signs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_vital_signs_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_vital_signs] CHECK CONSTRAINT [fk_medical_tbl_patient_vital_signs_patient]
GO
ALTER TABLE [dbo].[medical_tbl_patient_vital_signs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_patient_vital_signs_staff] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_patient_vital_signs] CHECK CONSTRAINT [fk_medical_tbl_patient_vital_signs_staff]
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_access_logs_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs] CHECK CONSTRAINT [fk_medical_tbl_record_access_logs_patient]
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_access_logs_record] FOREIGN KEY([medical_record_id])
REFERENCES [dbo].[medical_tbl_records] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs] CHECK CONSTRAINT [fk_medical_tbl_record_access_logs_record]
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_access_logs_staff] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs] CHECK CONSTRAINT [fk_medical_tbl_record_access_logs_staff]
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_access_logs_type] FOREIGN KEY([access_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs] CHECK CONSTRAINT [fk_medical_tbl_record_access_logs_type]
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_access_logs_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_access_logs] CHECK CONSTRAINT [fk_medical_tbl_record_access_logs_user]
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_attachments_document_type] FOREIGN KEY([document_type_id])
REFERENCES [dbo].[config_tbl_document_types] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments] CHECK CONSTRAINT [fk_medical_tbl_record_attachments_document_type]
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_attachments_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments] CHECK CONSTRAINT [fk_medical_tbl_record_attachments_patient]
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_attachments_record] FOREIGN KEY([medical_record_id])
REFERENCES [dbo].[medical_tbl_records] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments] CHECK CONSTRAINT [fk_medical_tbl_record_attachments_record]
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_attachments_user] FOREIGN KEY([uploaded_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_attachments] CHECK CONSTRAINT [fk_medical_tbl_record_attachments_user]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_notes_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] CHECK CONSTRAINT [fk_medical_tbl_record_notes_patient]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_notes_record] FOREIGN KEY([medical_record_id])
REFERENCES [dbo].[medical_tbl_records] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] CHECK CONSTRAINT [fk_medical_tbl_record_notes_record]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_notes_staff] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] CHECK CONSTRAINT [fk_medical_tbl_record_notes_staff]
GO
ALTER TABLE [dbo].[medical_tbl_record_notes]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_record_notes_type] FOREIGN KEY([note_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_record_notes] CHECK CONSTRAINT [fk_medical_tbl_record_notes_type]
GO
ALTER TABLE [dbo].[medical_tbl_records]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_records_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_records] CHECK CONSTRAINT [fk_medical_tbl_records_patient]
GO
ALTER TABLE [dbo].[medical_tbl_records]  WITH CHECK ADD  CONSTRAINT [fk_medical_tbl_records_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[medical_tbl_records] CHECK CONSTRAINT [fk_medical_tbl_records_status]
GO
ALTER TABLE [dbo].[notification_tbl_logs]  WITH CHECK ADD  CONSTRAINT [fk_notification_tbl_logs_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[notification_tbl_logs] CHECK CONSTRAINT [fk_notification_tbl_logs_patient]
GO
ALTER TABLE [dbo].[notification_tbl_logs]  WITH CHECK ADD  CONSTRAINT [fk_notification_tbl_logs_service_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[notification_tbl_logs] CHECK CONSTRAINT [fk_notification_tbl_logs_service_event]
GO
ALTER TABLE [dbo].[notification_tbl_logs]  WITH CHECK ADD  CONSTRAINT [fk_notification_tbl_logs_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[notification_tbl_logs] CHECK CONSTRAINT [fk_notification_tbl_logs_status]
GO
ALTER TABLE [dbo].[notification_tbl_logs]  WITH CHECK ADD  CONSTRAINT [fk_notification_tbl_logs_type] FOREIGN KEY([notification_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[notification_tbl_logs] CHECK CONSTRAINT [fk_notification_tbl_logs_type]
GO
ALTER TABLE [dbo].[notification_tbl_logs]  WITH CHECK ADD  CONSTRAINT [fk_notification_tbl_logs_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[notification_tbl_logs] CHECK CONSTRAINT [fk_notification_tbl_logs_user]
GO
ALTER TABLE [dbo].[patient_tbl_contacts]  WITH CHECK ADD  CONSTRAINT [fk_patient_tbl_contacts_contact_type] FOREIGN KEY([contact_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[patient_tbl_contacts] CHECK CONSTRAINT [fk_patient_tbl_contacts_contact_type]
GO
ALTER TABLE [dbo].[patient_tbl_contacts]  WITH CHECK ADD  CONSTRAINT [fk_patient_tbl_contacts_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[patient_tbl_contacts] CHECK CONSTRAINT [fk_patient_tbl_contacts_patient]
GO
ALTER TABLE [dbo].[patient_tbl_patients]  WITH CHECK ADD  CONSTRAINT [fk_patient_tbl_patients_address] FOREIGN KEY([address_id])
REFERENCES [dbo].[location_tbl_addresses] ([id])
GO
ALTER TABLE [dbo].[patient_tbl_patients] CHECK CONSTRAINT [fk_patient_tbl_patients_address]
GO
ALTER TABLE [dbo].[patient_tbl_patients]  WITH CHECK ADD  CONSTRAINT [fk_patient_tbl_patients_gender] FOREIGN KEY([gender_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[patient_tbl_patients] CHECK CONSTRAINT [fk_patient_tbl_patients_gender]
GO
ALTER TABLE [dbo].[patient_tbl_patients]  WITH CHECK ADD  CONSTRAINT [fk_patient_tbl_patients_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[patient_tbl_patients] CHECK CONSTRAINT [fk_patient_tbl_patients_status]
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_inventory_usage_batch] FOREIGN KEY([inventory_batch_id])
REFERENCES [dbo].[inventory_tbl_batches] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage] CHECK CONSTRAINT [fk_service_tbl_event_inventory_usage_batch]
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_inventory_usage_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage] CHECK CONSTRAINT [fk_service_tbl_event_inventory_usage_event]
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_inventory_usage_item] FOREIGN KEY([inventory_item_id])
REFERENCES [dbo].[inventory_tbl_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage] CHECK CONSTRAINT [fk_service_tbl_event_inventory_usage_item]
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_inventory_usage_user] FOREIGN KEY([created_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage] CHECK CONSTRAINT [fk_service_tbl_event_inventory_usage_user]
GO
ALTER TABLE [dbo].[service_tbl_event_notes]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_notes_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_notes] CHECK CONSTRAINT [fk_service_tbl_event_notes_event]
GO
ALTER TABLE [dbo].[service_tbl_event_notes]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_notes_staff] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_notes] CHECK CONSTRAINT [fk_service_tbl_event_notes_staff]
GO
ALTER TABLE [dbo].[service_tbl_event_notes]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_notes_type] FOREIGN KEY([note_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_notes] CHECK CONSTRAINT [fk_service_tbl_event_notes_type]
GO
ALTER TABLE [dbo].[service_tbl_event_services]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_services_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_services] CHECK CONSTRAINT [fk_service_tbl_event_services_event]
GO
ALTER TABLE [dbo].[service_tbl_event_services]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_services_service] FOREIGN KEY([service_id])
REFERENCES [dbo].[service_tbl_services] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_services] CHECK CONSTRAINT [fk_service_tbl_event_services_service]
GO
ALTER TABLE [dbo].[service_tbl_event_staff]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_staff_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_staff] CHECK CONSTRAINT [fk_service_tbl_event_staff_event]
GO
ALTER TABLE [dbo].[service_tbl_event_staff]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_staff_role] FOREIGN KEY([role_in_event_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_staff] CHECK CONSTRAINT [fk_service_tbl_event_staff_role]
GO
ALTER TABLE [dbo].[service_tbl_event_staff]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_staff_staff] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_staff] CHECK CONSTRAINT [fk_service_tbl_event_staff_staff]
GO
ALTER TABLE [dbo].[service_tbl_event_status_history]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_status_history_event] FOREIGN KEY([service_event_id])
REFERENCES [dbo].[service_tbl_events] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_status_history] CHECK CONSTRAINT [fk_service_tbl_event_status_history_event]
GO
ALTER TABLE [dbo].[service_tbl_event_status_history]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_status_history_new_status] FOREIGN KEY([new_status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_status_history] CHECK CONSTRAINT [fk_service_tbl_event_status_history_new_status]
GO
ALTER TABLE [dbo].[service_tbl_event_status_history]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_status_history_old_status] FOREIGN KEY([old_status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_status_history] CHECK CONSTRAINT [fk_service_tbl_event_status_history_old_status]
GO
ALTER TABLE [dbo].[service_tbl_event_status_history]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_event_status_history_user] FOREIGN KEY([changed_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[service_tbl_event_status_history] CHECK CONSTRAINT [fk_service_tbl_event_status_history_user]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_address] FOREIGN KEY([address_id])
REFERENCES [dbo].[location_tbl_addresses] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_address]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_created_by] FOREIGN KEY([created_by_user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_created_by]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_location] FOREIGN KEY([location_id])
REFERENCES [dbo].[location_tbl_locations] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_location]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_location_type] FOREIGN KEY([location_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_location_type]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_main_staff] FOREIGN KEY([main_staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_main_staff]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_patient] FOREIGN KEY([patient_id])
REFERENCES [dbo].[patient_tbl_patients] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_patient]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_status]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [fk_service_tbl_events_type] FOREIGN KEY([event_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [fk_service_tbl_events_type]
GO
ALTER TABLE [dbo].[staff_tbl_availability]  WITH CHECK ADD  CONSTRAINT [fk_staff_tbl_availability_member] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[staff_tbl_availability] CHECK CONSTRAINT [fk_staff_tbl_availability_member]
GO
ALTER TABLE [dbo].[staff_tbl_availability]  WITH CHECK ADD  CONSTRAINT [fk_staff_tbl_availability_source_type] FOREIGN KEY([source_type_id])
REFERENCES [dbo].[config_tbl_catalog_items] ([id])
GO
ALTER TABLE [dbo].[staff_tbl_availability] CHECK CONSTRAINT [fk_staff_tbl_availability_source_type]
GO
ALTER TABLE [dbo].[staff_tbl_member_specialties]  WITH CHECK ADD  CONSTRAINT [fk_staff_tbl_member_specialties_member] FOREIGN KEY([staff_member_id])
REFERENCES [dbo].[staff_tbl_members] ([id])
GO
ALTER TABLE [dbo].[staff_tbl_member_specialties] CHECK CONSTRAINT [fk_staff_tbl_member_specialties_member]
GO
ALTER TABLE [dbo].[staff_tbl_member_specialties]  WITH CHECK ADD  CONSTRAINT [fk_staff_tbl_member_specialties_specialty] FOREIGN KEY([staff_specialty_id])
REFERENCES [dbo].[staff_tbl_specialties] ([id])
GO
ALTER TABLE [dbo].[staff_tbl_member_specialties] CHECK CONSTRAINT [fk_staff_tbl_member_specialties_specialty]
GO
ALTER TABLE [dbo].[staff_tbl_members]  WITH CHECK ADD  CONSTRAINT [fk_staff_tbl_members_role] FOREIGN KEY([staff_role_id])
REFERENCES [dbo].[staff_tbl_roles] ([id])
GO
ALTER TABLE [dbo].[staff_tbl_members] CHECK CONSTRAINT [fk_staff_tbl_members_role]
GO
ALTER TABLE [dbo].[staff_tbl_members]  WITH CHECK ADD  CONSTRAINT [fk_staff_tbl_members_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[staff_tbl_members] CHECK CONSTRAINT [fk_staff_tbl_members_user]
GO
ALTER TABLE [dbo].[system_tbl_error_logs]  WITH CHECK ADD  CONSTRAINT [fk_system_tbl_error_logs_user] FOREIGN KEY([user_id])
REFERENCES [dbo].[access_tbl_users] ([id])
GO
ALTER TABLE [dbo].[system_tbl_error_logs] CHECK CONSTRAINT [fk_system_tbl_error_logs_user]
GO
ALTER TABLE [dbo].[financial_tbl_categories]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_categories_type] CHECK  (([transaction_type]=N'adjustment' OR [transaction_type]=N'expense' OR [transaction_type]=N'income'))
GO
ALTER TABLE [dbo].[financial_tbl_categories] CHECK CONSTRAINT [ck_financial_tbl_categories_type]
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_invoice_items_amounts] CHECK  (([quantity]>(0) AND [unit_price]>=(0) AND [total_amount]>=(0)))
GO
ALTER TABLE [dbo].[financial_tbl_invoice_items] CHECK CONSTRAINT [ck_financial_tbl_invoice_items_amounts]
GO
ALTER TABLE [dbo].[financial_tbl_invoices]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_invoices_amounts] CHECK  (([subtotal]>=(0) AND [tax_amount]>=(0) AND [total_amount]>=(0)))
GO
ALTER TABLE [dbo].[financial_tbl_invoices] CHECK CONSTRAINT [ck_financial_tbl_invoices_amounts]
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_receipt_items_amounts] CHECK  (([quantity]>(0) AND [unit_cost]>=(0) AND [total_amount]>=(0)))
GO
ALTER TABLE [dbo].[financial_tbl_receipt_items] CHECK CONSTRAINT [ck_financial_tbl_receipt_items_amounts]
GO
ALTER TABLE [dbo].[financial_tbl_receipts]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_receipts_amounts] CHECK  (([subtotal]>=(0) AND [tax_amount]>=(0) AND [total_amount]>=(0)))
GO
ALTER TABLE [dbo].[financial_tbl_receipts] CHECK CONSTRAINT [ck_financial_tbl_receipts_amounts]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_transactions_amount] CHECK  (([amount]>=(0)))
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [ck_financial_tbl_transactions_amount]
GO
ALTER TABLE [dbo].[financial_tbl_transactions]  WITH CHECK ADD  CONSTRAINT [ck_financial_tbl_transactions_type] CHECK  (([transaction_type]=N'adjustment' OR [transaction_type]=N'expense' OR [transaction_type]=N'income'))
GO
ALTER TABLE [dbo].[financial_tbl_transactions] CHECK CONSTRAINT [ck_financial_tbl_transactions_type]
GO
ALTER TABLE [dbo].[inventory_tbl_batches]  WITH CHECK ADD  CONSTRAINT [ck_inventory_tbl_batches_quantities] CHECK  (([quantity_initial]>=(0) AND [quantity_available]>=(0)))
GO
ALTER TABLE [dbo].[inventory_tbl_batches] CHECK CONSTRAINT [ck_inventory_tbl_batches_quantities]
GO
ALTER TABLE [dbo].[inventory_tbl_movements]  WITH CHECK ADD  CONSTRAINT [ck_inventory_tbl_movements_quantity] CHECK  (([quantity]>(0)))
GO
ALTER TABLE [dbo].[inventory_tbl_movements] CHECK CONSTRAINT [ck_inventory_tbl_movements_quantity]
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage]  WITH CHECK ADD  CONSTRAINT [ck_service_tbl_event_inventory_usage_quantity] CHECK  (([quantity_used]>(0)))
GO
ALTER TABLE [dbo].[service_tbl_event_inventory_usage] CHECK CONSTRAINT [ck_service_tbl_event_inventory_usage_quantity]
GO
ALTER TABLE [dbo].[service_tbl_events]  WITH CHECK ADD  CONSTRAINT [ck_service_tbl_events_schedule] CHECK  (([scheduled_end_at]>[scheduled_start_at]))
GO
ALTER TABLE [dbo].[service_tbl_events] CHECK CONSTRAINT [ck_service_tbl_events_schedule]
GO
ALTER TABLE [dbo].[staff_tbl_availability]  WITH CHECK ADD  CONSTRAINT [ck_staff_tbl_availability_time] CHECK  (([end_time]>[start_time]))
GO
ALTER TABLE [dbo].[staff_tbl_availability] CHECK CONSTRAINT [ck_staff_tbl_availability_time]
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_auth_login] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_auth_login]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_auth_login creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_auth_logout] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_auth_logout]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_auth_logout creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_auth_register_failed_attempt] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_auth_register_failed_attempt]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_auth_register_failed_attempt creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_internal_audit_log_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[access_sp_internal_audit_log_create]
    @user_id int = NULL,
    @action nvarchar(100),
    @entity_name nvarchar(150),
    @entity_id int = NULL,
    @old_value nvarchar(max) = NULL,
    @new_value nvarchar(max) = NULL,
    @ip_address nvarchar(45) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO access_tbl_audit_logs
        (user_id, action, entity_name, entity_id, old_value, new_value, ip_address, created_at)
    VALUES
        (@user_id, @action, @entity_name, @entity_id, @old_value, @new_value, @ip_address, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS audit_log_id;
END;

GO
/****** Objeto: StoredProcedure [dbo].[access_sp_password_reset_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_password_reset_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_password_reset_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_password_reset_use] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_password_reset_use]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_password_reset_use creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_report_audit_activity] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_report_audit_activity]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_report_audit_activity creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_user_roles_assign] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_user_roles_assign]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_user_roles_assign creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_user_roles_remove] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_user_roles_remove]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_user_roles_remove creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_users_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_users_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_users_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_users_delete] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_users_delete]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_users_delete creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_users_set_active] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_users_set_active]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_users_set_active creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[access_sp_users_update_profile] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[access_sp_users_update_profile]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de access_sp_users_update_profile creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[config_sp_catalog_items_list] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- config_sp_catalog_items_list  (nuevo)
--    Devuelve los items activos de un catalogo, por nombre de catalogo
--    (ej. 'service_event_type', 'service_event_status',
--    'service_event_location_type').
-------------------------------------------------------------------------------

CREATE   PROCEDURE [dbo].[config_sp_catalog_items_list]
    @catalog_name nvarchar(150)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ci.id,
        ci.name,
        ci.value,
        ci.sort_order
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = @catalog_name
      AND ci.deleted = 0
      AND ci.is_active = 1
    ORDER BY ci.sort_order, ci.name;
END;
GO
/****** Objeto: StoredProcedure [dbo].[config_sp_catalog_items_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[config_sp_catalog_items_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de config_sp_catalog_items_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[config_sp_settings_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[config_sp_settings_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de config_sp_settings_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_invoice_header_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_invoice_header_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_invoice_header_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_invoice_items_add] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_invoice_items_add]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_invoice_items_add creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_invoice_number_generate] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_invoice_number_generate]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_invoice_number_generate creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_invoice_payment_status_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_invoice_payment_status_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_invoice_payment_status_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_invoice_totals_recalculate] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_invoice_totals_recalculate]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_invoice_totals_recalculate creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_receipt_header_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_receipt_header_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_receipt_header_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_receipt_items_add] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_receipt_items_add]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_receipt_items_add creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_receipt_number_generate] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_receipt_number_generate]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_receipt_number_generate creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_internal_transaction_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_internal_transaction_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_internal_transaction_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_invoice_items_add] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_invoice_items_add]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_invoice_items_add creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_invoices_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_invoices_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_invoices_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_orc_invoices_generate] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[financial_sp_orc_invoices_generate]
    @patient_id int = NULL,
    @service_event_id int = NULL,
    @issue_date date = NULL,
    @due_date date = NULL,
    @notes nvarchar(max) = NULL,
    @created_by_user_id int,
    @invoice_items_json nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @invoice_items_json IS NULL OR ISJSON(@invoice_items_json) <> 1
        THROW 50000, N'invoice_items_json debe ser un JSON válido.', 1;

    -- Pendiente completar la lógica transaccional completa.
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_orc_invoices_generate creado.' AS message;
END;

GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_orc_invoices_register_payment] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[financial_sp_orc_invoices_register_payment]
    @financial_invoice_id int,
    @amount decimal(18,2),
    @financial_payment_method_id int,
    @transaction_date datetime2(0) = NULL,
    @description nvarchar(max) = NULL,
    @created_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @amount < 0
        THROW 50000, N'amount debe ser mayor o igual a cero.', 1;

    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_orc_invoices_register_payment creado.' AS message;
END;

GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_orc_receipts_register_purchase] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[financial_sp_orc_receipts_register_purchase]
    @supplier_id int = NULL,
    @financial_donor_id int = NULL,
    @receipt_date date = NULL,
    @location_id int,
    @notes nvarchar(max) = NULL,
    @created_by_user_id int,
    @receipt_items_json nvarchar(max),
    @create_financial_transaction bit,
    @financial_payment_method_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @receipt_items_json IS NULL OR ISJSON(@receipt_items_json) <> 1
        THROW 50000, N'receipt_items_json debe ser un JSON válido.', 1;

    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_orc_receipts_register_purchase creado.' AS message;
END;

GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_receipt_items_add] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_receipt_items_add]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_receipt_items_add creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_receipts_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_receipts_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_receipts_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_report_donations] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_report_donations]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_report_donations creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_report_invoices] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_report_invoices]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_report_invoices creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_report_receipts] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_report_receipts]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_report_receipts creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_report_summary] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_report_summary]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_report_summary creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_report_transactions] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_report_transactions]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_report_transactions creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[financial_sp_transactions_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[financial_sp_transactions_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de financial_sp_transactions_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_internal_batch_quantity_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_internal_batch_quantity_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_internal_batch_quantity_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_internal_batch_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_internal_batch_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_internal_batch_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_internal_stock_validate] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_internal_stock_validate]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_internal_stock_validate creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_items_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_items_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_items_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_items_delete] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_items_delete]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_items_delete creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_items_search] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_items_search]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_items_search creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_items_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_items_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_items_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_movements_register_adjustment] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_movements_register_adjustment]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_movements_register_adjustment creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_movements_register_entry] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_movements_register_entry]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_movements_register_entry creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_movements_register_exit] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_movements_register_exit]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_movements_register_exit creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_report_expiring_batches] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_report_expiring_batches]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_report_expiring_batches creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_report_low_stock] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_report_low_stock]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_report_low_stock creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_report_movements] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_report_movements]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_report_movements creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_report_stock] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_report_stock]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_report_stock creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_stock_check_low] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_stock_check_low]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_stock_check_low creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[inventory_sp_stock_get] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[inventory_sp_stock_get]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de inventory_sp_stock_get creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_orc_records_get_detail] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[medical_sp_orc_records_get_detail]
    @medical_record_id int = NULL,
    @patient_id int = NULL,
    @accessed_by_user_id int,
    @access_reason nvarchar(500) = NULL,
    @ip_address nvarchar(45) = NULL,
    @device_info nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_orc_records_get_detail creado.' AS message;
END;

GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_patient_allergies_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_patient_allergies_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_patient_allergies_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_patient_conditions_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_patient_conditions_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_patient_conditions_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_patient_medications_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_patient_medications_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_patient_medications_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_patient_vital_signs_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_patient_vital_signs_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_patient_vital_signs_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_record_attachments_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_record_attachments_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_record_attachments_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_record_attachments_download] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_record_attachments_download]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_record_attachments_download creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_record_notes_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_record_notes_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_record_notes_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_records_log_access] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[medical_sp_records_log_access]
    @medical_record_id int,
    @patient_id int,
    @user_id int,
    @staff_member_id int = NULL,
    @access_type_id int,
    @access_reason nvarchar(500) = NULL,
    @ip_address nvarchar(45) = NULL,
    @device_info nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO medical_tbl_record_access_logs
        (medical_record_id, patient_id, user_id, staff_member_id, access_type_id, access_reason, ip_address, device_info, created_at)
    VALUES
        (@medical_record_id, @patient_id, @user_id, @staff_member_id, @access_type_id, @access_reason, @ip_address, @device_info, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS access_log_id;
END;

GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_records_open] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_records_open]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_records_open creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_records_update_status] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_records_update_status]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_records_update_status creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[medical_sp_report_care_plan_follow_up] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[medical_sp_report_care_plan_follow_up]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de medical_sp_report_care_plan_follow_up creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[notification_sp_logs_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[notification_sp_logs_create]
    @user_id int = NULL,
    @patient_id int = NULL,
    @service_event_id int = NULL,
    @notification_type_id int,
    @recipient nvarchar(256) = NULL,
    @subject nvarchar(250) = NULL,
    @message nvarchar(max) = NULL,
    @status_id int,
    @sent_at datetime2(0) = NULL,
    @error_message nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO notification_tbl_logs
        (user_id, patient_id, service_event_id, notification_type_id, recipient, subject, message, status_id, sent_at, error_message, created_at)
    VALUES
        (@user_id, @patient_id, @service_event_id, @notification_type_id, @recipient, @subject, @message, @status_id, @sent_at, @error_message, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS notification_log_id;
END;
GO
/****** Objeto: StoredProcedure [dbo].[notification_sp_report_notifications] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[notification_sp_report_notifications]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de notification_sp_report_notifications creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_contacts_delete] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_contacts_delete]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_contacts_delete creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_contacts_upsert] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_contacts_upsert]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_contacts_upsert creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_orc_patients_register] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[patient_sp_orc_patients_register]
    @first_name nvarchar(100),
    @last_name nvarchar(150),
    @identification_number nvarchar(50) = NULL,
    @birth_date date = NULL,
    @gender_id int = NULL,
    @phone nvarchar(30) = NULL,
    @email nvarchar(256) = NULL,
    @address_id int = NULL,
    @contacts_json nvarchar(max) = NULL,
    @open_medical_record bit = 0,
    @created_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @contacts_json IS NOT NULL AND ISJSON(@contacts_json) <> 1
        THROW 50000, N'contacts_json debe ser un JSON válido.', 1;

    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_orc_patients_register creado.' AS message;
END;

GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_patients_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_patients_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_patients_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_patients_delete] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_patients_delete]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_patients_delete creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_patients_get_detail] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_patients_get_detail]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_patients_get_detail creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_patients_search] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 9) patient_sp_patients_search  (version minima)
--    Alimenta el combo de pacientes del formulario de citas.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[patient_sp_patients_search]
    @search nvarchar(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.id,
        p.first_name,
        p.last_name,
        p.identification_number,
        p.email,
        p.phone
    FROM patient_tbl_patients p
    WHERE p.deleted = 0
      AND p.is_active = 1
      AND (
            @search IS NULL
            OR p.first_name LIKE N'%' + @search + N'%'
            OR p.last_name LIKE N'%' + @search + N'%'
            OR p.identification_number LIKE N'%' + @search + N'%'
          )
    ORDER BY p.first_name, p.last_name;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_patients_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_patients_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_patients_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_report_medical_activity] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_report_medical_activity]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_report_medical_activity creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[patient_sp_report_registry] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[patient_sp_report_registry]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de patient_sp_report_registry creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_add_note] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_events_add_note]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_events_add_note creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_add_service] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_events_add_service]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_events_add_service creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_assign_staff] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_events_assign_staff]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_events_assign_staff creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_complete] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_events_complete]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_events_complete creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_get_detail] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 8) service_sp_events_get_detail  (nuevo)
--    Detalle completo de una cita (para vista de detalle/edicion) mas su
--    historial de estados. Devuelve dos result sets (Dapper QueryMultiple):
--    1) datos de la cita con nombres resueltos y datos de contacto
--    2) historial de cambios de estado
-------------------------------------------------------------------------------

CREATE   PROCEDURE [dbo].[service_sp_events_get_detail]
    @service_event_id int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        e.id,
        e.patient_id,
        p.first_name AS patient_first_name,
        p.last_name AS patient_last_name,
        p.email AS patient_email,
        p.phone AS patient_phone,
        e.event_type_id,
        et.name AS event_type_name,
        et.value AS event_type_value,
        e.status_id,
        st.name AS status_name,
        st.value AS status_value,
        e.scheduled_start_at,
        e.scheduled_end_at,
        e.actual_start_at,
        e.actual_end_at,
        e.location_type_id,
        lt.name AS location_type_name,
        lt.value AS location_type_value,
        e.location_id,
        loc.name AS location_name,
        e.address_id,
        a.address_line,
        a.reference,
        e.location_description,
        e.main_staff_member_id,
        sm.first_name AS staff_first_name,
        sm.last_name AS staff_last_name,
        sm.email AS staff_email,
        sm.phone AS staff_phone,
        e.summary,
        e.created_by_user_id,
        e.created_at,
        e.updated_at
    FROM service_tbl_events e
    LEFT JOIN patient_tbl_patients p ON p.id = e.patient_id
    LEFT JOIN staff_tbl_members sm ON sm.id = e.main_staff_member_id
    LEFT JOIN config_tbl_catalog_items et ON et.id = e.event_type_id
    LEFT JOIN config_tbl_catalog_items st ON st.id = e.status_id
    LEFT JOIN config_tbl_catalog_items lt ON lt.id = e.location_type_id
    LEFT JOIN location_tbl_locations loc ON loc.id = e.location_id
    LEFT JOIN location_tbl_addresses a ON a.id = e.address_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    SELECT
        h.id,
        h.service_event_id,
        h.old_status_id,
        os.name AS old_status_name,
        h.new_status_id,
        ns.name AS new_status_name,
        h.reason,
        h.changed_by_user_id,
        u.full_name AS changed_by_full_name,
        h.changed_at
    FROM service_tbl_event_status_history h
    LEFT JOIN config_tbl_catalog_items os ON os.id = h.old_status_id
    INNER JOIN config_tbl_catalog_items ns ON ns.id = h.new_status_id
    LEFT JOIN access_tbl_users u ON u.id = h.changed_by_user_id
    WHERE h.service_event_id = @service_event_id
    ORDER BY h.changed_at DESC;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_register_inventory_usage] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_events_register_inventory_usage]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_events_register_inventory_usage creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_events_validate_staff_availability] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 6) service_sp_events_validate_staff_availability
--    Verifica si un colaborador esta disponible en un rango de fecha/hora.
--    Si no lo esta, ademas del bit de disponibilidad, devuelve hasta 3
--    horarios alternativos libres (mismo dia +1h/+2h y siguiente dia mismo
--    horario) para que la vista pueda sugerirlos.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[service_sp_events_validate_staff_availability]
    @staff_member_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @exclude_event_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @duration_minutes int = DATEDIFF(MINUTE, @scheduled_start_at, @scheduled_end_at);
    DECLARE @is_available bit = 1;

    IF EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @staff_member_id
          AND (@exclude_event_id IS NULL OR e.id <> @exclude_event_id)
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        SET @is_available = 0;

    SELECT @is_available AS is_available;

    IF @is_available = 0
    BEGIN
        ;WITH candidates AS (
            SELECT DATEADD(MINUTE, 60, @scheduled_start_at) AS candidate_start
            UNION ALL SELECT DATEADD(MINUTE, 120, @scheduled_start_at)
            UNION ALL SELECT DATEADD(DAY, 1, @scheduled_start_at)
            UNION ALL SELECT DATEADD(DAY, 2, @scheduled_start_at)
        )
        SELECT TOP (3)
            c.candidate_start,
            DATEADD(MINUTE, @duration_minutes, c.candidate_start) AS candidate_end
        FROM candidates c
        WHERE NOT EXISTS (
            SELECT 1
            FROM service_tbl_events e
            INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
            WHERE e.deleted = 0
              AND st.value NOT IN (N'cancelled')
              AND e.main_staff_member_id = @staff_member_id
              AND (@exclude_event_id IS NULL OR e.id <> @exclude_event_id)
              AND e.scheduled_start_at < DATEADD(MINUTE, @duration_minutes, c.candidate_start)
              AND e.scheduled_end_at > c.candidate_start
        )
        ORDER BY c.candidate_start;
    END
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_internal_event_status_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_internal_event_status_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_internal_event_status_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_internal_status_history_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 5) service_sp_internal_status_history_create
--    SP de apoyo (mismo espiritu que notification_sp_logs_create): inserta
--    un registro en service_tbl_event_status_history. Lo llaman los
--    orquestadores de citas; tambien puede llamarse solo si se necesita.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[service_sp_internal_status_history_create]
    @service_event_id int,
    @old_status_id int = NULL,
    @new_status_id int,
    @reason nvarchar(500) = NULL,
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO service_tbl_event_status_history
        (service_event_id, old_status_id, new_status_id, reason, changed_by_user_id, changed_at)
    VALUES
        (@service_event_id, @old_status_id, @new_status_id, @reason, @changed_by_user_id, SYSDATETIME());
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_orc_events_cancel] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 4) service_sp_orc_events_cancel
--    Cancela una cita y deja el motivo en el historial de estados.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[service_sp_orc_events_cancel]
    @service_event_id int,
    @reason nvarchar(500),
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@reason)), N'') IS NULL
        THROW 50000, N'La razón de cancelación es requerida.', 1;

    DECLARE @current_status_id int, @status_value nvarchar(150);

    SELECT @current_status_id = e.status_id, @status_value = st.value
    FROM service_tbl_events e
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    IF @current_status_id IS NULL
        THROW 50013, N'La cita indicada no existe.', 1;

    IF @status_value IN (N'cancelled', N'completed')
        THROW 50014, N'La cita ya está cancelada o completada.', 1;

    DECLARE @cancelled_status_id int;
    SELECT @cancelled_status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_status' AND ci.value = N'cancelled';

    BEGIN TRAN;

        UPDATE service_tbl_events
        SET status_id = @cancelled_status_id,
            updated_at = SYSDATETIME()
        WHERE id = @service_event_id;

        EXEC service_sp_internal_status_history_create
            @service_event_id = @service_event_id,
            @old_status_id = @current_status_id,
            @new_status_id = @cancelled_status_id,
            @reason = @reason,
            @changed_by_user_id = @changed_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @service_event_id AS service_event_id;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_orc_events_complete_full] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[service_sp_orc_events_complete_full]
    @service_event_id int,
    @completed_by_user_id int,
    @completed_by_staff_member_id int = NULL,
    @completion_summary nvarchar(max) = NULL,
    @actual_start_at datetime2(0) = NULL,
    @actual_end_at datetime2(0) = NULL,
    @notes_json nvarchar(max) = NULL,
    @services_json nvarchar(max) = NULL,
    @inventory_usage_json nvarchar(max) = NULL,
    @vital_signs_json nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @notes_json IS NOT NULL AND ISJSON(@notes_json) <> 1 THROW 50000, N'notes_json debe ser un JSON válido.', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1 THROW 50000, N'services_json debe ser un JSON válido.', 1;
    IF @inventory_usage_json IS NOT NULL AND ISJSON(@inventory_usage_json) <> 1 THROW 50000, N'inventory_usage_json debe ser un JSON válido.', 1;
    IF @vital_signs_json IS NOT NULL AND ISJSON(@vital_signs_json) <> 1 THROW 50000, N'vital_signs_json debe ser un JSON válido.', 1;

    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_orc_events_complete_full creado.' AS message;
END;

GO
/****** Objeto: StoredProcedure [dbo].[service_sp_orc_events_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 1) service_sp_orc_events_create
--    Crea una cita (presencial o domiciliar), valida paciente, colaborador
--    y disponibilidad de horario, inserta staff/servicios asociados y deja
--    el primer registro en el historial de estados.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[service_sp_orc_events_create]
    @patient_id int = NULL,
    @event_type_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @location_type_id int,
    @location_id int = NULL,
    @address_id int = NULL,
    @location_description nvarchar(500) = NULL,
    @main_staff_member_id int = NULL,
    @summary nvarchar(max) = NULL,
    @created_by_user_id int,
    @staff_json nvarchar(max) = NULL,
    @services_json nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @scheduled_end_at <= @scheduled_start_at
        THROW 50000, N'scheduled_end_at debe ser mayor que scheduled_start_at.', 1;
    IF @staff_json IS NOT NULL AND ISJSON(@staff_json) <> 1
        THROW 50000, N'staff_json debe ser un JSON válido.', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1
        THROW 50000, N'services_json debe ser un JSON válido.', 1;

    -- RF-06 Paso 5: una cita siempre debe tener paciente.
    IF @patient_id IS NULL
        THROW 50000, N'El paciente es obligatorio.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50011, N'El paciente indicado no existe o está inactivo.', 1;

    IF @main_staff_member_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM staff_tbl_members
        WHERE id = @main_staff_member_id AND deleted = 0 AND is_active = 1
    )
        THROW 50012, N'El colaborador indicado no existe o está inactivo.', 1;

    -- RF-06 Paso 5: event_type_id y location_type_id deben ser valores
    -- reales de sus catalogos, y la ubicacion debe traer el dato que le
    -- corresponde (sede si es "en sede", direccion si es "domiciliar").
    DECLARE @event_type_value nvarchar(150), @location_type_value nvarchar(150);

    SELECT @event_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_type' AND ci.id = @event_type_id;

    IF @event_type_value IS NULL
        THROW 50000, N'El tipo de cita indicado no es válido.', 1;

    SELECT @location_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_location_type' AND ci.id = @location_type_id;

    IF @location_type_value IS NULL
        THROW 50000, N'El tipo de ubicación indicado no es válido.', 1;

    IF @location_type_value IN (N'onsite', N'home')
        AND (@location_description IS NULL OR LTRIM(RTRIM(@location_description)) = N'')
        THROW 50000, N'Debe indicar la sede o dirección de la cita.', 1;

    IF @main_staff_member_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @main_staff_member_id
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        THROW 50010, N'El colaborador ya tiene una cita en ese horario.', 1;

    DECLARE @status_id int;
    SELECT @status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_status' AND ci.value = N'scheduled';

    DECLARE @new_event_id int;
    DECLARE @output_ids TABLE (id int);

    BEGIN TRAN;

        INSERT INTO service_tbl_events
            (patient_id, event_type_id, status_id, scheduled_start_at, scheduled_end_at,
             location_type_id, location_id, address_id, location_description,
             main_staff_member_id, summary, created_by_user_id, created_at)
        OUTPUT inserted.id INTO @output_ids
        VALUES
            (@patient_id, @event_type_id, @status_id, @scheduled_start_at, @scheduled_end_at,
             @location_type_id, @location_id, @address_id, @location_description,
             @main_staff_member_id, @summary, @created_by_user_id, SYSDATETIME());

        SELECT @new_event_id = id FROM @output_ids;

        IF @main_staff_member_id IS NOT NULL
        BEGIN
            INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
            VALUES (@new_event_id, @main_staff_member_id, NULL, SYSDATETIME());
        END

        IF @staff_json IS NOT NULL
        BEGIN
            INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
            SELECT @new_event_id, j.staff_member_id, j.role_in_event_id, SYSDATETIME()
            FROM OPENJSON(@staff_json)
            WITH (
                staff_member_id int '$.staff_member_id',
                role_in_event_id int '$.role_in_event_id'
            ) j
            WHERE j.staff_member_id <> ISNULL(@main_staff_member_id, -1);
        END

        IF @services_json IS NOT NULL
        BEGIN
            INSERT INTO service_tbl_event_services (service_event_id, service_id, created_at)
            SELECT @new_event_id, j.service_id, SYSDATETIME()
            FROM OPENJSON(@services_json)
            WITH (service_id int '$.service_id') j;
        END

        EXEC service_sp_internal_status_history_create
            @service_event_id = @new_event_id,
            @old_status_id = NULL,
            @new_status_id = @status_id,
            @reason = N'Cita creada.',
            @changed_by_user_id = @created_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @new_event_id AS service_event_id;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_orc_events_reschedule] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 2) service_sp_orc_events_reschedule
--    Reprogramacion rapida: solo cambia fecha/hora. Valida disponibilidad
--    del colaborador principal en el nuevo horario (excluyendo la cita
--    misma) y deja rastro en el historial de estados.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[service_sp_orc_events_reschedule]
    @service_event_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @reason nvarchar(500) = NULL,
    @changed_by_user_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @scheduled_end_at <= @scheduled_start_at
        THROW 50000, N'scheduled_end_at debe ser mayor que scheduled_start_at.', 1;

    DECLARE @current_status_id int, @main_staff_member_id int, @status_value nvarchar(150);

    SELECT
        @current_status_id = e.status_id,
        @main_staff_member_id = e.main_staff_member_id,
        @status_value = st.value
    FROM service_tbl_events e
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    IF @current_status_id IS NULL
        THROW 50013, N'La cita indicada no existe.', 1;

    IF @status_value IN (N'cancelled', N'completed')
        THROW 50014, N'No se puede reprogramar una cita cancelada o completada.', 1;

    IF @main_staff_member_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND e.id <> @service_event_id
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @main_staff_member_id
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        THROW 50010, N'El colaborador ya tiene una cita en ese horario.', 1;

    DECLARE @rescheduled_status_id int;
    SELECT @rescheduled_status_id = ci.id
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_status' AND ci.value = N'rescheduled';

    BEGIN TRAN;

        UPDATE service_tbl_events
        SET scheduled_start_at = @scheduled_start_at,
            scheduled_end_at = @scheduled_end_at,
            status_id = @rescheduled_status_id,
            updated_at = SYSDATETIME()
        WHERE id = @service_event_id;

        EXEC service_sp_internal_status_history_create
            @service_event_id = @service_event_id,
            @old_status_id = @current_status_id,
            @new_status_id = @rescheduled_status_id,
            @reason = @reason,
            @changed_by_user_id = @changed_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @service_event_id AS service_event_id;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_orc_events_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 3) service_sp_orc_events_update  (nuevo)
--    Edicion completa de una cita: paciente, tipo, horario, ubicacion,
--    direccion, colaborador principal, resumen, staff y servicios.
--    Si el horario cambia, valida disponibilidad y marca la cita como
--    "rescheduled"; si no cambia, mantiene el estado actual.
-------------------------------------------------------------------------------

CREATE   PROCEDURE [dbo].[service_sp_orc_events_update]
    @service_event_id int,
    @patient_id int = NULL,
    @event_type_id int,
    @scheduled_start_at datetime2(0),
    @scheduled_end_at datetime2(0),
    @location_type_id int,
    @location_id int = NULL,
    @address_id int = NULL,
    @location_description nvarchar(500) = NULL,
    @main_staff_member_id int = NULL,
    @summary nvarchar(max) = NULL,
    @reason nvarchar(500) = NULL,
    @changed_by_user_id int,
    @staff_json nvarchar(max) = NULL,
    @services_json nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @scheduled_end_at <= @scheduled_start_at
        THROW 50000, N'scheduled_end_at debe ser mayor que scheduled_start_at.', 1;
    IF @staff_json IS NOT NULL AND ISJSON(@staff_json) <> 1
        THROW 50000, N'staff_json debe ser un JSON válido.', 1;
    IF @services_json IS NOT NULL AND ISJSON(@services_json) <> 1
        THROW 50000, N'services_json debe ser un JSON válido.', 1;

    DECLARE @current_status_id int, @current_start datetime2(0), @current_end datetime2(0), @status_value nvarchar(150);

    SELECT
        @current_status_id = e.status_id,
        @current_start = e.scheduled_start_at,
        @current_end = e.scheduled_end_at,
        @status_value = st.value
    FROM service_tbl_events e
    INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
    WHERE e.id = @service_event_id AND e.deleted = 0;

    IF @current_status_id IS NULL
        THROW 50013, N'La cita indicada no existe.', 1;

    IF @status_value IN (N'cancelled', N'completed')
        THROW 50014, N'No se puede modificar una cita cancelada o completada.', 1;

    -- RF-06 Paso 5: una cita siempre debe tener paciente.
    IF @patient_id IS NULL
        THROW 50000, N'El paciente es obligatorio.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM patient_tbl_patients
        WHERE id = @patient_id AND deleted = 0 AND is_active = 1
    )
        THROW 50011, N'El paciente indicado no existe o está inactivo.', 1;

    IF @main_staff_member_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM staff_tbl_members
        WHERE id = @main_staff_member_id AND deleted = 0 AND is_active = 1
    )
        THROW 50012, N'El colaborador indicado no existe o está inactivo.', 1;

    -- RF-06 Paso 5: event_type_id y location_type_id deben ser valores
    -- reales de sus catalogos, y la ubicacion debe traer el dato que le
    -- corresponde (sede si es "en sede", direccion si es "domiciliar").
    DECLARE @event_type_value nvarchar(150), @location_type_value nvarchar(150);

    SELECT @event_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_type' AND ci.id = @event_type_id;

    IF @event_type_value IS NULL
        THROW 50000, N'El tipo de cita indicado no es válido.', 1;

    SELECT @location_type_value = ci.value
    FROM config_tbl_catalog_items ci
    INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
    WHERE c.name = N'service_event_location_type' AND ci.id = @location_type_id;

    IF @location_type_value IS NULL
        THROW 50000, N'El tipo de ubicación indicado no es válido.', 1;

    -- La UI solo captura location_description (texto libre) para la
    -- ubicacion; location_id/address_id no tienen selector en el
    -- formulario todavia, asi que la validacion se basa en el texto.
    IF @location_type_value IN (N'onsite', N'home')
        AND (@location_description IS NULL OR LTRIM(RTRIM(@location_description)) = N'')
        THROW 50000, N'Debe indicar la sede o dirección de la cita.', 1;

    DECLARE @schedule_changed bit = CASE
        WHEN @current_start <> @scheduled_start_at OR @current_end <> @scheduled_end_at THEN 1 ELSE 0 END;

    IF @main_staff_member_id IS NOT NULL AND EXISTS (
        SELECT 1
        FROM service_tbl_events e
        INNER JOIN config_tbl_catalog_items st ON st.id = e.status_id
        WHERE e.deleted = 0
          AND e.id <> @service_event_id
          AND st.value NOT IN (N'cancelled')
          AND e.main_staff_member_id = @main_staff_member_id
          AND e.scheduled_start_at < @scheduled_end_at
          AND e.scheduled_end_at > @scheduled_start_at
    )
        THROW 50010, N'El colaborador ya tiene una cita en ese horario.', 1;

    DECLARE @new_status_id int = @current_status_id;
    IF @schedule_changed = 1
    BEGIN
        SELECT @new_status_id = ci.id
        FROM config_tbl_catalog_items ci
        INNER JOIN config_tbl_catalogs c ON c.id = ci.catalog_id
        WHERE c.name = N'service_event_status' AND ci.value = N'rescheduled';
    END

    BEGIN TRAN;

        UPDATE service_tbl_events
        SET patient_id = @patient_id,
            event_type_id = @event_type_id,
            status_id = @new_status_id,
            scheduled_start_at = @scheduled_start_at,
            scheduled_end_at = @scheduled_end_at,
            location_type_id = @location_type_id,
            location_id = @location_id,
            address_id = @address_id,
            location_description = @location_description,
            main_staff_member_id = @main_staff_member_id,
            summary = @summary,
            updated_at = SYSDATETIME()
        WHERE id = @service_event_id;

        IF @staff_json IS NOT NULL
        BEGIN
            DELETE FROM service_tbl_event_staff WHERE service_event_id = @service_event_id;

            IF @main_staff_member_id IS NOT NULL
                INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
                VALUES (@service_event_id, @main_staff_member_id, NULL, SYSDATETIME());

            INSERT INTO service_tbl_event_staff (service_event_id, staff_member_id, role_in_event_id, created_at)
            SELECT @service_event_id, j.staff_member_id, j.role_in_event_id, SYSDATETIME()
            FROM OPENJSON(@staff_json)
            WITH (
                staff_member_id int '$.staff_member_id',
                role_in_event_id int '$.role_in_event_id'
            ) j
            WHERE j.staff_member_id <> ISNULL(@main_staff_member_id, -1);
        END

        IF @services_json IS NOT NULL
        BEGIN
            DELETE FROM service_tbl_event_services WHERE service_event_id = @service_event_id;

            INSERT INTO service_tbl_event_services (service_event_id, service_id, created_at)
            SELECT @service_event_id, j.service_id, SYSDATETIME()
            FROM OPENJSON(@services_json)
            WITH (service_id int '$.service_id') j;
        END

        EXEC service_sp_internal_status_history_create
            @service_event_id = @service_event_id,
            @old_status_id = @current_status_id,
            @new_status_id = @new_status_id,
            @reason = @reason,
            @changed_by_user_id = @changed_by_user_id;

    COMMIT;

    SELECT CAST(1 AS bit) AS success, @service_event_id AS service_event_id;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_report_events] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 7) service_sp_report_events
--    Lista/consulta citas con filtros (fecha, paciente, colaborador,
--    estado, tipo). Alimenta tanto el calendario como el listado tabular.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[service_sp_report_events]
    @date_from date = NULL,
    @date_to date = NULL,
    @patient_id int = NULL,
    @staff_member_id int = NULL,
    @status_id int = NULL,
    @event_type_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.id,
        c.patient_id,
        c.patient_first_name,
        c.patient_last_name,
        c.event_type_id,
        c.event_type_name,
        c.status_id,
        c.status_name,
        st.value AS status_value,
        c.scheduled_start_at,
        c.scheduled_end_at,
        c.main_staff_member_id,
        c.staff_first_name,
        c.staff_last_name
    FROM service_vw_event_calendar c
    INNER JOIN config_tbl_catalog_items st ON st.id = c.status_id
    WHERE (@date_from IS NULL OR CAST(c.scheduled_start_at AS date) >= @date_from)
      AND (@date_to IS NULL OR CAST(c.scheduled_start_at AS date) <= @date_to)
      AND (@patient_id IS NULL OR c.patient_id = @patient_id)
      AND (@staff_member_id IS NULL OR c.main_staff_member_id = @staff_member_id)
      AND (@status_id IS NULL OR c.status_id = @status_id)
      AND (@event_type_id IS NULL OR c.event_type_id = @event_type_id)
    ORDER BY c.scheduled_start_at;
END;
GO
/****** Objeto: StoredProcedure [dbo].[service_sp_report_inventory_usage] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[service_sp_report_inventory_usage]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de service_sp_report_inventory_usage creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[spGetUserByID] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetUserByID]
	@id int

AS
BEGIN
	SET NOCOUNT ON;

	SELECT
	username,
	full_name,
	phone
	from access_tbl_users
	WHERE id = @id

END
GO
/****** Objeto: StoredProcedure [dbo].[spLoginUser] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spLoginUser]
	@email nvarchar(256),
	@password nvarchar(500)
AS
BEGIN
	SET NOCOUNT ON;

	--verificamos que las credenciales sean correctas y este activo
	IF EXISTS (SELECT 1 FROM access_tbl_users WHERE email = @email AND is_active = 1)
	BEGIN
		--si es correcto, actualizamos su último login
		UPDATE access_tbl_users 
		SET last_login_at = GETDATE()
		WHERE email = @email;

		--devolvemos los datos del usuario para la sesión
		SELECT 
		U.id, 
		U.username, 
		U.email,
		U.password,
		U.full_name, 
		U.phone, 
		U.is_active, 
		UR.role_id,
		R.name AS RoleName
		FROM access_tbl_users U
		inner JOIN access_tbl_user_roles UR ON U.id = UR.user_id
		inner JOIN access_tbl_roles R ON UR.role_id = R.id
		WHERE U.email = @email;
	END

END
GO
/****** Objeto: StoredProcedure [dbo].[spRegisterBasicUser] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRegisterBasicUser]
	@username nvarchar(100),
	@email nvarchar(256),
	@password nvarchar(500),
	@full_name nvarchar(200),
	@phone nvarchar(30) = NULL
AS
BEGIN
	DECLARE @failed_login_attempts int = 0
	DECLARE @lockout_until datetime = NULL
	DECLARE @last_login_at datetime = NULL
	DECLARE @is_active bit = 1
	DECLARE @deleted bit = 0
	DECLARE @created_at datetime = GETDATE()
	DECLARE @updated_at datetime = NULL

	SET NOCOUNT OFF;

	IF NOT EXISTS (SELECT 1 FROM access_tbl_users WHERE email = @email)
	BEGIN
	--se inserta primero en la tabla de usuarios
	INSERT INTO access_tbl_users (username, email, password, full_name, phone, failed_login_attempts, lockout_until, last_login_at, is_active, deleted, created_at,updated_at)
	VALUES(@username, @email, @password, @full_name, @phone, @failed_login_attempts, @lockout_until, @last_login_at, @is_active, @deleted, @created_at, @updated_at)

	--se inserta en la tabla de roles del usuario, el rol por default es 8 (Usuario)
	INSERT INTO access_tbl_user_roles (user_id, role_id, created_at)
	VALUES(SCOPE_IDENTITY(), 8, GETDATE())
	END

END
GO
/****** Objeto: StoredProcedure [dbo].[spUpdatePassword] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spUpdatePassword] 
	@id int,
	@password nvarchar(500)

AS
Begin

	UPDATE dbo.access_tbl_users
	SET password = @password
	WHERE id = @id

END	
GO
/****** Objeto: StoredProcedure [dbo].[spUpdateUserInfo] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spUpdateUserInfo]
	@id int,
	@username nvarchar(100),
	@full_name nvarchar(200),
	@phone nvarchar(30)

AS
BEGIN

	UPDATE access_tbl_users
	SET
	username = @username,
	full_name = @full_name,
	phone = @phone
	from access_tbl_users
	WHERE id = @id

END
GO
/****** Objeto: StoredProcedure [dbo].[spValidateEmail] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spValidateEmail] 

	@email nvarchar(256)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT id, email, full_name from dbo.access_tbl_users
	where @email = email

END
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_availability_generate] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[staff_sp_availability_generate]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de staff_sp_availability_generate creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_availability_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[staff_sp_availability_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de staff_sp_availability_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_members_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[staff_sp_members_create]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de staff_sp_members_create creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_members_delete] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[staff_sp_members_delete]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de staff_sp_members_delete creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_members_search] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------
-- 10) staff_sp_members_search  (version minima)
--     Alimenta el combo de colaboradores del formulario de citas.
-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[staff_sp_members_search]
    @search nvarchar(200) = NULL,
    @staff_role_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sm.id,
        sm.first_name,
        sm.last_name,
        sm.staff_role_id,
        r.name AS staff_role_name,
        sm.email,
        sm.phone
    FROM staff_tbl_members sm
    INNER JOIN staff_tbl_roles r ON r.id = sm.staff_role_id
    WHERE sm.deleted = 0
      AND sm.is_active = 1
      AND (@staff_role_id IS NULL OR sm.staff_role_id = @staff_role_id)
      AND (
            @search IS NULL
            OR sm.first_name LIKE N'%' + @search + N'%'
            OR sm.last_name LIKE N'%' + @search + N'%'
          )
    ORDER BY sm.first_name, sm.last_name;
END;
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_members_update] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[staff_sp_members_update]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de staff_sp_members_update creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[staff_sp_report_activity] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[staff_sp_report_activity]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de staff_sp_report_activity creado; falta completar implementación.' AS message;
END;
GO
/****** Objeto: StoredProcedure [dbo].[system_sp_error_logs_create] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[system_sp_error_logs_create]
    @user_id int = NULL,
    @source nvarchar(150) = NULL,
    @message nvarchar(max),
    @detail nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO system_tbl_error_logs
        (user_id, source, message, detail, created_at)
    VALUES
        (@user_id, @source, @message, @detail, SYSDATETIME());

    SELECT CAST(1 AS bit) AS success, SCOPE_IDENTITY() AS error_log_id;
END;

GO
/****** Objeto: StoredProcedure [dbo].[system_sp_report_errors] Fecha de script: 23/7/2026 18:22:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[system_sp_report_errors]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(1 AS bit) AS success, N'Contrato de system_sp_report_errors creado; falta completar implementación.' AS message;
END;
GO
