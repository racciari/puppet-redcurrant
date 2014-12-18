define redcurrant18::gridagentevt ($type='gridagentevt',$action='create',$num='0',$options={fhs_compliance=>true}) {

  include redcurrant18

  # Path
  if $options['fhs_compliance'] {
    $sysconfdir = "/etc"
  } else {
    $sysconfdir = "/GRID/common/conf"
  }

  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "/usr/local/bin/gridagent --child-evt=${options['ns']} ${sysconfdir}/gridagent.conf ${sysconfdir}/gridagent.log4crc",
    enabled => true,
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options['ns']},${type}",
    options => $options,
  }

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
                redcurrant18::gridagent { "gridagent-0":
                  options => $options,
                }
              }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent'
              }
  }

}
