define redcurrant18::rcservice ($type='rcservice',$action='create',$num='1',$options={fhs_compliance=>true}) {

  if $options[vol] {
    $datadir = $options[vol]
  }
  
  # Path
  if $options[fhs_compliance] {
    $rcdir = "redcurrant/${options['ns']}"
    $rundirname = "/etc/${rcdir}/run"
    $sysconfdir = "/etc/${rcdir}"
    $localstatedir = "/var/run/redcurrant"
    $spoolstatedir = "/var/spool/redcurrant/${type}"
    unless $datadir {
      $datadir = "/var/lib/${rcdir}/${type}-${num}"
    }
  } else {
    $rcdir = "${options['ns']}/${options['stgdev']}"
    $rundirname = "/GRID/${rcdir}/run"
    $sysconfdir = "/GRID/${rcdir}/conf"
    $localstatedir = "/GRID/${rcdir}/run"
    $spoolstatedir = "/DATA/${hostname}/spool"
    unless $datadir {
      $datadir = "/DATA/${rcdir}/${type}-${num}"
    }
  }

  # File
  case $action {
    'create': {
      $file_ensure = 'file'
      $directory_ensure = 'directory'
      # Create namespace
      redcurrant18::namespace {"${options['ns']}-${type}-${num}":
        action => 'create',
        ns => "${options['ns']}",
        options => $options,
      }
      # Create stgdev if necessary
      unless $options[fhs_compliance] {
        redcurrant18::stgdev {"${options['ns']}-${options['stgdev']}-${type}-${num}":
        action => 'create',
        ns => "${options['ns']}",
        stgdev => "${options['stgdev']}",
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
    allow_virtual => false
  }

  package { 'log4c':
    ensure => installed,
    allow_virtual => false
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

  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/service ${sysconfdir}/${type}-${num}.conf ${sysconfdir}/${type}-${num}.log4crc",
    enabled => true,
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options['ns']},${type},${num},${type}-${num}",
    options => $options,
  }

}
