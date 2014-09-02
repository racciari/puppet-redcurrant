define redcurrant18::elasticsearch ($type='elasticsearch', $action='create',
  $num='1', $options={fhs_compliance => 'true', environment => {}}) {

  #include redcurrant18

  $srvname = "${type}-${num}"
  $ES_HOME = "/usr/share/elasticsearch"

  # Path
  case $options['fhs_compliance'] {
    'true':  { $rundirname = "/var/run/redcurrant/${options['ns']}"
               $confdirname = "/etc/redcurrant/${options['ns']}"
               $logdirname = "/var/log/redcurrant/${options['ns']}/${type}"
               $tmpdir = "/var/tmp/redcurrant/${options['ns']}/${srvname}"
               $datadir = "/var/lib/redcurrant/${options['ns']}/${srvname}" }
    'false': { $griddirprefix = "/GRID/${options['ns']}/${options['stgdev']}"
               $rundirname = "${griddirprefix}/run"
               $confdirname = "${griddirprefix}/conf"
               $logdirname = "${griddirprefix}/logs/${type}"
               $tmpdir = "${griddirprefix}/tmp/${srvname}"
               $datadir = "/DATA/${options['ns']}/${options['stgdev']}/${srvname}" }
  }

  # File
  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory' }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent' }
  }

  if $action == 'create' {
    redcurrant18::namespace {"${options[ns]}-${srvname}":
      action => 'create',
      ns => "${options['ns']}",
      options => $options,
    }
    if $options['fhs_compliance'] == 'false' {
      redcurrant18::stgdev {"${options['ns']}-${options['stgdev']}-${srvname}":
        action => 'create',
        ns => "${options['ns']}",
        stgdev => "${options['stgdev']}",
      }
    }
    else {
      file { $rundirname:
        ensure => directory,
        owner => 'admgrid',
        group => 'admgrid',
        mode => '0755',
      }
    }
    package { ['elasticsearch', 'elasticsearch-redcurrant']:
      ensure => installed,
    }
  }

  file { ["${confdirname}/${srvname}",$datadir,$logdirname]:
    ensure => directory,
    owner => 'admgrid',
    group => 'admgrid',
    mode => '0755',
  }

  file { "${type}-${num}.yml":
    path => "${confdirname}/${srvname}/${type}.yml",
    ensure => $file_ensure,
    content => template("redcurrant18/${type}.yml.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  file { "${type}-${num}.logging.yml":
    path => "${confdirname}/${srvname}/logging.yml",
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

  redcurrant18::grid-init-service { "${options['ns']}-${srvname}":
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
# vi:syntax=puppet:filetype=puppet:ts=2:et:
