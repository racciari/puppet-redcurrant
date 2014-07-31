define redcurrant18::stgdev ($action='create',$ns,$stgdev=$hostname) {

  case $action {
    'create': { $file_ensure = 'file'
                $directory_ensure = 'directory'
              }
    'remove': { $file_ensure = 'absent'
                $directory_ensure = 'absent'
              }
  }

  if $action == 'create' {
    $toplevel_dirs = ["/GRID/${ns}/${stgdev}"]
    file { $toplevel_dirs:
      ensure => directory,
      owner => "root",
      group => "root",
      mode => "0755",
    }
    $required_dirs = ["/GRID/${ns}/${stgdev}/conf","/GRID/${ns}/${stgdev}/core","/GRID/${ns}/${stgdev}/run","/GRID/${ns}/${stgdev}/logs"]
    file { $required_dirs:
      ensure => directory,
      owner => "admgrid",
      group => "admgrid",
      mode => "0755",
    }
  }

}
