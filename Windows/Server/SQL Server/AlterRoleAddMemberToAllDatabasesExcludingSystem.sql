
exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       use [?]
			EXEC (''ALTER ROLE [db_prism] ADD MEMBER [UA\SQL-Prism]'')
END'
