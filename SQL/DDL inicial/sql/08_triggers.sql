/*
    Kronos - 08_triggers.sql

    Triggers puntuales para reglas que conviene proteger desde base de datos.
*/

SET NOCOUNT ON;
USE Kronos;

EXEC(N'
CREATE TRIGGER service_trg_events_status_history
ON service_tbl_events
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(status_id)
    BEGIN
        INSERT INTO service_tbl_event_status_history
            (service_event_id, old_status_id, new_status_id, reason, changed_by_user_id, changed_at)
        SELECT
            i.id,
            d.status_id,
            i.status_id,
            N''Cambio de estado automático registrado por trigger.'',
            i.created_by_user_id,
            SYSDATETIME()
        FROM inserted i
        INNER JOIN deleted d ON d.id = i.id
        WHERE ISNULL(i.status_id, -1) <> ISNULL(d.status_id, -1);
    END;
END;
');

EXEC(N'
CREATE TRIGGER inventory_trg_movements_batch_quantity
ON inventory_tbl_movements
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE b
    SET
        quantity_available =
            CASE mt.value
                WHEN N''in'' THEN b.quantity_available + i.quantity
                WHEN N''out'' THEN b.quantity_available - i.quantity
                ELSE b.quantity_available
            END,
        updated_at = SYSDATETIME()
    FROM inventory_tbl_batches b
    INNER JOIN inserted i ON i.inventory_batch_id = b.id
    INNER JOIN config_tbl_catalog_items mt ON mt.id = i.movement_type_id
    WHERE mt.value IN (N''in'', N''out'');

    IF EXISTS (SELECT 1 FROM inventory_tbl_batches WHERE quantity_available < 0)
    BEGIN
        THROW 50000, N''Inventory batch quantity cannot be negative.'', 1;
    END;
END;
');

SET NOCOUNT OFF;
