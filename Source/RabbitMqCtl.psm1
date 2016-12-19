# To-Do
# 1. Update all documentation.
# 2. Carefully read all source code and correct any copy/paste errors.
# 3. Ensure that enough Write-Verbose calls are being made where needed for troubleshooting.
# 4. Redirect error output to the user.  Example: "Get-RabbitMqVHosts -VHostInfoItems garbage" fails silently

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
    #This command instructs RabbitMQ to create a (non-administrative) user named tonyg with (initial) password changeit at Node rabbit@HOSTNAME and suppresses informational messages.
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
	This command instructs RabbitMQ to clear the password for the given user. This user now cannot log in with a password (but may be able to through e.g. SASL EXTERNAL if configured).

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user to create.

.EXAMPLE
    #This command instructs RabbitMQ to clear the password for the user named tonyg at Node rabbit@HOSTNAME and suppresses informational messages.
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
	This command instructs RabbitMQ to authenticate the given user named with the given password.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user.

.PARAMETER Password
    The password of the user.

.EXAMPLE
    #This command instructs RabbitMQ to authenticate a user named tonyg with password verifyit at Node rabbit@HOSTNAME and suppresses informational messages.
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
    This command instructs RabbitMQ to list all users.

.DESCRIPTION
	Lists users. Each result row will contain the user name followed by a list of the tags set for that user.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command instructs RabbitMQ at node rabbit@HOSTNAME to list all users and their tags, suppress informational messages, and timeouot after 10 seconds.
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

        # pattern: word characters, space, non-digits (including space and comma)
        $pattern = '^(?<Username>[\w]+)\s+\[(?<Tags>[\D]*)\]$'
        Write-Verbose "Object creation pattern: $($pattern)"

        $results = @()
        $lines = $stdout -split "\n" | ForEach {
            if($_ -match $pattern) {
                $obj = [PSCustomObject]@{
                    Username = $matches.Username
                    Tags = @()
                }
                #Write-Verbose $matches.Username
                $matches.Tags -split ", " | ForEach {
                    $obj.Tags += $_
                    #Write-Verbose $_
                }
                $results += $obj
                Write-Verbose $obj
            }
        }
        Write-Verbose "Results: $($results.length)"
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqUsers"
        return $results
    }
}

Function Get-RabbitMqVHosts {
<#
.SYNOPSIS
    Lists virtual hosts.

.DESCRIPTION
	Lists virtual hosts.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.PARAMETER VHostInfoItems
    The vhostinfoitem parameter is used to indicate which virtual host information items to include in the results. The column order in the results will match the order of the parameters. vhostinfoitem can take any value from the list that follows:
        name:  The name of the virtual host with non-ASCII characters escaped as in C.
        tracing:  Whether tracing is enabled for this virtual host.

.EXAMPLE
    #This command instructs RabbitMQ at node rabbit@HOSTNAME to list all virtual hosts and whether or not they have tracing enabled, suppress informational messages, and timeouot after 10 seconds.
        Get-RabbitMqVHosts -Node "rabbit@HOSTNAME" -Timeout 10 -VHostInfoItems name,tracing

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
        [int] $Timeout,

        [Parameter(Mandatory=$false)]
        [string[]] $VHostInfoItems
    )
    
    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqVHosts"
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
        $rabbitControlParams = $rabbitControlParams + "list_vhosts"

        if ($VHostInfoItems)
        {
            Write-Verbose "Adding VHostInfoItems parameter."
            $rabbitControlParams = $rabbitControlParams + $VHostInfoItems
        }
        
        $stdOut = Get-StdOut -filename $rabbitControlPath -arguments $rabbitControlParams
        Write-Host $stdOut

        # this block allows the object creator to match output in arbitrary order (i.e. "name,tracing" vs "tracing,name")
        # host pattern: word characters and forward slashes
        $host_pattern = '(?<Hostname>[\w/]+)'
        # trace pattern: non-digits
        $trace_pattern = '(?<Tracing>\D+)'
        # join pattern: white space
        $join_pattern = '\s+'
        $params_pattern = ""
        $VHostInfoItems | ForEach {
            if($params_pattern -ne "") {
                $params_pattern += $join_pattern
            }
            if($_ -eq "name") {
                $params_pattern += $host_pattern
            }
            if($_ -eq "tracing") {
                $params_pattern += $trace_pattern
            }
        }
        if($params_pattern -eq "") {
            $params_pattern = $host_pattern
        }
        $final_pattern = "^$($params_pattern)$"
        Write-Verbose "Object creation pattern: $($final_pattern)"

        $results = @()
        $lines = $stdout -split "\n" | ForEach {
            if($_ -match $final_pattern) {
                $obj = [PSCustomObject]@{
                    Hostname = $matches.Hostname
                    Tracing = $matches.Tracing
                }
                #$Write-Verbose $matches.Hostname
                $results += $obj
                Write-Verbose $obj
            }
        }
        Write-Verbose "Results: $($results.length)"
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqVHosts"
        return $results
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
    #This command instructs RabbitMQ to delete a user named tonyg at Node rabbit@HOSTNAME and suppresses informational messages.
        Remove-RabbitMqUser -Node "rabbit@HOSTNAME" -Username tonyg

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
        Write-Verbose "Begin: Remove-RabbitMqUser"
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
        $rabbitControlParams = $rabbitControlParams + "delete_user"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $Username
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Remove-RabbitMqUser"
    }
}

