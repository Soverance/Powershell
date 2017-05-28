# Build a Wordpress Web App with Azure database for MySQL (Preview)

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/Soverance/Powershell/master/Azure/Templates/WebApp_MySQL/WebApp_MySQL.json" target="_blank">
  <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https://raw.githubusercontent.com/Soverance/Powershell/master/Azure/Templates/WebApp_MySQL/WebApp_MySQL.json" target="_blank">
  <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template provides a easy way to deploy WordPress as an Azure Web App on Windows with Azure database for MySQL(Preview).

The template currently installs WordPress 4.3.1 and configures it for IIS.  The "wordpress-4.3.1-IIS.zip" file contained in this directory should be uploaded to an Azure storage blob (or any other online host), and then you must update the "packageUri" property of the MSDeploy extension within the template's website deployment section.