define redcurrant18::service ($type='service',$action='create',$num='1',$options={fhs_compliance=>'true'}) {

  # Path
  case $options['fhs_compliance'] {
    'true': {
      $rundirname = "/etc/redcurrant/${options[ns]}/run"
      $sysconfdir = "/etc/redcurrant/${options[ns]}"
      $localstatedir = "/var/run/redcurrant"
      $spoolstatedir = "/var/spool/redcurrant/${type}"
    }
    'false': {
      $rundirname = "/GRID/${options[ns]}/${options[stgdev]}/run"
      $sysconfdir = "/GRID/${options[ns]}/${options[stgdev]}/conf"
      $localstatedir = "/GRID/${options[ns]}/${options[stgdev]}/run"
      $spoolstatedir = "/DATA/${hostname}/spool"
    }
  }
  if ( )

  # File
  case $action {
    'create': {
      $file_ensure = 'file'
      $directory_ensure = 'directory'
      # Create namespace
      redcurrant18::namespace {"${options[ns]}-${type}-${num}":
        action => 'create',
        ns => "${ns}",
        options => $options,
      }
      # Create stgdev if necessary
      if $options['fhs_compliance'] == 'false' {
        redcurrant18::stgdev {"${options[ns]}-${options[stgdev]}-${type}-${num}":
        action => 'create',
        ns => "${options[ns]}",
        stgdev => "${options[stgdev]}",
        }
      }
    }
    'remove': {
      $file_ensure = 'absent'
      $directory_ensure = 'absent'
    }
  }

  package { 'redcurrant-server':
    ensure => installed,
  }

  package { 'log4c':
    ensure => installed,
  }

  file { "${type}-${num}.conf":
    path => "${dirname}/${type}-${num}.conf",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}.conf.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  file { "${type}-${num}.log4crc":
    path => "${dirname}/${type}-${num}.log4crc",
    ensure => $file_ensure,
    require => Package['log4c'],
    content => template("redcurrant18/log4crc.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  redcurrant18::grid-init-service { "${options[ns]}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/service ${sysconfdir}/${type}-${num}.conf ${sysconfdir}/${type}-${num}.log4crc",
    enabled => 'true',
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options[ns]},${type},${num},${type}-${num}",
    options => $options,
  }

}
