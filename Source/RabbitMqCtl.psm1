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
        [string[]] $arguments,

        #timeout in seconds
        [Parameter(Mandatory=$false)]
        [int] $Timeout=20
    )

    if($Timeout = 0){
        $Timeout = 20
    }

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
    $process.WaitForExit($Timeout * 1000)

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
        Add-RabbitMqUser -Node "rabbit@HOSTNAME" -Username tonyg -Password changeit -Quiet

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
        Add-RabbitMqVHost -Node "rabbit@HOSTNAME" -VHost new_host -Quiet

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

        Write-Verbose "Adding vhost parameter."
        $rabbitControlParams = $rabbitControlParams + $VHost

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Add-RabbitMqVHost"
    }
}

Function Clear-RabbitMqParameter {
<#
.SYNOPSIS
    Removes the value of a specific cluster-wide parameter for the specified vhost.

.DESCRIPTION
    This command instructs RabbitMQ to clear the value of a parameter on the cluster / vhost. In general, you should refer to the documentation for the feature in question (i.e. federation) to see how to set and clear parameters.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Component
    The name of the component the parameter applies to.

.PARAMETER ParamName
    The name of the parameter whose value should be cleared.

.EXAMPLE
    #This command instructs RabbitMQ to clear the service account name used for federation at VHost local_rabbitmq, sending the command via Node rabbit@HOSTNAME.
        Clear-RabbitMqParameter -Node "rabbit@HOSTNAME" -VHost local_rabbitmq -ParamName local_username -Component federation

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

        [Parameter(Mandatory=$true)]
        [string] $Component,

        [Parameter(Mandatory=$true)]
        [string] $ParamName
    )
    
    Begin
    {
        Write-Verbose "Begin: Clear-RabbitMqParameter"
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
        $rabbitControlParams = $rabbitControlParams + "clear_parameter"

        Write-Verbose "Adding component parameter."
        $rabbitControlParams = $rabbitControlParams + $Component
        
        Write-Verbose "Adding parameter name parameter."
        $rabbitControlParams = $rabbitControlParams + $ParamName

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Clear-RabbitMqParameter"
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
        Write-Verbose "Begin: Clear-RabbitMqPassword"
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
        Write-Verbose "End: Clear-RabbitMqPassword"
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
        Write-Verbose "End: Confirm-RabbitMqCredentials"
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

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

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

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet -Timeout $Timeout

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_users"
        
        $stdOut = Get-StdOut -filename $rabbitControlPath -arguments $rabbitControlParams -Timeout $Timeout
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
        
        $stdOut = Get-StdOut -filename $rabbitControlPath -arguments $rabbitControlParams -Timeout $Timeout
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

.PARAMETER Force
    Forces the node to start, overriding failure to start because the node was not the last in its cluster to shut down.  Note that this may be destructive in that any changes to the cluster after this node was shut down may be lost.  If the last node was permanently lost, use Remove-RabbitMqNodeFromCluster -ForceWhileOffline instead, to ensure the mirrored queues get promoted.

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
        [switch] $Quiet,

        # rabbitmqctl command [force_boot]
        [Parameter(Mandatory=$false)]
        [switch] $Force
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

        if($Force) {
            Write-Verbose "Adding command for force boot."
            $rabbitBootParams = $rabbitControlParams + "force_boot"
            Write-Verbose "Executing command: $rabbitControlPath $rabbitBootParams"
            Start-Process -ArgumentList $rabbitBootParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
        }

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
    #This command instructs RabbitMQ to ensure the user named tonyg is an administrator on the node rabbit@HOSTNAME, has management plugin rights, and suppressed informational messages. This has no effect when the user logs in via AMQP, but can be used to permit the user to manage users, virtual hosts and permissions when the user logs in via some other means (for example with the management plugin).
        Set-RabbitMqUserTags -Node "rabbit@HOSTNAME" -Username tonyg -Tag administrator,management -Quiet

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

        [Parameter(Mandatory=$false)]
        [string] $Tag
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

        if ($Tag) {
            Write-Verbose "Adding tag parameter."
            $parsedTag = $Tag -split ","
            $rabbitControlParams = $rabbitControlParams + $parsedTag
        }

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
        Write-Verbose "End: Stop-RabbitMq"
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

Function Get-RabbitMqQueues {
<#
.SYNOPSIS
    Lists the RabbitMq queues present on a host, as well as metadata about the current queue state.

.DESCRIPTION
    This command returns requested metadata for each queue on the specified RabbitMQ node.
        -Available metadata includes: name (queue name), durable (does queue persist through restart), auto_delete (delete when unused), arguments, policy, pid, owner_pid, exclusive, exclusive_consumer_pid, exclusive_consumer_tag, messages_ready, messages_unacknowledged, messages, messages_ready_ram, messages_unacknowledged_ram, messages_ram, messages_persistent, message_bytes, message_bytes_ready, message_bytes_unacknowledged, message_bytes_ram, message_bytes_persistent, head_message_timestamp, disk_reads, disk_writes, consumers, consumer_utilisation, memory, slave_pids, synchronised_slave_pids, state
        

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    The name of the virtual host to query.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.PARAMETER InfoItems
    List of metadata items to be returned regarding the queue.  Default is name,

.EXAMPLE
    Get-RabbitMqQueues -InfoItems name,messages,head_message_timestamp

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
        [string] $VHost,

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
        Write-Verbose "Begin: Get-RabbitMqQueues"
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

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        $stdOut = Get-StdOut -filename $rabbitControlPath -arguments $rabbitControlParams -Timeout $Timeout
        return $stdOut
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqQueues"
    }
}

