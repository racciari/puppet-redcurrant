define redcurrant18::grid-init-service ($action='create',$command,$enabled,$start_at_boot,$on_die,$group,$options={fhs_compliance=>'true'}) {

  include redcurrant18

  # Path
  case $options['fhs_compliance'] {
    'true':  { $sysconfdir = '/etc/gridinit.d'
               $socket = '/var/run/gridinit.sock' }
    'false': { $sysconfdir = "/GRID/${hostname}/conf/gridinit.conf.d"
               $socket = "/GRID/${hostname}/run/gridinit.sock" }
  }
  
  redcurrant18::grid-init-daemon {"gridinit-0":
    options => {
      fhs_compliance => $options[fhs_compliance],
      ns => 'common',
    }
  }

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
              }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent' }
  }

  # Config file
  file { "${title}":
    path => "${sysconfdir}/${title}",
    ensure => $file_ensure,
    content => template("redcurrant18/grid-init-service.erb"),
    notify => Exec["restart-${title}"],
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  # Reload action
  exec { "reload-${title}":
    command => "/usr/local/bin/gridinit_cmd -S ${socket} reload",
    refreshonly => true,
    require => Package["redcurrant-grid-init"],
  }

  # Restart action
  exec { "restart-${title}":
    command => "/usr/local/bin/gridinit_cmd -S ${socket} restart ${title}",
    refreshonly => true,
    refresh => "/usr/local/bin/gridinit_cmd -S ${socket} restart ${title}",
    require => Exec["reload-${title}"],
  }

}
