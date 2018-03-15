class zabbixsrv (
  $dbhost = 'db.local',
  $dbname = 'zabbix',
  $dbuser = 'zabbix',
  $dbpassword = 'zabbix',
)
{

  # configure zabbix repo 
  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX':
    ensure => present,
    owner  => root,
    group  => root,
    mode   => '0644',
    source => 'puppet:///environments/production/modules/zabbixsrv/etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX',
  }

  yumrepo { 'zabbixrepo':
    enabled  => 1,
    priority => 1,
    baseurl  => 'http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/',
    gpgcheck => 0,
    includepkgs => absent,
    exclude     => absent,
    gpgkey      => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX',
    require     => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX'],
  }

  package { 'httpd':
    ensure => installed, 
  }

  package { 'zabbix-server-mysql':
    ensure => installed,
    provider => 'yum',
    require => yumrepo['zabbixrepo'],
  }

  package { 'zabbix-web-mysql':
    ensure => installed,
    provider => 'yum',
    require => Package['zabbix-server-mysql'],

  }
  
  service { 'httpd':
    ensure => running, 
  }

  service { 'zabbix-server':
    ensure  => running,
    require => Package['zabbix-web-mysql'],
  }

}

