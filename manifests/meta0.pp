define redcurrant18::meta0 ($type='meta0',$action='create',$num='0',$options={prefixdir=>'/usr/local',bindir=>'/usr/local/bin',fhs_compliance=>'true'}) {

  include redcurrant18

  # Path
  case $options['fhs_compliance'] {
    'true':  { $rundirname = "/etc/redcurrant/${options['ns']}/run"
               $sysconfdir = "/etc/redcurrant/${options['ns']}"
               $localstatedir = '/var/run/redcurrant' }
    'false': { $rundirname = "/GRID/${options['ns']}/${options['stgdev']}/run"
               $sysconfdir = "/GRID/${options['ns']}/${options['stgdev']}/conf"
               $localstatedir = "/GRID/${options['ns']}/${options['stgdev']}/run" }
  }

  redcurrant18::grid-init-service { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/meta0_server -v -p ${rundirname}/${type}-${num}.pid -s RC,${options['ns']},${options['stgdev']},${type}-${num} -O Endpoint=${options['ipaddr']}:${options['port']} ${options['ns']} ${options['datadir']}", 
    enabled => 'true',
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options['ns']},${type}",
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
    file { "${options['datadir']}":
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
    if $options['fhs_compliance'] == 'false' {
      redcurrant18::stgdev {"${options['ns']}-${options['stgdev']}-${type}-${num}":
        action => 'create',
        ns => "${options['ns']}",
        stgdev => "${options['stgdev']}",
      }
    }
  }

}
