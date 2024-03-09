# WSL 2 and Cisco AnyConnect VPN: A Networking Solution
## Introduction

This repository provides a workaround for a known issue with WSL 2 and Cisco AnyConnect VPN. When a VPN session is established, firewall rules and routes are added that disrupt network connectivity within the WSL 2 VM. This issue is tracked in [WSL/issues/4277](https://github.com/microsoft/WSL/issues/4277) and [WSL/issues/5068](https://github.com/microsoft/WSL/issues/5068).

The provided scripts automatically configure the interface metric on VPN connect and update DNS settings (/etc/resolv.conf) on connect/disconnect, thereby maintaining network connectivity.

## Getting Started

### Prerequisites

Ensure that you have WSL 2 and Cisco AnyConnect VPN installed on your system.

### Installation

1. Clone this repository or download the scripts.
2. Save the scripts to a local directory, for example, `%HOMEPATH%\wsl\scripts`.

## Scripts description
### setCiscoVpnMetric.ps1
This PowerShell script adjusts the network interface metric for the Cisco AnyConnect VPN adapter to prevent the VPN connection from interfering with other network connections in WSL 2.

When executed, the script:

- Retrieves all network adapters on the system using the `Get-NetAdapter` cmdlet.
- Filters these adapters to find the one with an interface description that matches "Cisco AnyConnect" using the `Where-Object` cmdlet.
- Sets the interface metric of the Cisco AnyConnect adapter to 6000 using the `Set-NetIPInterface` cmdlet.

This high interface metric ensures that the system prioritizes other network interfaces over the VPN when establishing network connections.

### setDns.ps1

The setDns.ps1 script is a PowerShell script designed to update the DNS settings in a WSL 2 Linux VM. This is particularly useful in environments where the VPN connection might interfere with other network connections, such as with WSL 2.

When run, the script performs the following steps:

- It uses the `Get-NetAdapter` cmdlet to retrieve all network adapters on the system.
- It filters these adapters with the `Where-Object` cmdlet to find the adapter with an interface description that matches "Cisco AnyConnect".
- It then uses the `Set-NetIPInterface` cmdlet to set the interface metric of the Cisco AnyConnect adapter to 6000.

By setting a high interface metric, the system will prioritize other network interfaces over the VPN when establishing network connections. This can help to maintain network connectivity in certain situations where the VPN might otherwise take precedence.


## Usage

### WSL configuration (one time setup)
1. Open WSL 2
2. Run the following command to unlink the default /etc/resolv.conf file in WSL 2 and prevent it from being overwritten on startup:
    ```bash
    sudo unlink /etc/resolv.conf
    ```
3. Run the following command to update the WSL 2 configuration file to prevent it from overwriting the /etc/resolv.conf file on startup:
    ```bash
    sudo tee /etc/wsl.conf <<EOF
    [network]
    generateResolvConf = false
    EOF
    ```

### Create Scheduled Tasks
Windows Scheduled Tasks allows you to trigger an action when a certain log event comes in. The Cisco AnyConnect VPN client generates a number of log events.

We will create two tasks. The first task, will configure the interface metric when the VPN connects. The second task, will execute the dns update script inside of your Linux VM when the VPN Connects and Disconnects.

#### Cisco AnyConnect Events
- 2039: VPN Established and Passing Data
- 2061: Network Interface for the VPN has gone down
- 2010: VPN Termination
- 2041: The entire VPN connection has been re-established.

#### Procedure
1. Open Task Scheduler
2. Create a Folder called `WSL` (Optional, but easier to find rules later)
3. Create Rules
    1. Update AnyConnect Adapter Interface Metric for WSL2
        * General: Check: Run with highest privileges
        * Triggers:
            * On an Event, Log: `Cisco AnyConnect Secure Mobility Client`, Source: `acvpnagent`, Event ID: `2039`
            * On an Event, Log: `Cisco AnyConnect Secure Mobility Client`, Source: `acvpnagent`, Event ID: `2041`
        * Action: Start a program, Program: `Powershell.exe`, Add arguments: `-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File %HOMEPATH%\wsl\scripts\setCiscoVpnMetric.ps1`
        * Condition: Uncheck: Start the task only if the computer is on AC power
    2. Update DNS in WSL2 Linux VMs
        * Triggers:
            * On an Event, Log: `Cisco AnyConnect Secure Mobility Client`, Source: `acvpnagent`, Event ID: `2039`
            * On an Event, Log: `Cisco AnyConnect Secure Mobility Client`, Source: `acvpnagent`, Event ID: `2010`
            * On an Event, Log: `Cisco AnyConnect Secure Mobility Client`, Source: `acvpnagent`, Event ID: `2061`
            * On an Event, Log: `Cisco AnyConnect Secure Mobility Client`, Source: `acvpnagent`, Event ID: `2041`
            * At log on: At log on of $USER 
        * Action: Start a program, Program: `Powershell.exe`, Add arguments: `-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File %HOMEPATH%\wsl\scripts\setDns.ps1`
        * Condition: Uncheck: Start the task only if the computer is on AC power
4. Test: Connect to the VPN, a powershell window should pop-up briefly 

## FAQ
Q: How do I revert/disable these changes?\
A: Disable scheduled Tasks, Reboot wsl

## License
This project is licensed under the MIT License