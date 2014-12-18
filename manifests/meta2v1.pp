define redcurrant18::meta2v1 ($type='meta2v1',$action='create',$num='0',$options={fhs_compliance=>true}) {

  include redcurrant18

  # Path
  if $options[fhs_compliance] {
    $rcdir = "redcurrant/${options['ns']}"
    $rundirname = "/etc/${rcdir}/run"
    $sysconfdir = "/etc/${rcdir}"
    $localstatedir = "/var/run/redcurrant"
    $spoolstatedir = "/var/spool/redcurrant/${type}"
  } else {
    $rcdir = "${options['ns']}/${options['stgdev']}"
    $rundirname = "/GRID/${rcdir}/run"
    $sysconfdir = "/GRID/${rcdir}/conf"
    $localstatedir = "/GRID/${rcdir}/run"
    $spoolstatedir = "/DATA/${hostname}/spool"
  }

  if $options[ipportgroup] {
    $groups = "${options['ns']},${type},${options['ipaddr']}:${options['port']}"
  }
  else {
    $groups = "${options['ns']},${type}"
  }

  if $options[prefixdir] {
    $prefix = $options[prefixdir]
  } else {
    $prefix = '/usr/local'
  }
  
  if $options[libdir] {
    $lib = $options[libdir]
  } else {
    $lib = 'lib64'
  }
    
  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "${prefix}/bin/gridd ${sysconfdir}/${type}-${num}.conf ${sysconfdir}/${type}-${num}.log4crc",
    enabled => true,
    start_at_boot => 'yes',
    on_die => 'respawn',
    group => $groups,
    options => $options,
    before => Exec['postinstall']
  }

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
                namespace { "${options['ns']}-${type}-${num}":
                  action => $action,
                  ns => "${options['ns']}",
                  options => {'fhs_compliance' => $options['fhs_compliance']},
                }
              }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent'
              }
  }

  if $action == 'create' {
    file { ["/DATA", "/DATA/${options['ns']}", "/DATA/${options['ns']}/${options['server']}" ] :
      ensure => 'directory',
      owner => "root",
      group => "root",
      before => Exec['postinstall']
    }

    file { "/DATA/${options['ns']}/${options['stgdev']}/${type}-${num}":
      ensure => $directory_ensure,
      owner => "admgrid",
      group => "admgrid",
      before => Exec['postinstall']
    }
    redcurrant18::stgdev {"${options['stgdev']}":
      action => $action,
      ns => "${options['ns']}",
      stgdev => "${options['stgdev']}",
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