Function Get-RabbitMqPermissionsByUser {
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
    Get-RabbitMqPermissionsByUser admin

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
        Write-Verbose "Begin: Get-RabbitMqPermissionsByUser"
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
        Write-Verbose "End: Get-RabbitMqPermissionsByUser"
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
    Get-RabbitMqBindings -VHost local_rabbitmq -InfoItems source_name,destination_name

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

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "list_bindings $InfoItems"
        if($VHost){
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

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

        # rabbitmqctl parameter [channelinfoitem]
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
    Get-RabbitMqConnections -VHost local_rabbitmq -InfoItems name,user,confirm

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

        # rabbitmqctl parameter [connectioninfoitem]
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

Function Get-RabbitMqExchanges {
<#
.SYNOPSIS
    Lists the RabbitMq exchanges (message routers) for a vhost.

.DESCRIPTION
    Returns exchange details and metadata. By default the connections for the "/" virtual host are returned. The "-VHost" flag can be used to override this default.
        -Available metadata includes: name (readable name), type (i.e. "fanout" or "topic"), durable (survives restart Y/N), auto_delete (deleted when empty after initial fill), internal (cannot be direct publish target), arguments (to customize behavior), policy (policy name applied)
        -Default metadata is exchange name and type.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root vhost.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command displays the name of the exchange, it's current policy, and arguments available for that exchange.
    Get-RabbitMqExchanges -VHost local_rabbitmq -InfoItems name,arguments,policy

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

        # rabbitmqctl parameter [exchangeinfoitem]
        [Parameter(Mandatory=$false)]
        [ValidateSet("name", "type", "durable", "auto_delete", "internal", "arguments", "policy")]
        [String[]] $InfoItems
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqExchanges"
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
        $rabbitControlParams = $rabbitControlParams + "list_exchanges $InfoItems"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqExchanges"
    }
}

Function Get-RabbitMqConsumers {
<#
.SYNOPSIS
    Lists the RabbitMq consumers (message receivers / subscribers) for a vhost.

.DESCRIPTION
    List consumers, i.e. subscriptions to a queue's message stream. By default all consumers of queues for the "/" virtual host are returned. The "-VHost" flag can be used to override this default.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).
    Each line shows the name of the queue subscribed to, the id of the channel process via which the subscription was created and is managed, the consumer tag which uniquely identifies the subscription within a channel, a boolean indicating whether acknowledgements are expected for messages delivered to this consumer, an integer indicating the prefetch limit (with 0 meaning 'none'), and any arguments for this consumer. 

.PARAMETER VHost
    Default host is "/", the root vhost.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command displays the list of queues and associated consumers for the virtual host named local_rabbitmq on the node rabbit@HOSTNAME.
    Get-RabbitMqConsumers -VHost local_rabbitmq -Node rabbit@HOSTNAME

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

        # rabbitmqctl parameter [exchangeinfoitem]
        [Parameter(Mandatory=$false)]
        [ValidateSet("name", "type", "durable", "auto_delete", "internal", "arguments", "policy")]
        [String[]] $InfoItems
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqConsumers"
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
        $rabbitControlParams = $rabbitControlParams + "list_consumers $InfoItems"
        if($VHost){
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqConsumers"
    }
}

Function Get-RabbitMqPermissionsByVHost {
<#
.SYNOPSIS
    For a given virtual host, lists the RabbitMq users and the permissions granted to that user on the vhost.

.DESCRIPTION
    This command returns a list of permissions by user for a given vhost.
        
.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root vhost.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Timeout
    Operation timeout in seconds.

.EXAMPLE
    #This command instructs the RabbitMQ broker to list all the users and their permissions the virtual host local_rabbitmq on the node rabbit@HOSTNAME. 
    Get-RabbitMqPermissionsByVHost -Node rabbit@HOSTNAME -VHost local_rabbitmq

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
        [int] $Timeout
    )

    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqPermissionsByVHost"
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
        $rabbitControlParams = $rabbitControlParams + "list_permissions"
        if($VHost){
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqPermissionsByVHost"
    }
}

Function Set-RabbitMqParameter {
<#
.SYNOPSIS
    Add a value for a specific cluster-wide parameter for the specified vhost.

.DESCRIPTION
    This command instructs RabbitMQ to set the value of a parameter on the cluster / vhost. In general, you should refer to the documentation for the feature in question (i.e. federation) to see how to set and clear parameters.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Component
    The name of the component the parameter applies to.

.PARAMETER ParamName
    The name of the parameter whose value should be set.

.PARAMETER ParamValue
    The new value of the parameter whose value should be set.

.EXAMPLE
    #This command instructs RabbitMQ to set the service account name used for federation to the value "admin" at VHost local_rabbitmq, sending the command via Node rabbit@HOSTNAME.
        Set-RabbitMqParameter -Node "rabbit@HOSTNAME" -VHost local_rabbitmq -ParamName local_username -ParamValue admin -Component federation

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

        [Parameter(Mandatory=$true)]
        [string] $Component,

        [Parameter(Mandatory=$true)]
        [string] $ParamName,

        [Parameter(Mandatory=$true)]
        [string] $ParamValue
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqParameter"
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
        $rabbitControlParams = $rabbitControlParams + "set_parameter"

        Write-Verbose "Adding component parameter."
        $rabbitControlParams = $rabbitControlParams + $Component
        
        Write-Verbose "Adding parameter name parameter."
        $rabbitControlParams = $rabbitControlParams + $ParamName

        Write-Verbose "Adding parameter value parameter."
        $rabbitControlParams = $rabbitControlParams + $ParamValue

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqParameter"
    }
}

Function Get-RabbitMqParameters {
<#
.SYNOPSIS
    List cluster-wide parameters for the specified vhost.

.DESCRIPTION
    This command instructs RabbitMQ to set list the names and values of all parameters on the cluster / vhost. In general, you should refer to the documentation for the feature in question (i.e. federation) to see how to set and clear parameters.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Component
    The name of the component the parameter applies to.

.EXAMPLE
    #This command instructs RabbitMQ to list all parameters and their values at VHost local_rabbitmq, sending the command via Node rabbit@HOSTNAME.
        Get-RabbitMqParameters -Node "rabbit@HOSTNAME" -VHost local_rabbitmq

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
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqParameter"
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
        $rabbitControlParams = $rabbitControlParams + "list_parameters"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqParameter"
    }
}

Function Remove-RabbitMqConnection {
<#
.SYNOPSIS
    Close a connection which is listening to a queue.

.DESCRIPTION
    This command instructs RabbitMQ to disconnect a listener (connection) from a queue.  A message is sent to the connected client explaining the disconnection.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER ConnectionPid
    The process ID of the connection to remove.

.PARAMETER Reason
    Explanation sent to the connected client.

.EXAMPLE
    #This command instructs RabbitMQ to close connection with ID 282, and send the message "scheduled maintenance until 8:00pm" to the listening client.
        Remove-RabbitMqConnection -ConnectionPid 282 -Reason "scheduled maintenance until 8:00pm"

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

        # rabbitmqctl parameter [connectionpid]
        [Parameter(Mandatory=$true)]
        [switch] $ConnectionPid,

        # rabbitmqctl parameter [explanation]
        [Parameter(Mandatory=$false)]
        [switch] $Reason="session disconnected by host"
    )
    
    Begin
    {
        Write-Verbose "Begin: Remove-RabbitMqConnection"
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
        $rabbitControlParams = $rabbitControlParams + "close_connection"
        
        Write-Verbose "Adding connection PID parameter."
        $rabbitControlParams = $rabbitControlParams + $ConnectionPid 

        Write-Verbose "Adding reason parameter."
        $rabbitControlParams = $rabbitControlParams + $Reason

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Remove-RabbitMqConnection"
    }
}

Function Get-RabbitMqEnvironment {
<#
.SYNOPSIS
    Display the name and value of each variable in the application environment for each running application.

.DESCRIPTION
    This command displays the name and value of each variable in the environment, for each running application.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #List environment variables on the current node, suppressing informational messages.
        Get-RabbitMqEnvironment -Quiet

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
        Write-Verbose "Begin: Get-RabbitMqEnvironment"
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
        $rabbitControlParams = $rabbitControlParams + "environment"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqEnvironment"
    }
}