Function Remove-RabbitMqVHost {
<#
.SYNOPSIS
    Deletes a virtual host from the RabbitMQ node.

.DESCRIPTION
    Deletes a virtual host from the RabbitMQ node.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER VHost
    The name of the virtual host to delete.

.EXAMPLE
    #This command instructs RabbitMQ to delete a virtual host named new_host at Node rabbit@HOSTNAME and suppresses informational messages.
        Remove-RabbitMqVHost -Node "rabbit@HOSTNAME" -VHost new_host

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
        Write-Verbose "Begin: Remove-RabbitMqVHost"
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
        $rabbitControlParams = $rabbitControlParams + "delete_vhost"

        Write-Verbose "Adding username parameter."
        $rabbitControlParams = $rabbitControlParams + $VHost
        
        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Remove-RabbitMqVHost"
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

Function Reset-RabbitMqPassword {
<#
.SYNOPSIS
    Changes the password for the specified user.

.DESCRIPTION
	This command instructs RabbitMQ to change the password for the user named tonyg to newpass.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Username
    The name of the user to create.

.PARAMETER NewPassword
    The new password the created user will use to log in to the broker.

.EXAMPLE
    #This command instructs RabbitMQ to update a user named tonyg with new password changedit at Node rabbit@HOSTNAME and suppresses informational messages.
        Reset-RabbitMqPassword -Node "rabbit@HOSTNAME" -Username tonyg -NewPassword changedit -Quiet

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
        Write-Verbose "Begin: Reset-RabbitMqPassword"
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
        Write-Verbose "End: Reset-RabbitMqPassword"
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
    #This command instructs RabbitMQ to ensure the user named tonyg is an administrator on the node rabbit@HOSTNAME and suppressed informational messages. This has no effect when the user logs in via AMQP, but can be used to permit the user to manage users, virtual hosts and permissions when the user logs in via some other means (for example with the management plugin).
        Set-RabbitMqUserTags -Node "rabbit@HOSTNAME" -Username tonyg -Tag administrator -Quiet

.EXAMPLE
    #This command instructs RabbitMQ to remove any tags from the user named tonyg.
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

        Write-Verbose "Adding tag parameter."
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

Function Get-RabbitMqStats {
<#
.SYNOPSIS
    Lists the RabbitMq queues present on a host, as well as metadata about the current queue state.

.DESCRIPTION
    This command returns requested metadata for each queue on the specified RabbitMQ node.
        -Available metadata includes: name (queue name), durable (does queue persist through restart), auto_delete (delete when unused), arguments, policy, pid, owner_pid, exclusive, exclusive_consumer_pid, exclusive_consumer_tag, messages_ready, messages_unacknowledged, messages, messages_ready_ram, messages_unacknowledged_ram, messages_ram, messages_persistent, message_bytes, message_bytes_ready, message_bytes_unacknowledged, message_bytes_ram, message_bytes_persistent, head_message_timestamp, disk_reads, disk_writes, consumers, consumer_utilisation, memory, slave_pids, synchronised_slave_pids, state
        

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    Get-RabbitMqStats name,messages,head_message_timestamp

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

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout,

        # rabbitmqctl parameter [--offline | --online | --local]
        [Parameter(Mandatory=$false)]
        [ValidateSet("offline", "online", "local")]
        [string] $Locale,

        # rabbitmqctl parameter [queueinfoitem]
        [Parameter(Mandatory=$false)]
        [ValidateSet("name", "durable", "auto_delete", "arguments", "policy", "pid", "owner_pid", "exclusive", "exclusive_consumer_pid", "exclusive_consumer_tag", "messages_ready", "messages_unacknowledged", "messages", "messages_ready_ram", "messages_unacknowledged_ram", "messages_ram", "messages_persistent", "message_bytes", "message_bytes_ready", "message_bytes_unacknowledged", "message_bytes_ram", "message_bytes_persistent", "head_message_timestamp", "disk_reads", "disk_writes", "consumers", "consumer_utilisation", "memory", "slave_pids", "synchronised_slave_pids", "state")]
        [String[]] $InfoItems
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqStats"
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

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet -Timeout $Timeout

        Write-Verbose "Adding command parameter."
        if($Locale) {
            $LocaleFlag = "--$Locale"
        }

        $rabbitControlParams = $rabbitControlParams + "list_queues $LocaleFlag $InfoItems"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqStats"
    }
}

Function Get-RabbitMqPermissions {
<#
.SYNOPSIS
    For a given user, lists the RabbitMq hosts and the granted permissions on each host.

.DESCRIPTION
    This command returns a list of permissions by virtual host for a given user.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command instructs the RabbitMQ broker to list all the virtual hosts to which the user named tonyg has been granted access, and the permissions the user has for operations on resources in these virtual hosts. 
    Get-RabbitMqPermissions admin

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [username]
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Username,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqPermissions"
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

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet -Timeout $Timeout

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_user_permissions $Username"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqPermissions"
    }
}

