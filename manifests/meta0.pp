define redcurrant18::meta0 ($type='meta0',$action='create',$num='0',$options={prefixdir=>'/usr/local',bindir=>'/usr/local/bin',fhs_compliance=>true}) {

  include redcurrant18
  
  if $options[vol] {
    $datadir = $options[vol]
  }

  # Path
  if $options[fhs_compliance] {
    $rcdir = "redcurrant/${options['ns']}"
    $rundirname = "/etc/${rcdir}/run"
    $sysconfdir = "/etc/${rcdir}"
    $localstatedir = '/var/run/redcurrant'
    unless $datadir {
      $datadir = "/var/lib/${rcdir}/${type}-${num}"
    }
  } else {
    $rcdir = "${options['ns']}/${options['stgdev']}"
    $rundirname = "/GRID/${rcdir}/run"
    $sysconfdir = "/GRID/${rcdir}/conf"
    $localstatedir = "/GRID/${rcdir}/run"
    unless $datadir {
      $datadir = "/DATA/${rcdir}/${type}-${num}"
    }
  }
  
  if $options[prefixdir] {
    $prefix = $options[prefixdir]
  } else {
    $prefix = '/usr/local'
  }

  redcurrant18::gridinitservice { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "${prefix}/bin/meta0_server -v -p ${rundirname}/${type}-${num}.pid -s RC,${options['ns']},${options['stgdev']},${type}-${num} -O Endpoint=${options['ipaddr']}:${options['port']} ${options['ns']} ${datadir}", 
    enabled => true,
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
    exec { 'postinstall':
      command => "/usr/local/bin/gridinit_cmd reload",
      before => Exec['meta0_init']
    }

	  $cmd_meta0_init = sprintf("${prefix}/bin/meta0_init -O NbReplicas=%d %s:%d %s 2>&1 | grep 'META0 filled!'",
	                  $options[nbmeta1s], $options[ipaddr],
	                  $options[port], $options[meta1s])
	  notice($cmd_meta0_init)
	
	  exec { 'meta0_init':
	    command => $cmd_meta0_init,
	    logoutput => true,
	    try_sleep => 2,
	    tries => 20
	  }
  }

}
