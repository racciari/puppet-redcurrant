define redcurrant18::zookeeper ($type='zookeeper',$action='create',$num='0',$options={}) {

  include redcurrant18

  # Packages
  package { 'zookeeper':
    ensure => installed,
  }

# openjdk mandatory for zookeeper. gcj is bullhsit
  package { 'java-1.6.0-openjdk':
    ensure => installed,
  }

  # Path
  case $fhs_compliance {
    'true':  { $rundirname = "/etc/redcurrant/${options[ns]}/run" }
    'false': { $rundirname = "/GRID/${options[ns]}/${options[stgdev]}/run" }
  }


  if $action == 'create' {
    file { "/etc/zookeeper/zoo.cfg":
      ensure => 'file',
      owner => "root",
      group => "root",
      require => Package['zookeeper'],
      content => template("redcurrant18/zoo.cfg.erb"),
      path => "/etc/zookeeper/zoo.cfg",
    }

#    file { "/etc/gridstorage.conf.d/${options[ns]}":
#      ensure => 'file',
#      owner => "root",
#      group => "root",
#      content => template("redcurrant18/gridstoragens.conf.erb"),
#      path => "/etc/gridstorage.conf.d/${options[ns]}",
#      before => Exec['zookeeper init']
#    }
  
#    exec { "zookeeper init":
#      command => "/usr/local/bin/zk-bootstrap.py ${options[ns]}",
#      unless => "/bin/sleep 3 && /usr/bin/zkCli.sh ${options[zookeeper_url]} \"ls /hc\" | grep volumes" ,
#    }
#    service { "zookeeper":
#      ensure => 'running',
#      enable => true,
#      before => Exec["zookeeper init"],
#    }
  }
}
