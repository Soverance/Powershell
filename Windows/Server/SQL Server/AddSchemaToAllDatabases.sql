declare @ssql varchar(2000)

set @ssql= 'use [?]
			EXEC (''CREATE SCHEMA [prism1]'')'

exec sp_MSforeachdb 'IF ''?''  NOT IN (''master'',''tempDB'',''model'',''msdb'')
BEGIN
       @ssql
END'