Function Get-RabbitMqHealth {
<#
.SYNOPSIS
    Perform a health check on the rabbit node

.DESCRIPTION
    This command displays "Health check passed" if the application is running, list_queues and list_channels return, and no alarms are set / triggered. 

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Prints "Health check passed" if application is running, list_queues and list_channels return, and alarms are not set. 
        Get-RabbitMqHealth -Quiet

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
        Write-Verbose "Begin: Get-RabbitMqHealth"
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
        $rabbitControlParams = $rabbitControlParams + "node_health_check"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqHealth"
    }
}

Function Get-RabbitMqHealth {
<#
.SYNOPSIS
    Perform a health check on the rabbit node

.DESCRIPTION
    This command displays "Health check passed" if the application is running, list_queues and list_channels return, and no alarms are set / triggered. 

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Prints "Health check passed" if application is running, list_queues and list_channels return, and alarms are not set. 
        Get-RabbitMqHealth -Quiet

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
        Write-Verbose "Begin: Get-RabbitMqHealth"
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
        $rabbitControlParams = $rabbitControlParams + "node_health_check"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqHealth"
    }
}

Function Invoke-RabbitMqEncoder {
<#
.SYNOPSIS
    Encrypts the input value using the facilities available on the RabbitMQ node

.DESCRIPTION
    This command converts an un-encrypted string into its encrypted equivalent, using the passphase and encryption types defined by the parameters. 

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER EncryptedText
    The text to be encoded / encrypted.

.PARAMETER Passphrase
    The key phrase which will be supplied in order to decrypt the data.

.PARAMETER Cipher
    The cipher which will be supplied in order to decrypt the data.

.PARAMETER Hash
    The hash which will be supplied in order to decrypt the data.

.PARAMETER Iterations
    The number of encryption passes which will be applied to the data (must be supplied in order to decrypt the data).

.EXAMPLE
    #Returns the encrypted text encoded using parameters provided 
        Invoke-RabbitMqEncoder -Text "quick brown fox" -Passphrase "lazy dog" -Cipher blowfish_cfb64 -Hash sha256 -Iterations 14

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [value]
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Text,

        # rabbitmqctl parameter [passphrase]
        [Parameter(Mandatory=$true,Position=2)]
        [String] $Passphrase,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [--cipher cipher]
        [Parameter(Mandatory=$false)]
        [String] $Cipher=$null,

        # rabbitmqctl parameter [--hash hash]
        [Parameter(Mandatory=$false)]
        [String] $Hash=$null,

        # rabbitmqctl parameter [--iterations iterations]
        [Parameter(Mandatory=$false)]
        [int] $Iterations=$null
    )
    
    Begin
    {
        Write-Verbose "Begin: Invoke-RabbitMqEncoder"
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
        $rabbitControlParams = $rabbitControlParams + "encode"
        $rabbitControlParams = $rabbitControlParams + "$Text"
        $rabbitControlParams = $rabbitControlParams + "$Passphrase"

        if ($Hash)
        {
            Write-Verbose "Adding hash parameter."
            $rabbitControlParams = $rabbitControlParams + "--hash $Hash"
        }
        if ($Cipher)
        {
            Write-Verbose "Adding cipher parameter."
            $rabbitControlParams = $rabbitControlParams + "--cipher $Cipher"
        }
        if ($Iterations -gt 0)
        {
            Write-Verbose "Adding iterations parameter."
            $rabbitControlParams = $rabbitControlParams + "--iterations $Iterations"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Invoke-RabbitMqEncoder"
    }
}

Function Get-RabbitMqEncoderOptions {
<#
.SYNOPSIS
    Returns available options for use in the Invoke-RabbitMqEncoder command

.DESCRIPTION
    Lists encoding types (ciphers, hashes, etc) available for the Invoke-RabbitMqEncoder command.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Ciphers
    List available ciphers (i.e. "blowfish_cfb64") available.

.PARAMETER Hashes
    List available hashes (i.e. "SHA256") available.

.EXAMPLE
    #Lists the available ciphers and hashes for encrypting data on the node
        Get-RabbitMqEncoderOptions -Hashes -Ciphers

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

        # rabbitmqctl parameter [-- list-ciphers]
        [Parameter(Mandatory=$false)]
        [switch] $Ciphers,

        # rabbitmqctl parameter [-- list-hashes]
        [Parameter(Mandatory=$false)]
        [switch] $Hashes
    )
    
    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqEncoderOptions"
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

        if($Ciphers -eq $false -and $Hashes -eq $false){
            $Ciphers = $true
            $Hashes = $true
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "encode"
        if($Ciphers) {
            $rabbitControlParams = $rabbitControlParams + "--list-ciphers"
        }
        if($Hashes) {
            $rabbitControlParams = $rabbitControlParams + "--list-hashes"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqEncoderOptions"
    }
}

Function Invoke-RabbitMqDecoder {
<#
.SYNOPSIS
    Decrypts the input value using the facilities available on the RabbitMQ node

.DESCRIPTION
    This command converts an encrypted string into its human-readable equivalent, using the passphase and encryption types defined during the initial encryption. 

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER EncryptedText
    The text to be decoded / decrypted.

.PARAMETER Passphrase
    The key phrase used during the original encryption of the data.

.PARAMETER Cipher
    The cipher used during the original encryption of the data.

.PARAMETER Hash
    The hash used during the original encryption of the data.

.PARAMETER Iterations
    The number of encryption passes used during the original encryption of the data.

.EXAMPLE
    #Returns the original text encoded using the Invoke-RabbitMqEncoder command (with the same parameters provided below)
        Invoke-RabbitMqDecoder -EncryptedText "" -Passphrase "lazy dog" -Cipher blowfish_cfb64 -Hash sha256 -Iterations 14

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [value]
        [Parameter(Mandatory=$true, Position=1)]
        [String] $EncryptedText,

        # rabbitmqctl parameter [passphrase]
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Passphrase,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [--cipher cipher]
        [Parameter(Mandatory=$false)]
        [String] $Cipher=$null,

        # rabbitmqctl parameter [--hash hash]
        [Parameter(Mandatory=$false)]
        [String] $Hash=$null,

        # rabbitmqctl parameter [--iterations iterations]
        [Parameter(Mandatory=$false)]
        [int] $Iterations=$null
    )
    
    Begin
    {
        Write-Verbose "Begin: Invoke-RabbitMqDecoder"
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
        $rabbitControlParams = $rabbitControlParams + "encode --decode"
        $rabbitControlParams = $rabbitControlParams + "$EncodedText"
        $rabbitControlParams = $rabbitControlParams + "$Passphrase"

        if ($Hash)
        {
            Write-Verbose "Adding hash parameter."
            $rabbitControlParams = $rabbitControlParams + "--hash $Hash"
        }
        if ($Cipher)
        {
            Write-Verbose "Adding cipher parameter."
            $rabbitControlParams = $rabbitControlParams + "--cipher $Cipher"
        }
        if ($Iterations -gt 0)
        {
            Write-Verbose "Adding iterations parameter."
            $rabbitControlParams = $rabbitControlParams + "--iterations $Iterations"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Invoke-RabbitMqDecoder"
    }
}

