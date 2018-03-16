class zabbixagent (
  $server = 'zabbix.local',
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

  file { "/etc/zabbix/zabbix_agentd.conf":
    ensure  => file,
    content => template('zabbixagent/zabbix_agentd.conf.erb'),
    owner   => 'zabbix',
    group   => 'zabbix',
    require => Package['zabbix-agent'],
    mode    => '0666',
    notify  => Service['zabbix-agent'],
  }

  service {'zabbix-agent':
    ensure  => running,
  }




}