Function Get-RabbitMqBindings {
<#
.SYNOPSIS
    Lists the RabbitMq bindings (routing info) for a vhost.

.DESCRIPTION
    Returns binding details and metadata. By default the bindings for the / virtual host are returned. The "-VHost" flag can be used to override this default. 
        -Available metadata includes: source_name (message source), source_kind ("exchange"), destination_name (message destination), destination_kind (destination type), routing_key (topic), arguments (key-value to match for routing)
        -By default, all metadata items are displayed.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root vhost.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command displays the exchange name and queue name of the bindings in the virtual host named local_rabbitmq.
    Get-RabbitMqBindings Get-RabbitMqBindings -VHost local_rabbitmq -InfoItems source_name,destination_name

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout,

        # rabbitmqctl parameter [bindinginfoitem]
        [Parameter(Mandatory=$false)]
        [ValidateSet("source_name", "source_kind", "destination_name", "destination_kind", "routing_key", "arguments")]
        [String[]] $InfoItems
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqBindings"
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

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet -Timeout $Timeout
        if($VHost){
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_bindings $InfoItems"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqBindings"
    }
}

Function Get-RabbitMqChannels {
<#
.SYNOPSIS
    Lists the RabbitMq channels (logical containers for AMQP commands) for a vhost.

.DESCRIPTION
    Returns channel details and metadata. By default the channels for the / virtual host are returned. The "-VHost" flag can be used to override this default.
        -Available metadata includes: pid (Erlang process id), connection (Erlang process id), name (readable name), number (unique identifier within connection), user (username), vhost (virtual host), transactional (transact mode Y/N), confirm (confirmation mode Y/N), consumer_count (quantity of logical listeners), messages_unacknowledged (quantity delivered but not ack-ed), messages_uncommitted (quantity of messages in a pending transaction), acks_uncommitted (acks in a pending transaction), messages_unconfirmed (quantity sent but not confirmed, if in confirm mode), prefetch_count (QoS prefetch quantity allowed for new consumers), global_prefetch_count (QoS prefetch quantity allowed for channel)
        -Default metadata is pid, user, consumer_count, and messages_unacknowledged.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root vhost.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command displays the name and username associated with the channel, and whether confirm mode is enabled for the virtual host named local_rabbitmq.
    Get-RabbitMqChannels -VHost local_rabbitmq -InfoItems name,user,confirm

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout,

        # rabbitmqctl parameter [bindinginfoitem]
        [Parameter(Mandatory=$false)]
        [ValidateSet("pid", "connection", "name", "number","user", "vhost", "transactional", "confirm", "consumer_count", "messages_unacknowledged", "messages_uncommitted","acks_uncommitted", "messages_unconfirmed", "prefetch_count", "global_prefetch_count")]
        [String[]] $InfoItems
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqChannels"
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

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet -Timeout $Timeout
        if($VHost){
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_channels $InfoItems"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqChannels"
    }
}