Function Get-RabbitMqEncoderOptions {
<#
.SYNOPSIS
    Returns available options for use in the Invoke-RabbitMqEncoder command

.DESCRIPTION
    Lists encoding types (ciphers, hashes, etc) available for the Invoke-RabbitMqEncoder command.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Ciphers
    List available ciphers (i.e. "blowfish_cfb64") available.

.PARAMETER Hashes
    List available hashes (i.e. "SHA256") available.

.EXAMPLE
    #Lists the available ciphers and hashes for encrypting data on the node
        Get-RabbitMqEncoderOptions -Hashes -Ciphers

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

        # rabbitmqctl parameter [-- list-ciphers]
        [Parameter(Mandatory=$false)]
        [switch] $Ciphers,

        # rabbitmqctl parameter [-- list-hashes]
        [Parameter(Mandatory=$false)]
        [switch] $Hashes
    )
    
    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqEncoderOptions"
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

        if($Ciphers -eq $false -and $Hashes -eq $false){
            $Ciphers = $true
            $Hashes = $true
        }

        [string[]] $rabbitControlParams = Build-RabbitMq-Params -Node $Node -Quiet $Quiet

        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "encode"
        if($Ciphers) {
            $rabbitControlParams = $rabbitControlParams + "--list-ciphers"
        }
        if($Hashes) {
            $rabbitControlParams = $rabbitControlParams + "--list-hashes"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqEncoderOptions"
    }
}

Function Set-RabbitMqCluster {
<#
.SYNOPSIS
    Adds the current (or specified) RabbitMQ node to a node cluster

.DESCRIPTION
    Instruct the node to become a member of the cluster the node is in. Before clustering, the node is reset, so be careful when using this command. For this command to succeed the RabbitMQ application must have been stopped, e.g. with Stop-RabbitMq.
    Note: to remove a node from a cluster, use Stop-RabbitMq followed by Reset-RabbitMq

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Cluster
    Required.  Indicates the cluster (node) to join.

.PARAMETER Ram
    Indicates that the node should be in-memory only, and should not replicate data on disc.  RAM nodes are primarily used for scalability.  A cluster must always have at least one disc node (non-RAM), and usually should have more than one. 

.EXAMPLE
    #Instructs the local rabbit@LOCALHOST node to cluster with the node at rabbit@REMOTEHOST1, replicating only in-memory data
        Set-RabbitMqCluster rabbit@REMOTEHOST1 -Node rabbit@LOCALHOST -Ram

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [clusternode]
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Cluster,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [--ram]
        [Parameter(Mandatory=$false)]
        [switch] $Ram
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqCluster"
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
        $rabbitControlParams = $rabbitControlParams + "join_cluster"
        $rabbitControlParams = $rabbitControlParams + $Cluster

        if ($Ram)
        {
            Write-Verbose "Adding ram parameter."
            $rabbitControlParams = $rabbitControlParams + "--ram"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqCluster"
    }
}

Function Set-RabbitMqPolicy {
<#
.SYNOPSIS
    Sets the policy for the cluster which contains the specified node

.DESCRIPTION
    Sets a cluster-wide policy, exactly one of which will match each exchange or queue.  This allows various features to be controlled on a cluster-wide basis at runtime or queue / exchange startup.
    Policies can be used to configure the federation plugin, mirrored queues, alternate exchanges, dead lettering, per-queue TTLs, and maximum queue length. 
    Note: to apply policies for multiple features, modify the shared policy definition.  Only one policy will apply to a given queue or exchange, but that policy may apply definitions related to multiple features.

.PARAMETER Name
    Required. Readable policy name.

.PARAMETER Pattern
    Required. Regular expression used for matching component name.  Policy will be applied only to components with a matching name.

.PARAMETER Json
    Required. JSON definition of the policy values, escaped according to enviornment (Windows vs Unix).

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Priority
    Precedence of the policy in determining which policy to apply to a node.  Default is 0, higher numbers indicate greater priority.

.PARAMETER ApplyTo
    Defines the type of objects the policy applies to.  Options are "queues", "exchanges", or "all".  Default is "all".

.EXAMPLE
    #On a windows machine, defines a policy named "failover" which causes queues whose name ends with "-backup" to be federated, with all other queues considered upstream from the federated queue
        Set-RabbitMqPolicy failover "^.*-backup$" '"{""federation-upstream-set"":""all""}"' -ApplyTo queues

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [name]
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Name,

        # rabbitmqctl parameter [pattern]
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Pattern,

        # rabbitmqctl parameter [definition]
        [Parameter(Mandatory=$true, Position=3)]
        [String] $Json,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [--priority priority]
        [Parameter(Mandatory=$false)]
        [int] $Priority,

        # rabbitmqctl parameter [--apply-to apply-to]
        [Parameter(Mandatory=$false)]
        [ValidateSet("exchanges", "queues", "all")]
        [string] $ApplyTo
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqPolicy"
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
        $rabbitControlParams = $rabbitControlParams + "set_policy"
        $rabbitControlParams = $rabbitControlParams + $Name
        $rabbitControlParams = $rabbitControlParams + $Pattern
        $rabbitControlParams = $rabbitControlParams + $Json

        if ($Priority -gt 0)
        {
            Write-Verbose "Adding priority parameter."
            $rabbitControlParams = $rabbitControlParams + "--priority $Priority"
        }

        if ($ApplyTo)
        {
            Write-Verbose "Adding apply to parameter."
            $rabbitControlParams = $rabbitControlParams + "--apply-to $ApplyTo"
        }

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqPolicy"
    }
}

Function Clear-RabbitMqPolicy {
<#
.SYNOPSIS
    Removes the named policy from the cluster which contains the specified node

.DESCRIPTION
    Removes a cluster-wide policy, by name.  This allows various features to be controlled on a cluster-wide basis at runtime or queue / exchange startup.
    Policies can be used to configure the federation plugin, mirrored queues, alternate exchanges, dead lettering, per-queue TTLs, and maximum queue length. 

.PARAMETER Name
    Required. Readable policy name.  Should be unique per policy.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Removes the policy named "failover" from the cluster that contains vhost local_rabbitmq
        Clear-RabbitMqPolicy failover -VHost local_rabbitmq

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [name]
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Name,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Clear-RabbitMqPolicy"
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
        $rabbitControlParams = $rabbitControlParams + "clear_policy"
        $rabbitControlParams = $rabbitControlParams + $Name

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Clear-RabbitMqPolicy"
    }
}

Function Get-RabbitMqPolicies {
<#
.SYNOPSIS
    Lists all policies applied to the cluster which contains the specified node

.DESCRIPTION
    Lists the policies which have been defined on a cluster, 
    Policies can be used to configure the federation plugin, mirrored queues, alternate exchanges, dead lettering, per-queue TTLs, and maximum queue length. 

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #List the policies which have been successfully applied to any exchange or queue on the vhost local_rabbitmq
        Get-RabbitMqPolicies -VHost local_rabbitmq

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
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Get-RabbitMqPolicies"
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
        $rabbitControlParams = $rabbitControlParams + "list_policies"
        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqPolicies"
    }
}

