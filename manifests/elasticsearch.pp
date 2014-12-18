define redcurrant18::elasticsearch ($type='elasticsearch', $action='create',
  $num='1', $options={fhs_compliance => true, environment => {}}) {

  include redcurrant18

  $es_home = "/usr/share/elasticsearch"
  $srvname = "${type}-${num}"

  if $options[vol] {
    $datadir = $options[vol]
  }

  # Path
  if $options['fhs_compliance'] {
    $rcdir = "redcurrant/${options['ns']}"
    $rundirname = "/etc/${rcdir}/run"
    $sysconfdir = "/etc/${rcdir}"
    $localstatedir = "/var/run/redcurrant"
    $spoolstatedir = "/var/spool/redcurrant/${type}"
    unless $datadir {
      $datadir = "/var/lib/${rcdir}/${type}-${num}"
    }
    $logdir = "/var/log/${rcdir}/${type}-${num}"
  } else {
    $rcdir = "${options['ns']}/${options['stgdev']}"
    $rundirname = "/GRID/${rcdir}/run"
    $sysconfdir = "/GRID/${rcdir}/conf"
    $localstatedir = "/GRID/${rcdir}/run"
    $spoolstatedir = "/DATA/${hostname}/spool"
    unless $datadir {
      $datadir = "/DATA/${rcdir}/${type}-${num}"
    }
    $logdir = "/GRID/${options['ns']}/logs"
  }

  # File
  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory' }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent' }
  }

  if $action == 'create' {
    redcurrant18::namespace {"${options['ns']}-${srvname}":
      action => 'create',
      ns => "${options['ns']}",
      options => $options,
    }
    if $options['fhs_compliance'] {
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

  redcurrant18::gridinitservice { "${options['ns']}-${srvname}":
    action => $action,
    command => "${es_home}/bin/elasticsearch -p ${rundirname}/${srvname}.pid -Des.default.path.home=${es_home} -Des.default.path.conf=${sysconfdir}/${srvname}",
    enabled => true,
    start_at_boot => 'no',
    on_die => 'respawn',
    group => "${options['ns']},${type},${num},${srvname}",
    options => $options,
    environment => $options['environment']
  }

}
