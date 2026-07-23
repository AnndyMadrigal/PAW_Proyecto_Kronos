---------Insert de elementos/insumos medicos

INSERT INTO inventory_tbl_items
(
    inventory_category_id,
    inventory_unit_id,
    name,
    description,
    minimum_stock,
    requires_expiration_date,
    is_active,
    deleted,
    created_at,
    updated_at
)
VALUES
(1,2,'Guantes de látex','Protección de manos',100,1,1,0,GETDATE(),NULL),
(1,2,'Mascarilla quirúrgica','Protección respiratoria',200,1,1,0,GETDATE(),NULL),
(1,1,'Jeringa 5ml','Aplicación de medicamentos',150,1,1,0,GETDATE(),NULL),
(1,1,'Jeringa 10ml','Aplicación de medicamentos',100,1,1,0,GETDATE(),NULL),
(1,3,'Gasas estériles','Curación de heridas',300,1,1,0,GETDATE(),NULL),
(1,8,'Venda elástica','Soporte y compresión',50,1,1,0,GETDATE(),NULL),
(1,12,'Algodón médico','Limpieza y curación',100,1,1,0,GETDATE(),NULL),
(1,5,'Alcohol 70%','Desinfección',80,1,1,0,GETDATE(),NULL),
(1,4,'Suero fisiológico','Lavado e hidratación',60,1,1,0,GETDATE(),NULL),
(1,2,'Curitas adhesivas','Cobertura de heridas',200,1,1,0,GETDATE(),NULL),
(1,1,'Termómetro digital','Medición de temperatura',20,0,1,0,GETDATE(),NULL),
(1,3,'Baja lenguas','Examen oral',100,0,1,0,GETDATE(),NULL),
(1,1,'Catéter intravenoso','Acceso venoso',50,1,1,0,GETDATE(),NULL),
(1,1,'Equipo de venoclisis','Administración de sueros',40,1,1,0,GETDATE(),NULL),
(1,3,'Apósito estéril','Protección de heridas',100,1,1,0,GETDATE(),NULL);
(1,3,'Hisopos estériles','Toma de muestras',150,1,1,0,GETDATE(),NULL),
(1,2,'Lancetas','Punción capilar',200,1,1,0,GETDATE(),NULL),
(1,8,'Micropore','Fijación de apósitos',50,1,1,0,GETDATE(),NULL),
(1,8,'Esparadrapo','Fijación médica',50,1,1,0,GETDATE(),NULL),
(1,2,'Gorro desechable','Protección sanitaria',100,1,1,0,GETDATE(),NULL),
(1,2,'Cubrezapatos','Protección sanitaria',100,1,1,0,GETDATE(),NULL),
(1,1,'Tijera quirúrgica','Corte de material médico',10,0,1,0,GETDATE(),NULL),
(1,1,'Pinza clínica','Manipulación de material',10,0,1,0,GETDATE(),NULL),
(1,3,'Compresas estériles','Curación de heridas',100,1,1,0,GETDATE(),NULL),
(1,5,'Agua oxigenada','Desinfección',30,1,1,0,GETDATE(),NULL),
(1,5,'Yodo povidona','Antisepsia de piel',30,1,1,0,GETDATE(),NULL),
(1,4,'Gel antibacterial','Higiene de manos',40,1,1,0,GETDATE(),NULL),
(1,2,'Toallas con alcohol','Desinfección rápida',100,1,1,0,GETDATE(),NULL),
(1,7,'Guantes estériles','Procedimientos médicos',50,1,1,0,GETDATE(),NULL),
(1,3,'Mascarilla N95','Protección respiratoria',100,1,1,0,GETDATE(),NULL);

---------------------------

SELECT * FROM inventory_tbl_units;