Function Set-RabbitMqUserPermissions {
<#
.SYNOPSIS
    Adds access permissions to a user

.DESCRIPTION
    This command instructs RabbitMQ to add permissions a specified user which allow them to configure, write, or read resources matching a given pattern set.

.PARAMETER Username
    Required.  Username of the user whose permissions are being defined.

.PARAMETER ConfigPattern
    Regular expression which matches resource names which the user should be allowed to configure.  Defaults to no permissions, and overwrites any existing permissions.

.PARAMETER WritePattern
    Regular expression which matches resource names which the user should be allowed to write.  Defaults to no permissions, and overwrites any existing permissions.

.PARAMETER ReadPattern
    Regular expression which matches resource names which the user should be allowed to read.  Defaults to no permissions, and overwrites any existing permissions.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below allows user "guest" to read all resources, but disallows write and configure permissions.
        Set-RabbitMqUserPermissions -Username guest -ConfigPattern "^$" -WritePattern "^$" -ReadPattern ".*"

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Username,

        [Parameter(Mandatory=$false, Position=2)]
        [string] $ConfigPattern="^$",

        [Parameter(Mandatory=$false, Position=3)]
        [string] $WritePattern="^$",

        [Parameter(Mandatory=$false, Position=4)]
        [string] $ReadPattern="^$",

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqUserPermissions"
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
        $rabbitControlParams = $rabbitControlParams + "set_permissions"
        $rabbitControlParams = $rabbitControlParams + $Username
        $rabbitControlParams = $rabbitControlParams + $ConfigPattern
        $rabbitControlParams = $rabbitControlParams + $WritePattern
        $rabbitControlParams = $rabbitControlParams + $ReadPattern

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqUserPermissions"
    }
}

Function Clear-RabbitMqUserPermissions {
<#
.SYNOPSIS
    Deletes access permissions from a user

.DESCRIPTION
    This command instructs RabbitMQ to remove ALL permissions from a specified user, including configure, write, and read permissions.  It is scoped to a specific virtual host.

.PARAMETER Username
    Required.  Username of the user whose permissions are being defined.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below removes ALL permissions for user "guest" on VHost local_rabbitmq.  Other hosts are not impacted.
        Clear-RabbitMqUserPermissions -Username guest -VHost local_rabbitmq

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Username,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Clear-RabbitMqUserPermissions"
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
        $rabbitControlParams = $rabbitControlParams + "clear_permissions"
        $rabbitControlParams = $rabbitControlParams + $Username

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Clear-RabbitMqUserPermissions"
    }
}

Function Get-RabbitMqClusterStatus {
<#
.SYNOPSIS
    List nodes in the cluster

.DESCRIPTION
    This command instructs RabbitMQ to list all nodes in the cluster grouped by node type, together with the currently running nodes.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below lists clusters on the "rabbit@LOCALHOST" node
        Get-RabbitMqClusterStatus -Node rabbit@LOCALHOST

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
        Write-Verbose "Begin: Get-RabbitMqClusterStatus"
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
        $rabbitControlParams = $rabbitControlParams + "cluster_status"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqClusterStatus"
    }
}

Function Set-RabbitMqTrace {
<#
.SYNOPSIS
    Turn on message tracing on a vhost.

.DESCRIPTION
    This command instructs RabbitMQ to enable firehose tracing, which provides meta-information about all messages sent across the specified virtual host.  This metadata is published as separate message on the topic exchange "amq.rabbitmq.trace".
    -   The routing key for these messages will be either "publish.exchangename" for messages entering the broker, or "deliver.queuename" for messages leaving the broker.
    -   Metadata provided in these messages includes: exchange_name (exchange published to), routing_keys (routing plus CC/BCC info), properties (message properties), node (node where trace message was generated), redelivered (message redelivered flag set Y/N).
    -   See https://www.rabbitmq.com/amqp-0-9-1-reference.html#class.basic for more info on message properties.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below turns on message tracing on the "local_rabbitmq" host of the rabbit@LOCALHOST" node, with no info messages
        Set-RabbitMqTrace -VHost local_rabbitmq -Node rabbit@LOCALHOST -Quiet

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
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqTrace"
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
        $rabbitControlParams = $rabbitControlParams + "trace_on"

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqTrace"
    }
}

Function Clear-RabbitMqTrace {
<#
.SYNOPSIS
    Turn off message tracing on a vhost.

.DESCRIPTION
    This command instructs RabbitMQ to disable firehose tracing.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below turns off message tracing on the "local_rabbitmq" host of the rabbit@LOCALHOST" node, with no info messages
        Clear-RabbitMqTrace -VHost local_rabbitmq -Node rabbit@LOCALHOST -Quiet

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
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Clear-RabbitMqTrace"
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
        $rabbitControlParams = $rabbitControlParams + "trace_off"

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Clear-RabbitMqTrace"
    }
}

Function Invoke-RabbitMqLogSwap {
<#
.SYNOPSIS
    Start a new log set after archiving existing logs.

.DESCRIPTION
    This command instructs RabbitMQ to archive the current logs (with a user-specified suffix), and start new log files in the default location.  If a file exists matching the provided suffix, the contents are appended to the end of that file, otherwise the new file is created.  If no archive is desired, specify the -Delete flag.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Suffix
    The suffix to append to the archived log files.  Default is today's date and time in sortable format.

.PARAMETER Delete
    Flag to indicate that no archives should be created.

.EXAMPLE
    #The command below archives the current logs for node rabbit@LOCALHOST, and starts new logs. Archived file names will end in ".bak.1"
        Invoke-RabbitMqLogSwap -Suffix .bak.1 -Node rabbit@LOCALHOST

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

        # rabbitmqctl parameter [suffix]
        [Parameter(Mandatory=$false)]
        [string] $Suffix,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [switch] $Delete
    )
    
    Begin
    {
        Write-Verbose "Begin: Invoke-RabbitMqLogSwap"
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
        $rabbitControlParams = $rabbitControlParams + "rotate_logs"
        if($Delete -ne $true){
            if($Suffix) {
                Write-Verbose "Adding suffix parameter."
                $rabbitControlParams = $rabbitControlParams + $Suffix
            } else {
                Write-Error "Suffix parameter is required if Delete flag is not specified."
            }
        } else {
            Write-Verbose "Delete specified - no log archives created."
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Invoke-RabbitMqLogSwap"
    }
}

Function Get-RabbitMqBrokerStatus {
<#
.SYNOPSIS
    List broker status information

.DESCRIPTION
    This command instructs RabbitMQ to list broker status, such as applications running on the Erlang node, RabbitMQ and Erlang versions, OS name, memory and file descriptor statistics.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below lists clusters on the "rabbit@LOCALHOST" node
        Get-RabbitMqBrokerStatus -Node rabbit@LOCALHOST

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
        Write-Verbose "Begin: Get-RabbitMqBrokerStatus"
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
        $rabbitControlParams = $rabbitControlParams + "status"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqBrokerStatus"
    }
}

