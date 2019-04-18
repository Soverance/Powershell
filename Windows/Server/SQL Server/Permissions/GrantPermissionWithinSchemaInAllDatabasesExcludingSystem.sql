
exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       use [?]
			EXEC (''GRANT ALTER, INSERT, SELECT, UPDATE ON SCHEMA :: prism TO [UA\SQL-Prism]'')
END'
