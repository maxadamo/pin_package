# == Define: pin_package::pin
#
# THIS IS OBSOLETE AND IT WILL BE REMOVED. 
# Please use init.pp instead. 
#
define pin_package::pin (
  String $ensure,
  $pinpackage                           = $name,
  Boolean $unpin                        = false,
  Boolean $pin_only                     = false,
  Enum['*', 'x86_64', 'noarch'] $arch   = '*',

  # RedHat family only
  Integer $epoch                        = 0,
  Boolean $install_version_lock_package = true,
) {

  # latest is, in fact, same as unpinning and purge and absent
  # means unpin and remove the package
  if $ensure in ['latest', 'purged', 'absent', 'present'] {
    $pinstatus = 'absent'
  } else {
    if any2bool($unpin) {
      $pinstatus = 'absent'
    } else {
      $pinstatus = 'present'
    }
  }

  case $facts['os']['name'] {
    'RedHat', 'CentOS': {
      pin_package::redhat_version_lock { $pinpackage:
        pkg_name                     => $pinpackage,
        pkg_status                   => $pinstatus,
        epoch                        => $epoch,
        pkg_version                  => $ensure,
        pin_only                     => $pin_only,
        arch                         => $arch,
        install_version_lock_package => $install_version_lock_package;
      }
    }
    /^(Debian|Ubuntu)$/: {
      if $unpin or $ensure == 'latest' {
        file { "/etc/apt/preferences.d/pin_${pinpackage}.pref":
          ensure  => $pinstatus;
        }
      } else {
        file { "/etc/apt/preferences.d/pin_${pinpackage}.pref":
          ensure  => $pinstatus,
          notify  => Exec['apt_update'],
          content => "Package: ${pinpackage}\nPin: version ${ensure}\nPin-Priority: 1001\n";
        }
      }
      unless any2bool($pin_only) {
        package { $pinpackage:
          ensure  => $ensure,
          require => [
            File["/etc/apt/preferences.d/pin_${pinpackage}.pref"],
            Exec['apt_update'],
          ];
        }
      }
    }
    default: {
      fail("${facts['os']['name']} not yet supported")
    }
  }

}
# vim:ts=2:sw=2
