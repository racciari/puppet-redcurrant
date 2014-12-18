define redcurrant18::namespace ($action='create',$ns,$options={fhs_compliance=>true}) {

  # Path
  if $options[fhs_compliance] {
    $required_path = ["/etc/redcurrant","/etc/redcurrant/${ns}","/var/log/redcurrant","/var/log/redcurrant/${ns}","/var/lib/redcurrant","/var/lib/redcurrant/core","/var/run/redcurrant","/var/run/redcurrant/${ns}"]
  } else {
    $required_path = ["/GRID","/GRID/${ns}"]
  }

  if $action == 'create' {
    file { $required_path:
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755',
    }
    unless $options[fhs_compliance] {
      file { "/GRID/${ns}/logs":
        ensure => directory,
        owner => 'admgrid',
        group => 'admgrid',
        mode => '0755',
      }
    }
  }

}
