# Private Functions ----------------------------------------------------------------------------------------------------
Function Find-RabbitMQ-Plugins {
    Write-Verbose "Checking for rabbitmq-plugins on the system path."
    $rabbitCommand = Get-Command "rabbitmq-plugins.bat"
    if ($?)
    {
        $rabbitPluginsPath = $rabbitCommand.Source
        return $rabbitPluginsPath
    }

    else
    {
		Write-Error "Error:  Could not find rabbitmq-plugins.bat in user or system path.  Make sure rabbitmq-plugins is installed and its installation directory is in your system or user path."
        throw "Could not find rabbitmq-plugins.bat in user or system path.  Make sure rabbitmq-plugins is installed and its installation directory is in your system or user path."
    }
}





# Exported Module Functions --------------------------------------------------------------------------------------------
Function Disable-RabbitMQ-Management {
<#
.SYNOPSIS
    Disables the RabbitMQ Management Plugin.

.DESCRIPTION
    Disables the RabbitMQ Management Plugin.

.EXAMPLE
    # Disable the RabbitMQ Management Plugin.
	    Disable-RabbitMQ-Management

.FUNCTIONALITY
    RabbitMQ
#>
	Begin
	{
        Write-Verbose "Begin: Disable-RabbitMQ-Management"
	}
	
	Process
	{
		Try
		{
            $rabbitPluginsPath = Find-RabbitMQ-Plugins
		}
		
		Catch
		{
			Break
		}

        Write-Verbose "Adding command parameter."
		$rabbitPluginsParams = "enable rabbitmq_management"

        Write-Verbose "Executing command: $rabbitPluginsPath $rabbitPluginsParams"
		Start-Process -ArgumentList $rabbitPluginsParams -FilePath "$rabbitPluginsPath" -NoNewWindow -Wait
	}

    End
    {
        Write-Verbose "End: Disable-RabbitMQ-Management"
    }
}






# Export Declarations --------------------------------------------------------------------------------------------------
Export-ModuleMember -Function Disable-RabbitMQ-Management