Function Get-RabbitMqConnections {
<#
.SYNOPSIS
    Lists the RabbitMq connections (TCP/IP info) for a vhost.

.DESCRIPTION
    Returns connection details and metadata. By default the connections for the "/" virtual host are returned. The "-VHost" flag can be used to override this default.
        -Available metadata includes: pid (Erlang process id), name (readable name), port (server port), host (DNS name or IP), peer_port (port for peer-to-peer connections), peer_host (DNS name or IP), ssl (enabled Y/N), ssl_protocol (i.e. "TLSv1"), ssl_key_exchange (i.e. "RSA"), ssl_cipher (i.e. "aes_256_cbc"), ssl_hash (i.e. "SHA"), peer_cert_subject (RFC4514 name, i.e. "CN=Surname\, Lastname,OU=Users,DC=Foo,DC=net"), peer_cert_issuer (RFC4514 name), peer_cert_validity (date of expiration), state ([starting, tuning, opening, running, flow, blocking, blocked, closing, closed]), channels (quantity of channels), protocol (version in use), auth_mechanism (SASL auth, i.e. "PLAIN"), user (username), vhost, timeout (seconds), frame_max (bytes), channel_max (channel quantity limit), client_properties (sent from client), recv_oct (octets received), recv_cnt (packets received), send_oct (octets received), send_cnt (packets sent), send_pend (send queue size), connected_at (time connection established)
        -Default metadata is user, peer host, peer port, time since flow control and memory block state.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root vhost.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command displays the name and username associated with the channel, and whether confirm mode is enabled for the virtual host named local_rabbitmq.
    Get-RabbitMqChannels -VHost local_rabbitmq -InfoItems name,user,confirm

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [-t timeout]
        [Parameter(Mandatory=$false)]
        [int] $Timeout,

        # rabbitmqctl parameter [bindinginfoitem]
        [Parameter(Mandatory=$false)]
        [ValidateSet("pid", "connection", "name", "number","user", "vhost", "transactional", "confirm", "consumer_count", "messages_unacknowledged", "messages_uncommitted","acks_uncommitted", "messages_unconfirmed", "prefetch_count", "global_prefetch_count")]
        [String[]] $InfoItems
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqConnections"
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

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet -Timeout $Timeout
        if($VHost){
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_connections $InfoItems"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqConnections"
    }
}

# Export Declarations --------------------------------------------------------------------------------------------------
Export-ModuleMember -Function Add-RabbitMqUser
Export-ModuleMember -Function Add-RabbitMqVHost
Export-ModuleMember -Function Clear-RabbitMqPassword
Export-ModuleMember -Function Confirm-RabbitMqCredentials
Export-ModuleMember -Function Get-RabbitMqBindings
Export-ModuleMember -Function Get-RabbitMqChannels
Export-ModuleMember -Function Get-RabbitMqConnections
Export-ModuleMember -Function Get-RabbitMqPermissions
Export-ModuleMember -Function Get-RabbitMqStats
Export-ModuleMember -Function Get-RabbitMqUsers
Export-ModuleMember -Function Get-RabbitMqVHosts
Export-ModuleMember -Function Remove-RabbitMqUser
Export-ModuleMember -Function Remove-RabbitMqVHost
Export-ModuleMember -Function Reset-RabbitMPassword
Export-ModuleMember -Function Reset-RabbitMq
Export-ModuleMember -Function Start-RabbitMq
Export-ModuleMember -Function Set-RabbitMqUserTags
Export-ModuleMember -Function Stop-RabbitMq
Export-ModuleMember -Function Wait-RabbitMq
