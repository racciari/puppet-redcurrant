define redcurrant18::namespace ($action='create',$ns,$options={fhs_compliance=>'true'}) {

  # Path
  case $options['fhs_compliance'] {
    'true':  { $required_path = ["/etc/redcurrant","/etc/redcurrant/${ns}","/var/log/redcurrant","/var/log/redcurrant/${ns}","/var/lib/redcurrant","/var/lib/redcurrant/core","/var/run/redcurrant","/var/run/redcurrant/${ns}"] }
    'false': { $required_path = ["/GRID","/GRID/${ns}"] }
  }

  if $action == 'create' {
    file { $required_path:
      ensure => directory,
      owner => 'root',
      group => 'root',
      mode => '0755',
    }
  }

}