Function Set-RabbitMqFlowControl {
<#
.SYNOPSIS
    Sets the memory usage level where flow control is triggered

.DESCRIPTION
    This command instructs RabbitMQ to turn on flow control (pausing incoming messages several times per second to allow the queues and message processing to keep up with incoming message rate).  A flow-controlled connection will show a state of "flow" in Get-RabbitMqConnections.

.PARAMETER Limit
    Required.  The max memory usage before flow control is triggered.  By default, provided as a decimal number between 0 and 1 (i.e. 0.75 = 75% of available memory).  Alternately, when the -Absolute flag is provided, can be a specific number of bytes (i.e. 2048000) or a string with memory units (i.e. 2MB).

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Absolute
    Indicates that the Limit parameter provides a fixed memory amount.

.EXAMPLE
    #This command triggers flow control mode when the node "rabbit@LOCALHOST" exceeds 90% of memory utilization
        Set-RabbitMqFlowControl 0.9 -Node rabbit@LOCALHOST

.EXAMPLE
    #The command below triggers flow control mode when the default node exceeds 3GB of memory utilization
        Set-RabbitMqFlowControl 3GB -Absolute

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Limit,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [absolute]
        [Parameter(Mandatory=$false)]
        [switch] $Absolute
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqFlowControl"
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

        if($Absolute -ne $true){
            if($Limit -lt 0 -or $Limit -gt 1) {
                Write-Error "Limit parameter must be a decimal between 0 and 1 when -Absolute flag is not specified."
                return
            }
        }


        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "set_vm_memory_high_watermark"
        if($Absolute){
            Write-Verbose "Adding absolute flag."
            $rabbitControlParams = $rabbitControlParams + "absolute"
        }
        $rabbitControlParams = $rabbitControlParams + $Limit

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqFlowControl"
    }
}

Function Clear-RabbitMqQueue {
<#
.SYNOPSIS
    Clear all messages from a queue

.DESCRIPTION
    This command instructs RabbitMQ to delete all messages from a queue, specified by name

.PARAMETER Queue
    Required.  The readable name of the queue to clear.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below clears all messages from the queue named "myqueue" on the "rabbit@LOCALHOST" node
        Clear-RabbitMqQueue myqueue -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Queue,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Clear-RabbitMqQueue"
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
        $rabbitControlParams = $rabbitControlParams + "purge_queue $Queue"

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Clear-RabbitMqQueue"
    }
}

Function Get-RabbitMqReport {
<#
.SYNOPSIS
    Server status report

.DESCRIPTION
    This command instructs RabbitMQ to print a server status report containing a concatenation of all server status information for support purposes.  Output should be redirected to a file to be attached to a support ticket.  Includes the output of Get-RabbitMqClusterStatus, Get-RabbitMqBrokerStatus, Get-RabbitMqQueues, Get-RabbitMqEnvironment, etc.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #The command below prints a concatenated string containing detailed system state information on the "rabbit@LOCALHOST" node
        Get-RabbitMqReport -Node rabbit@LOCALHOST

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
        Write-Verbose "Begin: Get-RabbitMqReport"
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
        $rabbitControlParams = $rabbitControlParams + "report"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Get-RabbitMqReport"
    }
}

Function Remove-RabbitMqNodeFromCluster {
<#
.SYNOPSIS
    Remove a node from the cluster

.DESCRIPTION
    This command instructs the controlling RabbitMQ node of a cluster to that another node will no longer participate in that cluster. The removed node must be offline. The controlling node must be online, unless the -ForceWhileOffline flag is specified.

.PARAMETER Forget
    Required. The node which is being removed from the cluster.

.PARAMETER Node
    A node in the cluster from which the -Forget node is being removed. Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER ForceWhileOffline
    Forces the node to take control of an offline cluster in order to remove the specified node.  This may be destructive, as the recipient node becomes the system of record for cluster metadata, which may cause changes which occurred after the node was stopped to be lost.

.EXAMPLE
    #The command below removes the node "rabbit@ANOTHERHOST" from the cluster which includes "rabbit@LOCALHOST".
        Remove-RabbitMqNodeFromCluster -Node rabbit@LOCALHOST -Forget rabbit@ANOTHERHOST

.EXAMPLE
    #This command removes the node "rabbit@ANOTHERHOST" from the cluster which includes "rabbit@LOCALHOST", using abbreviated syntax
        Remove-RabbitMqNodeFromCluster rabbit@ANOTHERHOST

.EXAMPLE
    #This command removes the node "rabbit@ANOTHERHOST", regardless of the offline status of the cluster
        Remove-RabbitMqNodeFromCluster rabbit@ANOTHERHOST -ForceWhileOffline

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Forget,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [--offline]
        [Parameter(Mandatory=$false)]
        [switch] $ForceWhileOffline
    )
    
    Begin
    {
        Write-Verbose "Begin: Remove-RabbitMqNodeFromCluster"
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
        $rabbitControlParams = $rabbitControlParams + "forget_cluster_node $Forget"

        if($ForceWhileOffline){
            Write-Verbose "Adding offline parameter."
            $rabbitControlParams = $rabbitControlParams + "--offline"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Remove-RabbitMqNodeFromCluster"
    }
}

Function Set-RabbitMqDiskFree {
<#
.SYNOPSIS
    Sets the disk usage level where a low space alarm is triggered

.DESCRIPTION
    This command instructs RabbitMQ to turn on a disk usage alarm when remaining / available disk space falls below the specified threshold.

.PARAMETER Limit
    Required.  The minimum disk space remaining before an alarm is triggered.  By default, provided as a decimal multiple of installed RAM (i.e. 2.5 = 10GB disk space when 4GB RAM is installed).  Alternately, when the -Absolute flag is provided, can be a specific number of bytes (i.e. 2048000) or a string with memory units (i.e. 350MB).

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Absolute
    Indicates that the Limit parameter provides a fixed disk space amount.

.EXAMPLE
    #This command triggersan alarm when the node "rabbit@LOCALHOST" has less than 15% of disk space free
        Set-RabbitMqDiskFree 0.15 -Node rabbit@LOCALHOST

.EXAMPLE
    #The command below triggers an alarm when the default node has less than 1GB of disk space free
        Set-RabbitMqDiskFree 1GB -Absolute

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Limit,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet,

        # rabbitmqctl parameter [absolute]
        [Parameter(Mandatory=$false)]
        [switch] $Absolute
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqFlowControl"
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

        if($Absolute -ne $true){
            if($Limit -lt 1) {
                Write-Error "Warning: relative memory values until 1.0 can be dangerous, as system may have insufficient space to persist in-memory data."
            }
        }


        Write-Verbose "Adding command parameter."
        $rabbitControlParams = $rabbitControlParams + "set_disk_free_limit"
        if($Absolute -ne $true){
            Write-Verbose "Adding relative flag."
            $rabbitControlParams = $rabbitControlParams + "mem_relative"
        }
        $rabbitControlParams = $rabbitControlParams + $Limit

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqDiskFree"
    }
}

