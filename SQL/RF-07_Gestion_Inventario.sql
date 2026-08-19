/* RF-07. Gestion de Inventario. Ejecutar en la base de datos Kronos. */
SET NOCOUNT ON;
GO

/* =========================================================================
   1. Listar / Buscar productos del inventario con detalle de categoria y unidad
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_items_search
    @search nvarchar(200) = NULL,
    @category_id int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @search = NULLIF(LTRIM(RTRIM(@search)), N'');

    SELECT
        i.id,
        i.name,
        i.description,
        i.minimum_stock,
        i.inventory_category_id,
        c.name AS category_name,
        i.inventory_unit_id,
        u.name AS unit_name,
        u.abbreviation AS unit_abbreviation,
        i.is_active,
        i.created_at,
        i.updated_at
    FROM dbo.inventory_tbl_items i
    INNER JOIN dbo.inventory_tbl_categories c ON c.id = i.inventory_category_id AND c.deleted = 0
    INNER JOIN dbo.inventory_tbl_units u ON u.id = i.inventory_unit_id AND u.deleted = 0
    WHERE i.deleted = 0
      AND (@category_id IS NULL OR i.inventory_category_id = @category_id)
      AND (
          @search IS NULL
          OR i.name LIKE N'%' + @search + N'%'
          OR ISNULL(i.description, N'') LIKE N'%' + @search + N'%'
      )
    ORDER BY i.name;
END;
GO

/* =========================================================================
   2. Obtener detalle de un producto por ID
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_items_get_by_id
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        i.id,
        i.name,
        i.description,
        i.minimum_stock,
        i.inventory_category_id,
        c.name AS category_name,
        i.inventory_unit_id,
        u.name AS unit_name,
        u.abbreviation AS unit_abbreviation,
        i.is_active,
        i.created_at,
        i.updated_at
    FROM dbo.inventory_tbl_items i
    INNER JOIN dbo.inventory_tbl_categories c ON c.id = i.inventory_category_id AND c.deleted = 0
    INNER JOIN dbo.inventory_tbl_units u ON u.id = i.inventory_unit_id AND u.deleted = 0
    WHERE i.id = @id AND i.deleted = 0;
END;
GO

/* =========================================================================
   3. Crear un nuevo producto en el inventario
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_items_create
    @name nvarchar(200),
    @description nvarchar(500) = NULL,
    @minimum_stock decimal(18, 4),
    @inventory_category_id int,
    @inventory_unit_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET @name = LTRIM(RTRIM(@name));

    IF @name IS NULL OR @name = N''
    BEGIN
        THROW 50000, N'El nombre del producto es requerido.', 1;
    END

    IF @minimum_stock < 0
    BEGIN
        THROW 50000, N'El stock mínimo no puede ser negativo.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.inventory_tbl_categories WHERE id = @inventory_category_id AND deleted = 0 AND is_active = 1)
    BEGIN
        THROW 50000, N'La categoría seleccionada no existe o no está activa.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.inventory_tbl_units WHERE id = @inventory_unit_id AND deleted = 0 AND is_active = 1)
    BEGIN
        THROW 50000, N'La unidad seleccionada no existe o no está activa.', 1;
    END

    IF EXISTS (SELECT 1 FROM dbo.inventory_tbl_items WHERE name = @name AND deleted = 0)
    BEGIN
        THROW 50000, N'Ya existe un producto registrado con ese nombre.', 1;
    END

    INSERT INTO dbo.inventory_tbl_items
        (inventory_category_id, inventory_unit_id, name, description, minimum_stock, requires_expiration_date, is_active, deleted, created_at)
    VALUES
        (@inventory_category_id, @inventory_unit_id, @name, NULLIF(LTRIM(RTRIM(@description)), N''), @minimum_stock, 0, 1, 0, SYSDATETIME());

    DECLARE @new_id int = SCOPE_IDENTITY();
    SELECT @new_id AS id, CAST(1 AS bit) AS success, N'Producto creado exitosamente.' AS message;
END;
GO

/* =========================================================================
   4. Actualizar un producto existente en el inventario
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_items_update
    @id int,
    @name nvarchar(200),
    @description nvarchar(500) = NULL,
    @minimum_stock decimal(18, 4),
    @inventory_category_id int,
    @inventory_unit_id int
AS
BEGIN
    SET NOCOUNT ON;
    SET @name = LTRIM(RTRIM(@name));

    IF @name IS NULL OR @name = N''
    BEGIN
        THROW 50000, N'El nombre del producto es requerido.', 1;
    END

    IF @minimum_stock < 0
    BEGIN
        THROW 50000, N'El stock mínimo no puede ser negativo.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.inventory_tbl_items WHERE id = @id AND deleted = 0)
    BEGIN
        THROW 50013, N'El producto no existe o ha sido eliminado.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.inventory_tbl_categories WHERE id = @inventory_category_id AND deleted = 0 AND is_active = 1)
    BEGIN
        THROW 50000, N'La categoría seleccionada no existe o no está activa.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.inventory_tbl_units WHERE id = @inventory_unit_id AND deleted = 0 AND is_active = 1)
    BEGIN
        THROW 50000, N'La unidad seleccionada no existe o no está activa.', 1;
    END

    IF EXISTS (SELECT 1 FROM dbo.inventory_tbl_items WHERE name = @name AND id <> @id AND deleted = 0)
    BEGIN
        THROW 50000, N'Ya existe otro producto registrado con ese nombre.', 1;
    END

    UPDATE dbo.inventory_tbl_items
    SET inventory_category_id = @inventory_category_id,
        inventory_unit_id = @inventory_unit_id,
        name = @name,
        description = NULLIF(LTRIM(RTRIM(@description)), N''),
        minimum_stock = @minimum_stock,
        updated_at = SYSDATETIME()
    WHERE id = @id;

    SELECT @id AS id, CAST(1 AS bit) AS success, N'Producto actualizado exitosamente.' AS message;
END;
GO

/* =========================================================================
   5. Eliminar un producto (borrado logico)
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_items_delete
    @id int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.inventory_tbl_items WHERE id = @id AND deleted = 0)
    BEGIN
        THROW 50013, N'El producto no existe o ya ha sido eliminado.', 1;
    END

    UPDATE dbo.inventory_tbl_items
    SET deleted = 1,
        is_active = 0,
        updated_at = SYSDATETIME()
    WHERE id = @id;

    SELECT @id AS id, CAST(1 AS bit) AS success, N'Producto eliminado exitosamente.' AS message;
END;
GO

/* =========================================================================
   6. Listar categorias activas de inventario
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_categories_list
AS
BEGIN
    SET NOCOUNT ON;

    SELECT id, name, description
    FROM dbo.inventory_tbl_categories
    WHERE deleted = 0 AND is_active = 1
    ORDER BY name;
END;
GO

/* =========================================================================
   7. Listar unidades activas de inventario
   ========================================================================= */
CREATE OR ALTER PROCEDURE dbo.inventory_sp_units_list
AS
BEGIN
    SET NOCOUNT ON;

    SELECT id, name, abbreviation
    FROM dbo.inventory_tbl_units
    WHERE deleted = 0 AND is_active = 1
    ORDER BY name;
END;
GO
