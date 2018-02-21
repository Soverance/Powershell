
exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       use [?]
			EXEC (''ALTER AUTHORIZATION ON SCHEMA::[prism] TO db_prism'')
END'