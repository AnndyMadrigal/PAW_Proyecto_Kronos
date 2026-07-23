/*
    Kronos - 06_functions.sql

    Funciones pequeñas de apoyo.
    La idea es usarlas solo donde simplifiquen la consulta.
*/

SET NOCOUNT ON;
USE Kronos;

EXEC(N'
CREATE FUNCTION patient_fn_age(@birth_date date)
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
');

EXEC(N'
CREATE FUNCTION inventory_fn_item_stock(@inventory_item_id int)
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
');

EXEC(N'
CREATE FUNCTION inventory_fn_batch_stock(@inventory_batch_id int)
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
');

EXEC(N'
CREATE FUNCTION staff_fn_is_available
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
');

EXEC(N'
CREATE FUNCTION config_fn_catalog_item_value(@catalog_item_id int)
RETURNS nvarchar(150)
AS
BEGIN
    DECLARE @value nvarchar(150);

    SELECT @value = value
    FROM config_tbl_catalog_items
    WHERE id = @catalog_item_id;

    RETURN @value;
END;
');

SET NOCOUNT OFF;
