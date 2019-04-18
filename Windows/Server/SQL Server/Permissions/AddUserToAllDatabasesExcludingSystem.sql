
exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       use [?]
			EXEC (''CREATE USER [UA\SQL-Prism] FROM login [UA\SQL-Prism]'')
END'