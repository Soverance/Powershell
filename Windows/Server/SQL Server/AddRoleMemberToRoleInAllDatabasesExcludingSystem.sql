
exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       use [?]
			EXEC (''sp_addrolemember db_CreateStoredProcedure, "UA\SQL-Prism"'')
END'
