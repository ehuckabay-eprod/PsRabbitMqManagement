# Private Functions ----------------------------------------------------------------------------------------------------
Function Build-RabbitMQ-Params {
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [bool] $Quiet,

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout
    )

    Write-Verbose "Building common RabbitMQ parameters"
    [string[]] $rabbitControlParams = @()

    if ($Node -and $Node -ne "")
    {
        Write-Verbose "Adding node parameter."
        $rabbitControlParams = $rabbitControlParams + "-n $Node"
    }
        
    if ($Quiet)
    {
        Write-Verbose "Adding quiet parameter."
        $rabbitControlParams = $rabbitControlParams + "-q"
    }

    if ($Timeout)
    {
        Write-Verbose "Adding timeout parameter."
        $rabbitControlParams = $rabbitControlParams + "-t $Timeout"
    }

    return $rabbitControlParams
}

Function Find-RabbitMQCtl {
    Write-Verbose "Checking for rabbitmqctl on the system path."
    $rabbitCommand = Get-Command "rabbitmqctl.bat"
    if ($?)
    {
        $rabbitControlPath = $rabbitCommand.Source
        return $rabbitControlPath
    }

    else
    {
        Write-Error "Error:  Could not find rabbitmqctl.bat in user or system path.  Make sure rabbitmqctl is installed and its installation directory is in your system or user path."
        throw "Could not find rabbitmqctl.bat in user or system path.  Make sure rabbitmqctl is installed and its installation directory is in your system or user path."
    }
}





# Exported Module Functions --------------------------------------------------------------------------------------------
Function Add-RabbitMQUser {
<#
.SYNOPSIS
    Adds a new user to the RabbitMQ node.

.DESCRIPTION

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user to create.

.PARAMETER Password
    The password the created user will use to log in to the broker.

.EXAMPLE
    #This command instructs the RabbitMQ broker to create a (non-administrative) user named tonyg with (initial) password changeit at Node rabbit@HOSTNAME and suppresses informational messages.
        Add-RabbitMQUser -Node "rabbit@HOSTNAME" -Username tonyg -Password chageit -Quiet

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        [Parameter(Mandatory=$true)]
        [string] $Username,

        [Parameter(Mandatory=$true)]
        [string] $Password
    )
    
    Begin
    {
        Write-Verbose "Begin: Add-RabbitMQUser"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "add_user"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username

        Write-Verbose "Adding password parameter."
        $rabbitControlParams = $rabbitControlParams + $Password
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMQ"
    }
}

Function Remove-RabbitMQUser {
<#
.SYNOPSIS
    Deletes a user from the RabbitMQ node.

.DESCRIPTION

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user to delete.

.EXAMPLE
    #This command instructs the RabbitMQ broker to delete a user named tonyg at Node rabbit@HOSTNAME and suppresses informational messages.
        Delete-RabbitMQUser -Node "rabbit@HOSTNAME" -Username tonyg

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        [Parameter(Mandatory=$true)]
        [string] $Username
    )
    
    Begin
    {
        Write-Verbose "Begin: Delete-RabbitMQUser"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Deleteing command parameter."
        $rabbitControlParams = $rabbitControlParams + "delete_user"

        Write-Verbose "Deleteing username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMQ"
    }
}

Function Reset-RabbitMQ {
<#
.SYNOPSIS
    Return a RabbitMQ node to its virgin state.

.DESCRIPTION
    This command resets the RabbitMQ node.
        -Removes the node from any cluster it belongs to, removes all data from the management database, such as configured users and vhosts, and deletes all persistent messages.
        -For reset to succeed the RabbitMQ application must have been stopped, e.g. with stop_app.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Force
    If present, we will use force_reset instead of reset.  The force_reset command differs from reset in that it resets the node unconditionally, regardless of the current management database state and cluster configuration. It should only be used as a last resort if the database or cluster configuration has been corrupted.

.EXAMPLE
    #Reset the RabbitMQ application at Node rabbit@HOSTNAME to its virgin state and suppress informational messages.
        Reset-RabbitMQ -Node "rabbit@HOSTNAME" -Quiet

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        [Parameter(Mandatory=$false)]
        [switch] $Force
    )
    
    Begin
    {
        Write-Verbose "Begin: Reset-RabbitMQ"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        if ($Force)
        {
            $rabbitControlParams = $rabbitControlParams + "force_reset"
        }

        else
        {
            $rabbitControlParams = $rabbitControlParams + "reset"
        }


        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMQ"
    }
}

