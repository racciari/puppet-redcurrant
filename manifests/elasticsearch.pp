define redcurrant18::elasticsearch ($type='elasticsearch', $action='create',
  $num='1', $options={fhs_compliance => 'true', environment => {}}) {

  #include redcurrant18

  $srvname = "${type}-${num}"

  # Path
  case $options['fhs_compliance'] {
    'true':  { $sysconfdir = "/etc/redcurrant/${ns}"
               $localstatedir = '/var/run/redcurrant'
               $ES_HOME = "/usr/share/elasticsearch"
               $rundir = "${localstatedir}"
               $logdir = "/var/log/redcurrant"
			   $rundirname = "/etc/redcurrant/${options['ns']}/run"
			   $confdirname = "${sysconfdir}"
			   $logdirname = "${logdir}/${type}"
               $tmpdir = "${localstatedir}/tmp/redcurrant"
               $datadir = "${localstatedir}/lib/redcurrant/${type}-${num}" }
    'false': { $dirname = "/GRID/${options['ns']}/${options['stgdev']}"
               $rundirname = "/GRID/${options['ns']}/${options['stgdev']}/run"
               $bindirname = "/GRID/${options['ns']}/${options['stgdev']}/bin"
               $confdirname = "/GRID/${options['ns']}/${options['stgdev']}/conf"
               $logdirname = "/GRID/${options['ns']}/${options['stgdev']}/logs/${type}"
               $ES_HOME = "/usr/share/elasticsearch"
               $tmpdir = "/GRID/${options['ns']}/${options['stgdev']}/tmp/${type}-${num}"
               $datadir = "/DATA/${options['ns']}/${options['stgdev']}/${type}-${num}" }
  }

  # File
  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory' }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent' }
  }

  if $action == 'create' {
    redcurrant18::namespace {"${options[ns]}-${type}-${num}":
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
    package { ['elasticsearch', 'elasticsearch-redcurrant']:
      ensure => installed,
    }
  }

  file { ["${confdirname}/${type}-${num}","/GRID/${options['ns']}/logs",
          "${datadir}","${bindirname}","${logdirname}"]:
    ensure => directory,
    owner => 'admgrid',
    group => 'admgrid',
    mode => '0755',
  }

  file { "${type}-${num}.yml":
    path => "${confdirname}/${type}-${num}/${type}.yml",
    ensure => $file_ensure,
    content => template("redcurrant18/${type}.yml.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  file { "${type}-${num}.logging.yml":
    path => "${confdirname}/${type}-${num}/logging.yml",
    ensure => $file_ensure,
    content => template("redcurrant18/${type}.logging.yml.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  if $options['ipportgroup'] {
    $groups = "${options[ns]},${type},${num},${srvname},${options[ipaddr]}:${options[port]}"
  }
  else {
    $groups = "${options[ns]},${type},${num},${srvname}"
  }

  if $options['environment'] {
    $environment = $options['environment']
  }
  else {
    $environment = {}
  }

  redcurrant18::grid-init-service { "${options['ns']}-${type}-${num}":
    action => $action,
    command => "${ES_HOME}/bin/elasticsearch -p ${rundirname}/${srvname}.pid -Des.default.path.home=${ES_HOME} -Des.default.path.work=${tmpdir} -Des.default.path.conf=${confdirname}/${srvname}",
    enabled => 'true',
    start_at_boot => 'no',
    on_die => 'respawn',
    group => $groups,
    options => $options,
	environment => $environment,
  }

}
