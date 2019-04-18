
exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       use [?]
			EXEC (''GRANT CREATE TABLE TO db_Prism'')
END'