Function Set-RabbitMqClusterName {
<#
.SYNOPSIS
    Sets the readable name of a cluster

.DESCRIPTION
    This command instructs RabbitMQ to change the name of a cluster to the specified value.

.PARAMETER Name
    Required.  The new, human-readable name for the cluster.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #This command changes the name of the cluster of which rabbit@LOCALHOST is a member to "recovery"
        Set-RabbitMqClusterName recovery -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Name,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqClusterName"
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
        $rabbitControlParams = $rabbitControlParams + "set_cluster_name $Name"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqClusterName"
    }
}

Function Set-RabbitMqClusterNodeType {
<#
.SYNOPSIS
    Sets the type of a cluster node

.DESCRIPTION
    This command instructs RabbitMQ to change the node type (i.e. RAM or DISC) of a node in a cluster to the specified value.  Note that the node must be stopped (i.e. with Stop-RabbitMq) prior to running this command.

.PARAMETER Type
    Required.  Allowed values are "disc" or "RAM".

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #This command changes the node rabbit@LOCALHOST from a RAM node to a DISC node on its current cluster
        Set-RabbitMqClusterNodeType disc -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet("disc", "ram")]
        [string] $Type,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Set-RabbitMqClusterNodeType"
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
        $rabbitControlParams = $rabbitControlParams + "change_cluster_node_type $Type"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Set-RabbitMqClusterNodeType"
    }
}

Function Stop-RabbitMqMirroringSync {
<#
.SYNOPSIS
    Stops trying to synch versions of a mirrored queue

.DESCRIPTION
    This command instructs RabbitMQ to stop synchronizing a mirrored queue, by name.

.PARAMETER Queue
    Required.  Name of the queue to remove from synchronization on the node, and being processing messages normally.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #This command stops "myqueue" from the list of queues being mirrored on rabbit@LOCALHOST
        Stop-RabbitMqMirroringSync myqueue -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Queue,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Stop-RabbitMqMirroringSync"
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
        $rabbitControlParams = $rabbitControlParams + "cancel_sync_queue $Queue"

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }


        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Stop-RabbitMqMirroringSync"
    }
}

Function Start-RabbitMqMirroringSync {
<#
.SYNOPSIS
    Adds mirroring for a queue

.DESCRIPTION
    This command instructs RabbitMQ to pause a queue and bring a mirrored queue into synch, by name.  The queue will block (not recieve or publish messages) while the two queues are being aligned.  Because active queues which are being drained will eventually be synhronized naturally, this command is primarily used for queues which are not being drained.

.PARAMETER Queue
    Required.  Name of the queue to synchronize.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER VHost
    Default host is "/", the root virtual host.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #This command ensures that all messages in the mirrored "myqueue" queue are present slave queues
        Start-RabbitMqMirroringSync myqueue -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Queue,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-p vhost]
        [Parameter(Mandatory=$false)]
        [String] $VHost=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Start-RabbitMqMirroringSync"
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
        $rabbitControlParams = $rabbitControlParams + "sync_queue $Queue"

        if($VHost){
            Write-Verbose "Adding vhost parameter."
            $rabbitControlParams = $rabbitControlParams + "-p $VHost"
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Start-RabbitMqMirroringSync"
    }
}

Function Stop-RabbitMqHost {
<#
.SYNOPSIS
    Stops the Erlang host / VM

.DESCRIPTION
    This command instructs the RabbitMQ node to stop the RabbitMQ Erlang node / VM.  Details:
        -This command generally run prior to shutting down the actual server.  To stop the RabbitMQ app, use Stop-RabbitMq.
        -To restart, follow the instructions for Running the Server in the installation guide.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker stopup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.PARAMETER Pid
    A process ID name / path to wait for termination on when stopping.  See also Wait-RabbitMq.

.EXAMPLE
    #Stops the RabbitMQ host VM at Node rabbit@HOSTNAME and suppress informational messages.
        Stop-RabbitMqHost -Node "rabbit@HOSTNAME" -Quiet

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

        # rabbitmqctl parameter [pid]
        [Parameter(Mandatory=$false)]
        [string] $PidName=$null
    )
    
    Begin
    {
        Write-Verbose "Begin: Stop-RabbitMqHost"
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
        $rabbitControlParams = $rabbitControlParams + "stop"
        if($PidName){
            Write-Verbose "Adding pid parameter."
            $rabbitControlParams = $rabbitControlParams + $PidName
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Stop-RabbitMqHost"
    }
}

Function Reset-RabbitMqCluster {
<#
.SYNOPSIS
    Resets the cluster "controller" for an offline node

.DESCRIPTION
    This command instructs an already clustered offline node to contact the specified node when waking up.  It is similar to a forwarding address for the cluster.
    - Differs from Set-RabbitMqCluster in that the node is already in the cluster, but may be out of synch and attempting to rejoin using a no longer valid node for the cluster.
    - Primarily used when the cluster members have changed while the target node is offline.  For example, in a rolling outage of a cluster containing Node1 and Node2, Node1 might go down, be replaced by Node3, then Node2 might be brought down and Node1 restarted.  This command informs Node1 to use Node3 for the latest cluster info, since Node2 is offline.

.PARAMETER ClusterNode
    Required. A node that is currently in the cluster.

.PARAMETER Node
    The node to re-attach to the cluster. Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker stopup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Re-adds node rabbit@HOSTNAME to the cluster which rabbit@ANOTHERHOST is currently part of.
        Reset-RabbitMqCluster -Node rabbit@HOSTNAME -Cluster rabbit@ANOTHERHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [clusternode]
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Cluster,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Reset-RabbitMqCluster"
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
        $rabbitControlParams = $rabbitControlParams + "update_cluster_nodes $Cluster"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMqCluster"
    }
}

Function Invoke-RabbitMqEval {
<#
.SYNOPSIS
    Evaluate an arbitrary Erlang expression

.DESCRIPTION
    This command instructs the node to submit a command to the Erlang VM for evaluation.  

.PARAMETER Expr
    Required.  The Erlang expression to evaluate.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker stopup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #Executes an internal Elrang command which identified suspicious processes which might be deadlocked / stuck
        Invoke-RabbitMqEval 'rabbit_diagnostics:maybe_stuck().' -Node rabbit@HOSTNAME 

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [expr]
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Expr,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Invoke-RabbitMqEval"
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
        $rabbitControlParams = $rabbitControlParams + "eval $Expr"

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Invoke-RabbitMqEval"
    }
}

