define redcurrant18::conscience ($action='create',$type='conscience',$num='0',$options={fhs_compliance=>true}) {

  include redcurrant18

  # Required vars
  if $options['ns'] == undef or ($options['fhs_compliance'] == false and $options['stgdev'] == undef) {
    fail("All required variables are not satisfied for redcurrant18::conscience")
  }

  # Path
  if $options['fhs_compliance'] {
      $sysconfdir = "/etc/redcurrant/${options['ns']}"
      $localstatedir = '/var/run/redcurrant'
  } else {
      $sysconfdir = "/GRID/${options['ns']}/${options['stgdev']}/conf"
      $localstatedir = "/GRID/${options['ns']}/${options['stgdev']}/run"
  }

  # File
  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory' }
    'delete': { $file_ensure = 'absent'
                $directory_ensure = 'absent' }
  } 

  if $action == 'create' {
    redcurrant18::namespace {"${options['ns']}-${type}-${options['num']}":
      action => 'create',
      ns => "${options['ns']}",
      options => $options,
    }
    unless $options['fhs_compliance'] {
      redcurrant18::stgdev {"${options['ns']}-${options['stgdev']}-${type}-${options['num']}":
        action => 'create',
        ns => "${options['ns']}",
        stgdev => "${options['stgdev']}",
      }
    }
  }

  file { "${type}-${num}.conf":
    path => "${sysconfdir}/${type}-${num}.conf",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}.conf.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  file { "${type}-${num}.log4crc":
    path => "${sysconfdir}/${type}-${num}.log4crc",
    ensure => $file_ensure,
    require => Package['log4c'],
    content => template("redcurrant18/log4crc.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }
  file { "${type}-${num}.events":
    path => "${sysconfdir}/${type}-${num}.events",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}.events.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }
  file { "${type}-${num}.storage":
    path => "${sysconfdir}/${type}-${num}.storage",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}.storage.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/gridd ${sysconfdir}/${type}-${num}.conf ${sysconfdir}/${type}-${num}.log4crc",
    enabled => true,
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options['ns']},${type}",
    options => $options,
  }

}
