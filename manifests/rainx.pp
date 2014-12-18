define redcurrant18::rainx ($type='rainx',$action='create',$num='0',$options={fhs_compliance=>true}) {

  include redcurrant18

  # Path
  if $options[fhs_compliance] {
    $rcdir = "redcurrant/${options['ns']}"
    $sysconfdir = "/etc/${rcdir}"
    $localstatedir = "/var/run/${rcdir}"
    $sharedstatedir = "/var/lib/redcurrant"
    $logstatedir = "/var/log/${rcdir}"
    $docroot = "/var/lib/${rcdir}/${type}-${num}"
  } else {
    $rcdir = "${options['ns']}/${options['stgdev']}"
    $sharedstatedir = "/GRID/${rcdir}"
    $sysconfdir = "${sharedstatedir}/conf"
    $localstatedir = "${sharedstatedir}/run"
    $logstatedir = "${sharedstatedir}/logs"
    $docroot = "/DATA/${rcdir}/${type}-${num}"
  }

  if $options[ipportgroup] {
    $groups = "${options['ns']},${type},${options['ipaddr']}:${options['port']}"
  }
  else {
    $groups = "${options['ns']},${type}"
  }

  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/redc-${type}-monitor ${sysconfdir}/${type}-${num}-monitor.conf ${sysconfdir}/${type}-${num}-monitor.log4crc",
    enabled => true,
    start_at_boot => 'yes',
    on_die => 'respawn',
    group => $groups,
    options => $options,
    before => Exec['postinstall']
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
    owner => 'admgrid',
    group => 'admgrid',
    before => Exec['postinstall']
  }

  file { "${type}-monitor.conf":
    path => "${sysconfdir}/${type}-${num}-monitor.conf",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/${type}-monitor.conf.erb"),
    owner => 'admgrid',
    group => 'admgrid',
    before => Exec['postinstall']
  }

  file { "${type}-monitor.log4c":
    path => "${sysconfdir}/${type}-${num}-monitor.log4crc",
    ensure => $file_ensure,
    require => Package['redcurrant-server'],
    content => template("redcurrant18/log4crc.erb"),
    owner => 'admgrid',
    group => 'admgrid',
    before => Exec['postinstall']
  }

  if $action == 'create' {
    file { ["/DATA", "/DATA/${options['ns']}", "/DATA/${options['ns']}/${options['server']}" ] :
      ensure => 'directory',
      owner => "admgrid",
      group => "admgrid",
      before => Exec['postinstall']
    }

    file { "$docroot":
      ensure => $directory_ensure,
      owner => "admgrid",
      group => "admgrid",
      before => Exec['postinstall']
    }
    redcurrant18::namespace {"${options['ns']}-${type}-${num}":
      action => 'create',
      ns => "${options['ns']}",
      options => {fhs_compliance => $options[fhs_compliance]},
      before => Exec['postinstall']
    }
    unless $options[fhs_compliance] {
      redcurrant18::stgdev {"${options['ns']}-${options['stgdev']}-${type}-${num}":
        action => 'create',
        ns => "${options['ns']}",
        stgdev => "${options['stgdev']}",
        before => Exec['postinstall']
      }
    }

    exec { 'postinstall':
      command => '/usr/local/bin/gridinit_cmd reload'
    }
  }

}