Function Reset-RabbitMqClusterNames {
<#
.SYNOPSIS
    Changes the readable names of nodes in the cluster

.DESCRIPTION
    This command instructs RabbitMQ to update internal references to cluster nodes, by specifying old-value / new-value pairs.  The local node must be completely stopped prior to running this command.
    - It is possible to stop all nodes and rename them all simultaneously (in which case old and new names for all nodes must be given to every node) or stop and rename nodes one at a time (in which case each node only needs to be told how its own name is changing).

.PARAMETER Names
    Required.  Array of name changes in the format "A=>B" where A is the old name and B is the new name.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #This command changes the name of the cluster of which rabbit@LOCALHOST is a member to "recovery"
        Reset-RabbitMqClusterNames "passive=>active","backup=>standby","nydatacenter=>offshoredatacenter" -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [oldnode newnode]
        [Parameter(Mandatory=$true, Position=1)]
        [string[]] $Names,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Reset-RabbitMqClusterNames"
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
        $rabbitControlParams = $rabbitControlParams + "rename_cluster_node"

        $Names | ForEach {
            $items = $_ -split "=>" 
            if($items.Length -eq 2) {
                Write-Verbose "Adding name change parameter."
                $rabbitControlParams = $rabbitControlParams + $items[0]
                $rabbitControlParams = $rabbitControlParams + $items[1]
            } else {
                Write-Error "Invalid parameter format: values must be supplied in the format old_name=>new_name."
                Write-Error "Value supplied: $_"
                return;
            }
        }

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Reset-RabbitMqClusterNames"
    }
}

Function Invoke-RabbitMqHipeCompile {
<#
.SYNOPSIS
    Compiles files to optimize performance

.DESCRIPTION
    This command instructs RabbitMQ to precompile the node confguration using High Performance Erlang, which improves performance by substantially (20-80%) at the cost of additional startup time.

.PARAMETER Directory
    Required.  The directory to place the compiled files in.

.PARAMETER Node
    Default node is "rabbit@server", where server is the local host. On a host named "server.example.com", the node name of the RabbitMQ Erlang node will usually be rabbit@server (unless RABBITMQ_NODENAME has been set to some non-default value at broker startup time).  Can also be configured in the RabbitMQ config file.

.PARAMETER Quiet
    Informational messages are suppressed when quiet mode is in effect.

.EXAMPLE
    #This command compiles the Erlang files associated with rabbit@LOCALHOST, storing the resulting files in /tmp/rabbit-hipe/ebin
        Invoke-RabbitMqHipeCompile /tmp/rabbit-hipe/ebin -Node rabbit@LOCALHOST

.FUNCTIONALITY
    RabbitMQ
#>
    [cmdletbinding()]
    param (
        # rabbitmqctl parameter [oldnode newnode]
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Directory,

        # rabbitmqctl parameter [-n node]
        [Parameter(Mandatory=$false)]
        [String] $Node=$null,

        # rabbitmqctl parameter [-q (quiet)]
        [Parameter(Mandatory=$false)]
        [switch] $Quiet
    )
    
    Begin
    {
        Write-Verbose "Begin: Invoke-RabbitMqHipeCompile"
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
        $rabbitControlParams = $rabbitControlParams + "hipe_compile"
        $rabbitControlParams = $rabbitControlParams + $Directory

        Write-Verbose "Executing command: $rabbitControlPath $rabbitControlParams"
        Start-Process -ArgumentList $rabbitControlParams -FilePath "$rabbitControlPath" -NoNewWindow -Wait
    }

    End
    {
        Write-Verbose "End: Invoke-RabbitMqHipeCompile"
    }
}



# Export Declarations --------------------------------------------------------------------------------------------------
Export-ModuleMember -Function Add-RabbitMqUser
Export-ModuleMember -Function Add-RabbitMqVHost
Export-ModuleMember -Function Clear-RabbitMqParameter
Export-ModuleMember -Function Clear-RabbitMqPassword
Export-ModuleMember -Function Clear-RabbitMqPolicy
Export-ModuleMember -Function Clear-RabbitMqQueue
Export-ModuleMember -Function Clear-RabbitMqTrace
Export-ModuleMember -Function Clear-RabbitMqUserPermissions
Export-ModuleMember -Function Confirm-RabbitMqCredentials
Export-ModuleMember -Function Get-RabbitMqBindings
Export-ModuleMember -Function Get-RabbitMqBrokerStatus
Export-ModuleMember -Function Get-RabbitMqChannels
Export-ModuleMember -Function Get-RabbitMqClusterStatus
Export-ModuleMember -Function Get-RabbitMqConnections
Export-ModuleMember -Function Get-RabbitMqConsumers
Export-ModuleMember -Function Get-RabbitMqEncoderOptions
Export-ModuleMember -Function Get-RabbitMqEnvironment
Export-ModuleMember -Function Get-RabbitMqExchanges
Export-ModuleMember -Function Get-RabbitMqHealth
Export-ModuleMember -Function Get-RabbitMqParameters
Export-ModuleMember -Function Get-RabbitMqPermissionsByUser
Export-ModuleMember -Function Get-RabbitMqPermissionsByVHost
Export-ModuleMember -Function Get-RabbitMqPolicies
Export-ModuleMember -Function Get-RabbitMqReport
Export-ModuleMember -Function Get-RabbitMqQueues
Export-ModuleMember -Function Get-RabbitMqUsers
Export-ModuleMember -Function Get-RabbitMqVHosts
Export-ModuleMember -Function Invoke-RabbitMqDecoder
Export-ModuleMember -Function Invoke-RabbitMqEncoder
Export-ModuleMember -Function Invoke-RabbitMqEval
Export-ModuleMember -Function Invoke-RabbitMqHipeCompile
Export-ModuleMember -Function Invoke-RabbitMqLogSwap
Export-ModuleMember -Function Remove-RabbitMqConnection
Export-ModuleMember -Function Remove-RabbitMqNodeFromCluster
Export-ModuleMember -Function Remove-RabbitMqUser
Export-ModuleMember -Function Remove-RabbitMqVHost
Export-ModuleMember -Function Reset-RabbitMq
Export-ModuleMember -Function Reset-RabbitMqCluster
Export-ModuleMember -Function Reset-RabbitMqClusterNames
Export-ModuleMember -Function Reset-RabbitMqPassword
Export-ModuleMember -Function Start-RabbitMq
Export-ModuleMember -Function Start-RabbitMqMirroringSync
Export-ModuleMember -Function Set-RabbitMqCluster
Export-ModuleMember -Function Set-RabbitMqClusterName
Export-ModuleMember -Function Set-RabbitMqClusterNodeType
Export-ModuleMember -Function Set-RabbitMqDiskFree
Export-ModuleMember -Function Set-RabbitMqFlowControl
Export-ModuleMember -Function Set-RabbitMqParameter
Export-ModuleMember -Function Set-RabbitMqPolicy
Export-ModuleMember -Function Set-RabbitMqTrace
Export-ModuleMember -Function Set-RabbitMqUserPermissions
Export-ModuleMember -Function Set-RabbitMqUserTags
Export-ModuleMember -Function Stop-RabbitMq
Export-ModuleMember -Function Stop-RabbitMqHost
Export-ModuleMember -Function Stop-RabbitMqMirroringSync
Export-ModuleMember -Function Wait-RabbitMq
