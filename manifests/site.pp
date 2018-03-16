node 'zabbix' {
  include zabbixsrv
}
node 'db'{
  include zabbixagent
}
