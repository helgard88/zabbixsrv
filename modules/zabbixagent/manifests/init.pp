class zabbixagent (
  $server = 'zabbix.if083',
  $aport = '10050',
){

    
  # configure zabbix repo
  # insert gpg-key
  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///modules/zabbixsrv/etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX',
  }
->
  # main repo
  yumrepo { 'zabbix':
    enabled  => 1,
    priority => 1,
    baseurl  => 'http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/',
    gpgcheck => 0,
    includepkgs => absent,
    exclude     => absent,
    gpgkey      => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX',
    require     => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX'],
  }
->
  # zabbix-nonsupported repo
  yumrepo { 'zabbix-nonsupported':
    enabled  => 1,
    priority => 1,
    baseurl  => 'https://repo.zabbix.com/non-supported/rhel/7/x86_64/',
    gpgcheck => 0,
    includepkgs => absent,
    exclude     => absent,
    gpgkey      => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX',
    require     => Yumrepo['zabbix'],
  }

  package { 'zabbix-agent':
    ensure   => installed,
    provider => 'yum',
    require  => Yumrepo['zabbix-nonsupported'],
  }

  #selinux crutch =)
  package { 'policycoreutils-python':
    ensure   => installed,
    require => Package['zabbix-agent'],
  }
->
  file {'/opt/selinux_permit.sh':
    ensure  => 'file',
    content => template('zabbixagent/selinux_permit.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755', # Use 0700 if it is sensitive
    notify  => Exec['selinux'],
  }
->
  exec { 'selinux':
    command => "/bin/bash -c '/opt/selinux_permit.sh'",
  }



  file { "/etc/zabbix/zabbix_agentd.conf":
    ensure  => file,
    content => template('zabbixagent/zabbix_agentd.conf.erb'),
    owner   => 'zabbix',
    group   => 'zabbix',
    require => File['/opt/selinux_permit.sh'],
    mode    => '0666',
    notify  => Service['zabbix-agent'],
  }
->
  service {'zabbix-agent':
    ensure  => running,
  }


  
  #firewall
  exec { 'firewall-cmd-zabbix':
    command => "firewall-cmd --zone=public --add-port=10050/tcp --permanent",
    path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    notify  => Exec['firewall-reload'],
  }
  ->
  exec { 'firewall-reload':
    command => "firewall-cmd --reload",
    path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    notify  => Service['firewalld'],
  }
  ->
  service { 'firewalld':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    subscribe  => Exec['firewall-cmd-zabbix'],
  }



}
