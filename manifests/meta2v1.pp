define redcurrant18::meta2v1 ($type='meta2v1',$action='create',$num='0',$options={fhs_compliance='true'}) {

  include redcurrant18

  # Path
  case $fhs_compliance {
    'true':  { $rundirname = "/etc/redcurrant/${options[ns]}/run"
               $sysconfdir = "/etc/redcurrant/${options[ns]}"
               $localstatedir = "/var/run/redcurrant"
               $spoolstatedir = "/var/spool/redcurrant/${type}"
    }
    'false': { $rundirname = "/GRID/${options[ns]}/${options[stgdev]}/run"
               $sysconfdir = "/GRID/${options[ns]}/${options[stgdev]}/conf"
               $localstatedir = "/GRID/${options[ns]}/${options[stgdev]}/run"
               $spoolstatedir = "/DATA/${hostname}/spool"
    }
  }

  if $options['ipportgroup'] {
    $groups = "${options[ns]},${type},${options[ipaddr]}:${options[port]}"
  }
  else {
    $groups = "${options[ns]},${type}"
  }

  redcurrant18::grid-init::config { "${options[ns]}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/gridd ${sysconfdir}/${type}-${num}.conf ${sysconfdir}/${type}-${num}.log4crc",
    enabled => 'true',
    start_at_boot => 'yes',
    on_die => 'respawn',
    group => $groups,
    fhs_compliance => "${fhs_compliance}",
    before => Exec['postinstall']
  }

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
                namespace { "${options[ns]}-${type}-${num}":
                  action => $action,
                  ns => "${options[ns]}",
                  fhs_compliance => "${fhs_compliance}",
                }
              }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent'
              }
  }

  if $action == 'create' {
    file { ["/DATA", "/DATA/${options[ns]}", "/DATA/${options[ns]}/${options[server]}" ] :
      ensure => 'directory',
      owner => "root",
      group => "root",
      before => Exec['postinstall']
    }

    file { "/DATA/${options[ns]}/${options[stgdev]}/${type}-${num}":
      ensure => $directory_ensure,
      owner => "admgrid",
      group => "admgrid",
      before => Exec['postinstall']
    }
    redcurrant18::stgdev {"${options[stgdev]}":
      action => $action,
      ns => "${options[ns]}",
      stgdev => "${options[stgdev]}",
      before => Exec['postinstall']
    }
  }

  file { "${type}-${num}.conf":
    path => "${sysconfdir}/${type}-${num}.conf",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}.conf.erb"),
    owner => "admgrid",
    group => "admgrid",
    before => Exec['postinstall']
  }

  file { "${type}-$num.log4crc":
    path => "${sysconfdir}/${type}-${num}.log4crc",
    ensure => $file_ensure,
    require => Package['log4c'],
    content => template("redcurrant18/log4crc.erb"),
    owner => "admgrid",
    group => "admgrid",
    before => Exec['postinstall']
  }

  exec { 'postinstall':
    command => '/usr/local/bin/gridinit_cmd reload'
  }
}

