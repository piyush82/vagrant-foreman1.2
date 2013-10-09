# Configure the DHCP component
class foreman_proxy::proxydhcp {
  $ip   = inline_template("<%= scope.lookupvar('::ipaddress_${foreman_proxy::dhcp_interface}') %>")
  $net  = inline_template("<%= scope.lookupvar('::network_${foreman_proxy::dhcp_interface}') %>")
  $mask = inline_template("<%= scope.lookupvar('::netmask_${foreman_proxy::dhcp_interface}') %>")

  if $foreman_proxy::dhcp_nameservers == 'default' {
    $nameservers = [$ip]
  } else {
    $nameservers = split($foreman_proxy::dhcp_nameservers,',')
  }

  class { 'dhcp':
    dnsdomain    => [$::domain],
    nameservers  => $nameservers,
    #interfaces   => [$foreman_proxy::dhcp_interface],
    interfaces   => ['eth1','eth2'],
    #dnsupdatekey => /etc/bind/keys.d/foreman,
    #require      => Bind::Key[ 'foreman' ],
    pxeserver    => $ip,
    pxefilename  => 'pxelinux.0',
  }

  # dhcp::pool{ $::domain:
  #   network => $net,
  #   mask    => $mask,
  #   range   => $foreman_proxy::dhcp_range,
  #   gateway => $foreman_proxy::dhcp_gateway,
  # }

  # stable network
  dhcp::pool{ "s-mgt.${::domain}":
    network => "10.10.10.0",
    mask    => "255.255.255.0",
    range   => "10.10.10.50 10.10.10.250",
    gateway => "10.10.10.2",
  }
  
  dhcp::pool{ "s-data.${::domain}":
    network => "192.168.100.0",
    mask    => "255.255.255.0",
    range   => "192.168.100.50 192.168.100.250",
    gateway => "192.168.100.2",
  }

  # research network
  dhcp::pool{ "r-mgt.${::domain}":
    network => "10.10.11.0",
    mask    => "255.255.255.0",
    range   => "10.10.11.50 10.10.11.250",
    gateway => "10.10.11.2",
  }

  dhcp::pool{ "r-data.${::domain}":
    network => "192.168.101.0",
    mask    => "255.255.255.0",
    range   => "192.168.101.50 192.168.101.250",
    gateway => "192.168.101.2",
  }
}