Function Reset-RabbitMPassword {
<#
.SYNOPSIS
    Changes the password for the specified user.

.DESCRIPTION
	This command instructs the RabbitMQ broker to change the password for the user named tonyg to newpass.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user to create.

.PARAMETER NewPassword
    The new password the created user will use to log in to the broker.

.EXAMPLE
    #This command instructs the RabbitMQ broker to update a user named tonyg with new password changedit at Node rabbit@HOSTNAME and suppresses informational messages.
        Reset-RabbitMQPassword -Node "rabbit@HOSTNAME" -Username tonyg -NewPassword chagedit -Quiet

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        [Parameter(Mandatory=$true)]
        [string] $Username,

        [Parameter(Mandatory=$true)]
        [string] $NewPassword
    )
    
    Begin
    {
        Write-Verbose "Begin: Reset-RabbitMPassword"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "change_password"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username

        Write-Verbose "Adding new password parameter."
        $rabbitControlParams = $rabbitControlParams + $NewPassword
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMQ"
    }
}

Function Start-RabbitMQ {
<#
.SYNOPSIS
    Starts the RabbitMQ application.

.DESCRIPTION
    This command instructs the RabbitMQ node to start the RabbitMQ application.  Details:
        -This command is typically run prior to performing other management actions that require the RabbitMQ application to be startped, e.g. reset.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Start the RabbitMQ application at Node rabbit@HOSTNAME and suppress informational messages.
        Start-RabbitMQ -Node "rabbit@HOSTNAME" -Quiet

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Start-RabbitMQ"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "start_app"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Start-RabbitMQ"
    }
}

Function Stop-RabbitMQ {
<#
.SYNOPSIS
    Stops the RabbitMQ application.

.DESCRIPTION
    This command instructs the RabbitMQ node to stop the RabbitMQ application.  Details:
        -This command is typically run prior to performing other management actions that require the RabbitMQ application to be stopped, e.g. reset.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker stopup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Stop the RabbitMQ application at Node rabbit@HOSTNAME and suppress informational messages.
        Stop-RabbitMQ -Node "rabbit@HOSTNAME" -Quiet

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Stop-RabbitMQ"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "stop_app"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Start-RabbitMQ"
    }
}

Function Wait-RabbitMQ {
<#
.SYNOPSIS
    Waits for the RabbitmQ application to start.  NOT SUPPORTED IF RABBITMQ IS RUNNING ON WINDOWS.

.DESCRIPTION
    This command will return when the RabbitMQ node has started up.
        -This command will wait for the RabbitMQ application to start at the node. It will wait for the pid file to be created, then for a process with a pid specified in the pid file to start, and then for the RabbitMQ application to start in that process. It will fail if the process terminates without starting the RabbitMQ application.
        -A suitable pid file is created by the rabbitmq-server script. By default this is located in the Mnesia directory. Modify the RABBITMQ_PID_FILE environment variable to change the location.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER PidFile
    File in which the process id is placed.  Default on Linux is $RABBITMQ_MNESIA_DIR.pid

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    Wait-RabbitMQ -PidFile "/var/run/rabbitmq/pid"

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter {pid_file}
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $PidFile,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )

    Begin
    {
        Write-Verbose "Begin: Wait-RabbitMQ"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMQCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMQ-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "wait $PidFile"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Wait-RabbitMQ"
    }
}





# Export Declarations --------------------------------------------------------------------------------------------------
Export-ModuleMember -Function Add-RabbitMQUser
Export-ModuleMember -Function Remove-RabbitMQUser
Export-ModuleMember -Function Reset-RabbitMPassword
Export-ModuleMember -Function Reset-RabbitMQ
Export-ModuleMember -Function Start-RabbitMQ
Export-ModuleMember -Function Stop-RabbitMQ
Export-ModuleMember -Function Wait-RabbitMQ
