# To-Do
# 1. Update all documentation.
# 2. Carefully read all source code and correct any copy/paste errors.
# 3. Ensure that enough Write-Verbose calls are being made where needed for troubleshooting.

# Private Functions ----------------------------------------------------------------------------------------------------
Function Build-RabbitMq-Params {
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

Function Find-RabbitMqCtl {
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

Function Get-StdOut {
    param (
        [Parameter(Mandatory=$true)]
        [String] $filename,

        [Parameter(Mandatory=$false)]
        [string[]] $arguments
    )

    $commandString = "$rabbitControlPath $rabbitControlParams"
    Write-Verbose "Executing command: $commandString"
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $filename
    $processInfo.RedirectStandardError = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.UseShellExecute = $false

    if ($arguments)
    {
        $processInfo.Arguments = $arguments
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $process.WaitForExit()

    if ($process.ExitCode -ne 0)
    {
        Write-Error "Error:  Error executing command:  $commandString"
        $stderr = $process.StandardError.ReadToEnd()
        throw $stderr
    }

    Write-Verbose "Getting output from command $commandString"
    $stdout = $process.StandardOutput.ReadToEnd()
    return $stdout
}





# Exported Module Functions --------------------------------------------------------------------------------------------
Function Add-RabbitMqUser {
<#
.SYNOPSIS
    Adds a new user to the RabbitMQ node.

.DESCRIPTION
    Adds a new user to the RabbitMQ node.

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
        Add-RabbitMqUser -Node "rabbit@HOSTNAME" -Username tonyg -Password chageit -Quiet

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
        Write-Verbose "Begin: Add-RabbitMqUser"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

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
        Write-Verbose "End: Add-RabbitMqUser"
    }
}

Function Add-RabbitMqVHost {
<#
.SYNOPSIS
    Creates a new virtual host on the RabbitMQ node.

.DESCRIPTION
    Creates a new virtual host on the RabbitMQ node.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER VHost
    The name of the virtual host to create.

.EXAMPLE
    #This command instructs RabbitMQ to create a virtual host named new_host Node rabbit@HOSTNAME and suppresses informational messages.
        Add-RabbitMqVHost -Node "rabbit@HOSTNAME" -VHost new_host -Password chageit -Quiet

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
        [string] $VHost
    )
    
    Begin
    {
        Write-Verbose "Begin: Add-RabbitMqVHost"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "add_vhost"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $VHost

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Add-RabbitMqVHost"
    }
}

Function Clear-RabbitMqPassword {
<#
.SYNOPSIS
    Removes the password for the specified user.

.DESCRIPTION
	This command instructs the RabbitMQ broker to clear the password for the given user. This user now cannot log in with a password (but may be able to through e.g. SASL EXTERNAL if configured).

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user to create.

.EXAMPLE
    #This command instructs the RabbitMQ broker to clear the password for the user named tonyg at Node rabbit@HOSTNAME and suppresses informational messages.
        Clear-RabbitMqPassword -Node "rabbit@HOSTNAME" -Username tonyg -Quiet

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
        Write-Verbose "Begin: Clear-RabbitMPassword"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "clear_password"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMq"
    }
}

Function Confirm-RabbitMqCredentials {
<#
.SYNOPSIS
    Authenticates the given username and password.

.DESCRIPTION
	This command instructs the RabbitMQ broker to authenticate the given user named with the given password.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user.

.PARAMETER Password
    The password of the user.

.EXAMPLE
    #This command instructs the RabbitMQ broker to authenticate a user named tonyg with password verifyit at Node rabbit@HOSTNAME and suppresses informational messages.
        Confirm-RabbitMqCredentials -Node "rabbit@HOSTNAME" -Username tonyg -Password verifyit -Quiet

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
        Write-Verbose "Begin: Confirm-RabbitMqCredentials"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "authenticate_user"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username

        Write-Verbose "Adding password parameter."
        $rabbitControlParams = $rabbitControlParams + $Password
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMq"
    }
}

