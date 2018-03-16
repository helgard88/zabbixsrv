class zabbixsrv (
  $dbhost = 'db.local',
  $dbname = 'zabbix',
  $dbuser = 'zabbix',
  $dbpassword = '3a66ikc_DB',
  $timezone = 'Europe/Kiev',
)
{

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



  package { 'httpd':
    ensure => installed, 
  }

  package { 'mysql':
    ensure => installed,
  }
 
  package { 'zabbix-server-mysql':
    ensure   => installed,
    provider => 'yum',
    require  => Yumrepo['zabbix-nonsupported'],
  }

  package { 'zabbix-web-mysql':
    ensure   => installed,
    provider => 'yum',
    require  => Package['zabbix-server-mysql'],

  }



  file { "/etc/zabbix/zabbix_server.conf":
    ensure  => file,
    content => template('zabbixsrv/zabbix_server.conf.erb'),
    owner   => 'zabbix',
    group   => 'zabbix',
    require => Package['zabbix-web-mysql'],
    mode    => '0666',
  }

  file { "/etc/httpd/conf.d/zabbix.conf":
    ensure  => file,
    content => template('zabbixsrv/zabbix.conf.erb'),
    require => Package['httpd'],
    notify  => Service['httpd'],
    mode    => '0664',
  }

  file {'/opt/db_init.sh':
    ensure  => 'file',
    content => template('zabbixsrv/db_init.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755', # Use 0700 if it is sensitive
    notify  => Exec['db_init'],
  }
->
  exec { 'db_init':
    command => "/bin/bash -c '/opt/db_init.sh'",
    creates => '/var/log/zabbix/zabbix_server.log',
    require => Package['mysql']
  }
  
  file {'/etc/zabbix/web/zabbix.conf.php':
    ensure  => file,
    content => template('zabbixsrv/zabbix.conf.php.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0664',
  }

  exec { 'setsebool':
    command => "setsebool -P httpd_can_network_connect_db=1",
    path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    require => Package['httpd'],
  }
  exec { 'setsebool2':
    command => "setsebool -P httpd_can_connect_zabbix on",
    path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    require => Package['httpd'],
  }
  exec { 'setsebool3':
    command => "setsebool -P zabbix_can_network on",
    path    => '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
    require => Package['httpd'],
  }

  service { 'httpd':
    ensure => running, 
  }

  service { 'zabbix-server':
    ensure  => running,
    require => File['/etc/httpd/conf.d/zabbix.conf'],
  }
  
  exec { 'firewall-cmd':
    command => "firewall-cmd --zone=public --add-port=80/tcp --permanent",
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
    subscribe  => Exec['firewall-cmd'],
  }


}
