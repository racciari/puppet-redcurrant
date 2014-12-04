define redcurrant18::elasticsearch ($type='elasticsearch', $action='create',
  $num='1', $options={fhs_compliance => 'true', environment => {}}) {

  include redcurrant18

  $ES_HOME = "/usr/share/elasticsearch"
  $srvname = "${type}-${num}"

  # Path
  case $options['fhs_compliance'] {
    'true':  {
      $rundirname = "/etc/redcurrant/${options[ns]}/run"
      $sysconfdir = "/etc/redcurrant/${options[ns]}"
      $localstatedir = "/var/run/redcurrant"
      $spoolstatedir = "/var/spool/redcurrant/${type}"
      if "${options[vol]}" != "" { $datadir = "$options[vol]" }
      else { $datadir = "/var/lib/redcurrant/${options[ns]}/${type}-${num}" }
      $logdir = "/var/log/redcurrant/${options[ns]}/${type}-${num}"
    }
    'false': {
      $rundirname = "/GRID/${options[ns]}/${options[stgdev]}/run"
      $sysconfdir = "/GRID/${options[ns]}/${options[stgdev]}/conf"
      $localstatedir = "/GRID/${options[ns]}/${options[stgdev]}/run"
      $spoolstatedir = "/DATA/${hostname}/spool"
      if "${options[vol]}" != "" { $datadir = $options['vol'] }
      else { $datadir = "/DATA/${options[ns]}/${options[stgdev]}/${type}-${num}" }
      $logdir = "/GRID/${options[ns]}/logs"
    }
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
    #package { ['elasticsearch', 'elasticsearch-redcurrant']:
    #  ensure => installed,
    #}
  }

  file { ["${sysconfdir}/${srvname}"]:
    ensure => directory,
    owner => 'admgrid',
    group => 'admgrid',
    mode => '0755',
  }

  file { "${type}-${num}.yml":
    path => "${sysconfdir}/${srvname}/${type}.yml",
    ensure => $file_ensure,
    content => template("redcurrant18/${type}.yml.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  file { "${type}-${num}.logging.yml":
    path => "${sysconfdir}/${srvname}/logging.yml",
    ensure => $file_ensure,
    content => template("redcurrant18/${type}.logging.yml.erb"),
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  if $options['discovery_mode'] == '' {
    $options['discovery_mode'] = 'redcurrant'
  }

  if $options['environment'] {
    $environment = $options['environment']
  }
  else {
    $environment = {'ES_MIN_MEM' => '1g', 'ES_MAX_MEM' => '1g'}
  }

  redcurrant18::grid-init-service { "${options['ns']}-${srvname}":
    action => $action,
    command => "${ES_HOME}/bin/elasticsearch -p ${rundirname}/${srvname}.pid -Des.default.path.home=${ES_HOME} -Des.default.path.conf=${sysconfdir}/${srvname}",
    enabled => 'true',
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options[ns]},${type},${num},${srvname}",
    options => $options,
    environment => $options['environment']
  }

}