Function Get-RabbitMqUsers {
<#
.SYNOPSIS
    This command instructs the RabbitMQ broker to list all users.

.DESCRIPTION
	Lists users. Each result row will contain the user name followed by a list of the tags set for that user.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.PARAMETER Password
    The password of the user.

.EXAMPLE
    #This command instructs the RabbitMQ broker at node rabbit@M6800 to list all users and their tags, suppress informational messages, and timeouot after 10 seconds.
        Get-RabbitMqUsers -Node "rabbit@HOSTNAME" -Quiet -Timeout 10

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout
    )
    
    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqUsers"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $true -Timeout $Timeout

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_users"
        
        $stdOut = Get-StdOut -filename $rabbitControlPath -arguments $rabbitControlParams
        Write-Host $stdOut

        # $userInfo = $stdOut | ConvertFrom-String -TemplateFile .\usersAndTags.template.txt
        # Write-Host $userInfo
        # $userInfo | ForEach-Object {
        #     $username = $_.Username
        #     Write-Verbose $username
        # }
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqUsers"
    }
}

Function Remove-RabbitMqUser {
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
        Delete-RabbitMqUser -Node "rabbit@HOSTNAME" -Username tonyg

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
        Write-Verbose "Begin: Delete-RabbitMqUser"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Deleteing command parameter."
        $rabbitControlParams = $rabbitControlParams + "delete_user"

        Write-Verbose "Deleteing username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMq"
    }
}

Function Reset-RabbitMq {
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
        Reset-RabbitMq -Node "rabbit@HOSTNAME" -Quiet

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
        Write-Verbose "Begin: Reset-RabbitMq"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

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
        Write-Verbose "End: Reset-RabbitMq"
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
        Reset-RabbitMqPassword -Node "rabbit@HOSTNAME" -Username tonyg -NewPassword chagedit -Quiet

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
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

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
        Write-Verbose "End: Reset-RabbitMq"
    }
}

Function Start-RabbitMq {
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
        Start-RabbitMq -Node "rabbit@HOSTNAME" -Quiet

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
        Write-Verbose "Begin: Start-RabbitMq"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "start_app"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Start-RabbitMq"
    }
}

Function Set-RabbitMqUserTags {
<#
.SYNOPSIS
    Sets user tags in RabbitMQ.

.DESCRIPTION
	Sets the given tag for the given user in the given RabbitMQ node.  If no tags are given, removes all tags from the given user.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user whose tags are to be set.

.PARAMETER Tag
    Zero, one or more tags to set. Any existing tags will be removed.

.EXAMPLE
    #This command instructs the RabbitMQ broker to ensure the user named tonyg is an administrator on the node rabbit@M6800 and suppressed informational messages. This has no effect when the user logs in via AMQP, but can be used to permit the user to manage users, virtual hosts and permissions when the user logs in via some other means (for example with the management plugin).
        Set-RabbitMqUserTags -Node "rabbit@HOSTNAME" -Username tonyg -Tag administrator -Quiet

.EXAMPLE
    #This command instructs the RabbitMQ broker to remove any tags from the user named tonyg.
        Set-RabbitMqUserTags -Username tonyg

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
        [string[]] $Tag
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqUserTags"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "set_user_tags"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username

        Write-Verbose "Adding password parameter."
        $rabbitControlParams = $rabbitControlParams + $Tag
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqUserTags"
    }
}

Function Stop-RabbitMq {
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
        Stop-RabbitMq -Node "rabbit@HOSTNAME" -Quiet

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
        Write-Verbose "Begin: Stop-RabbitMq"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "stop_app"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Start-RabbitMq"
    }
}

Function Wait-RabbitMq {
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
    Wait-RabbitMq -PidFile "/var/run/rabbitmq/pid"

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
        Write-Verbose "Begin: Wait-RabbitMq"
    }
    
    Process
    {
        Try
        {
            $rabbitControlPath = Find-RabbitMqCtl
        }
        
        Catch
        {
            Break
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "wait $PidFile"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Wait-RabbitMq"
    }
}





# Export Declarations --------------------------------------------------------------------------------------------------
Export-ModuleMember -Function Add-RabbitMqUser
Export-ModuleMember -Function Add-RabbitMqVHost
Export-ModuleMember -Function Clear-RabbitMqPassword
Export-ModuleMember -Function Confirm-RabbitMqCredentials
Export-ModuleMember -Function Get-RabbitMqUsers
Export-ModuleMember -Function Remove-RabbitMqUser
Export-ModuleMember -Function Reset-RabbitMPassword
Export-ModuleMember -Function Reset-RabbitMq
Export-ModuleMember -Function Start-RabbitMq
Export-ModuleMember -Function Set-RabbitMqUserTags
Export-ModuleMember -Function Stop-RabbitMq
Export-ModuleMember -Function Wait-RabbitMq
