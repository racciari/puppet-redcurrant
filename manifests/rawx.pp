define redcurrant18::rawx ($type='rawx',$action='create',$num='0',$options={fhs_compliance=>true}) {

  include redcurrant18

  if $options[vol] {
    $datadir = $options[vol]
  }
  
  # Path
  if $options[fhs_compliance] {
    $rcdir = "redcurrant/${options['ns']}"
    $sysconfdir = "/etc/${rcdir}"
    $localstatedir = "/var/run/${rcdir}"
    $sharedstatedir = '/var/lib/redcurrant'
    $logstatedir = "/var/log/${rcdir}"
    unless $datadir {
      $datadir = "/var/lib/${rcdir}/${type}-${num}"
    }
  } else {
    $rcdir = "${options['ns']}/${options['stgdev']}"
    $sharedstatedir = "/GRID/${rcdir}"
    $sysconfdir = "${sharedstatedir}/conf"
    $localstatedir = "${sharedstatedir}/run"
    $logstatedir = "${sharedstatedir}/logs"
    unless $datadir {
      $datadir = "/DATA/${rcdir}/${type}-${num}"
    }
  }

  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/redc-${type}-monitor ${sysconfdir}/${type}-${num}-monitor.conf ${sysconfdir}/${type}-${num}-monitor.log4crc",
    enabled => true,
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options['ns']},${type},${num}",
    options => $options,
  }

  # Packages
  package { 'redcurrant-mod-httpd':
    ensure => installed,
    allow_virtual => false
  }

  # File
  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory' }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent' }
  }

  file { "${type}-httpd.conf":
    path => "${sysconfdir}/${type}-${num}-httpd.conf",
    ensure => $file_ensure,
    require => Package['redcurrant-mod-httpd'],
    content => template("redcurrant18/${type}-httpd.conf.erb"),
    mode => "0644",
  }

  file { "${type}-monitor.conf":
    path => "${sysconfdir}/${type}-${num}-monitor.conf",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}-monitor.conf.erb"),
    mode => "0644",
  }

  file { "${type}-monitor.log4c":
    path => "${sysconfdir}/${type}-${num}-monitor.log4crc",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/log4crc.erb"),
    mode => "0644",
  }

  if $action == 'create' {
    file { $datadir:
      ensure => $directory_ensure,
      owner => "admgrid",
      group => "admgrid",
      mode => "0750",
    }
    redcurrant18::namespace {"${options['ns']}-${type}-${num}":
      action => 'create',
      ns => "${options['ns']}",
      options => $options,
    }
    unless $options[fhs_compliance] {
      redcurrant18::stgdev {"${options['ns']}-${options['stgdev']}-${type}-${num}":
        action => 'create',
        ns => "${options['ns']}",
        stgdev => "${options['stgdev']}",
      }
    }
  }

}
