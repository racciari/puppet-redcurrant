define redcurrant18::gridagent ($type='gridagent',$action='create',$num='0',$options={fhs_compliance=>'true'}) {

  include redcurrant18

  # Path
  case $options['fhs_compliance'] {
    'true':  { $sysconfdir = "/etc"
               $spoolstatedir = "/var/spool/redcurrant/${type}"
               $toplevel_dirs = ["/etc/gridstorage.conf.d","/var/lib/redcurrant"]
               $required_dirs = ["/var/lib/redcurrant/spool"]
    }
    'false': { $sysconfdir = "/GRID/common/conf"
               $spoolstatedir = "/DATA/${hostname}/spool"
               $toplevel_dirs = ["/etc/gridstorage.conf.d","/GRID/common"]
               $required_dirs = ["/GRID/common/conf","/GRID/common/core","/GRID/common/run"]
    }
  }

  redcurrant18::grid-init-service { "common-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/gridagent --child-req ${sysconfdir}/${type}.conf ${sysconfdir}/${type}.log4crc",
    enabled => 'true',
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "common,${type}",
    options => $options,
  }

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
              }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent'
              }
  }

  if $action == 'create' {
    file { $toplevel_dirs:
      ensure => directory,
      owner => "root",
      group => "root",
      mode => "0755",
    }
    file { $required_dirs:
      ensure => directory,
      owner => "admgrid",
      group => "admgrid",
      mode => "0755",
    }
    file { "/etc/gridstorage.conf":
      ensure => 'file',
      content => template("redcurrant18/gridstorage.conf.erb"),
      owner => "root",
      group => "root",
      mode => "0644",
    }
  }

  # File
  file { "${type}.conf":
    path => "${sysconfdir}/${type}.conf",
    ensure => $file_ensure,
    require => Package["redcurrant-server"],
    content => template("redcurrant18/${type}.conf.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }
  file { "${type}.log4crc":
    path => "${sysconfdir}/${type}.log4crc",
    ensure => $file_ensure,
    require => Package["redcurrant-server"],
    content => template("redcurrant18/log4crc.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }
  if $options['ns'] != undef {
    file { "/etc/gridstorage.conf.d/${options['ns']}":
      ensure => $file_ensure,
      content => template("redcurrant18/gridstoragens.conf.erb"),
      notify => Exec["reload-gridagent"],
      owner => "admgrid",
      group => "admgrid",
      mode => "0644",
    }
  }

  exec { "reload-gridagent":
    command => "/bin/ps -fC 'gridagent' | /bin/awk '/ --child-req / {print $2}'",
    refreshonly => true,
  }

}
