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
Function Disable-RabbitMQManagement {
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
    [cmdletbinding()]
    param ()

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
		[string[]] $rabbitPluginsParams = "disable rabbitmq_management"

        Write-Verbose "Executing command: $rabbitPluginsPath $rabbitPluginsParams"
		Start-Process -ArgumentList $rabbitPluginsParams -FilePath "$rabbitPluginsPath" -NoNewWindow -Wait
	}

    End
    {
        Write-Verbose "End: Disable-RabbitMQ-Management"
    }
}

Function Enable-RabbitMQManagement {
<#
.SYNOPSIS
    Enables the RabbitMQ Management Plugin.

.DESCRIPTION
    Enables the RabbitMQ Management Plugin.

.EXAMPLE
    # Enable the RabbitMQ Management Plugin.
	    Enable-RabbitMQ-Management

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param ()

	Begin
	{
        Write-Verbose "Begin: Enable-RabbitMQ-Management"
	}
	
	Process
	{
		Try
		{
            $rabbitPluginsPath = Find-RabbitMQ-Plugins
		}
		
		Catch
		{yy
			Break
		}

        Write-Verbose "Adding command parameter."
		[string[]] $rabbitPluginsParams = "enable rabbitmq_management"

        Write-Verbose "Executing command: $rabbitPluginsPath $rabbitPluginsParams"
		Start-Process -ArgumentList $rabbitPluginsParams -FilePath "$rabbitPluginsPath" -NoNewWindow -Wait
	}

    End
    {
        Write-Verbose "End: Enable-RabbitMQ-Management"
    }
}





# Export Declarations --------------------------------------------------------------------------------------------------
Export-ModuleMember -Function Disable-RabbitMQManagement
Export-ModuleMember -Function Enable-RabbitMQManagement
