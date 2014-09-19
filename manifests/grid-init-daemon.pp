define redcurrant18::grid-init-daemon ($type='gridinit',$num='0',$action='create',$options={fhs_compliance=>'true'}) {

  include redcurrant18

  # Path
  case $options['fhs_compliance'] {
    'true':  { $sysconfdir = "/etc"
               $sysconfdird = "/etc/gridinit.d"
               $localstatedir = "/var/run"
               $socket = "/var/run/gridinit.sock"
               $dirs = "${sysconfdir}"
    }
    'false': { $sysconfdir = "/GRID/${hostname}/conf"
               $sysconfdird = "/GRID/${hostname}/conf/gridinit.conf.d"
               $localstatedir = "/GRID/${hostname}/run"
               $socket = "/GRID/${hostname}/run/gridinit.sock"
               $dirs = ["/GRID/${hostname}","/GRID/${hostname}/conf","/GRID/${hostname}/conf/gridinit.conf.d","/GRID/${hostname}/core","/GRID/${hostname}/run"]
    }
  }

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
                file { $dirs:
                  ensure => directory,
                  owner => "admgrid",
                  group => "admgrid",
                  mode => "0755",
                }
    }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent'
    }
  }

  # File
  file { "${name}-gridinit.conf":
    path => "${sysconfdir}/gridinit.conf",
    ensure => $file_ensure,
    require => Package["grid-init"],
    content => template("redcurrant18/gridinit.conf.erb"),
    notify => Service["gridinit"],
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }
  file { "${name}-gridinit.log4crc":
    path => "${sysconfdir}/gridinit.log4crc",
    ensure => $file_ensure,
    require => Package["grid-init"],
    content => template("redcurrant18/gridinit.log4crc.erb"),
    notify => Service["gridinit"],
    owner => "admgrid",
    group => "admgrid",
    mode => "0644",
  }

  package { 'grid-init':
    ensure => present,
  }

  service { 'gridinit':
    ensure => running,
    enable => true,
    hasrestart => true,
    require => Package["grid-init"],
  }

}