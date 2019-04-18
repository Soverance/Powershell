declare @number int = 0000000000

update [dbo].[Devices]
set    @number = @number + 1,    
       BarcodeTag = FORMAT(@Number, '000000000#')