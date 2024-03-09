$dnsServers = (Get-NetAdapter | Where-Object InterfaceDescription -like "Cisco AnyConnect*" | Get-DnsClientServerAddress).ServerAddresses
$searchSuffix = (Get-DnsClientGlobalSetting).SuffixSearchList -join ','

function set-DnsWsl() {
  if ( $dnsServers ) {
    $setDnsCommand = $dnsServers | ForEach-Object { "echo 'nameserver $_' >> /etc/resolv.conf" }
    if ( $searchSuffix ) {
      $setDnsCommand += "echo 'search $searchSuffix' >> /etc/resolv.conf"
    }
    wsl.exe -u root bash -c "if [ -f /etc/resolv.conf ]; then rm /etc/resolv.conf; fi; $($setDnsCommand -join '; ')"
  }
  else {
    wsl.exe -u root bash -c "if [ -f /etc/resolv.conf ]; then rm /etc/resolv.conf; fi; echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
  }
}

set-DnsWsl