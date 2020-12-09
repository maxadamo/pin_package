# == Define: pin_package::pin
#
# This module is used to pin/unpin a specific package version.
# If you pin a package version, "yum update" won't update that package
#
# === Parameters
#
# [*pin_package*]: the package name
# [*ensure*]: version to pin
#
# === Requires
#
# Nothing.
#
# === Examples
#
#  to pin a package:
#
#  pin_package::pin { 'apache':
#    ensure => '0.5-40';
#  }
#
#  to unpin a previously pinned package. You need to re-use the last used
#  version (unfrotunately 'file_line' can match, but cannot delete only with
#  match) and use whatever value (true, yes, ok, wow, boom):
#
#  pin_package::pin { 'apache':
#    ensure => '0.5-40',
#    unpin  => true;
#  }
#
#  If you have mutual dependencies issues, you set pin_only to true, and you use
#  the package resource with "require" against pin_package define. Example:
#
#  pin_package::pin { ['salt-minion', 'salt-common']:
#    ensure => $my_version,
#    pin_only  => true;
#  }
#
#  package { ['salt-minion', 'salt-common']:
#    ensure  => $my_version,  # you could also use latest here, because you have already pinned
#    require => Pin_package::Pin['salt-minion', 'salt-common'];
#  }
#
#
define pin_package::pin (
  Optional[String] $ensure,
  Integer $epoch                                = 0, # RedHat family only
  $pinpackage                                   = $name,
  Boolean $unpin                                = false,
  Boolean $pin_only                             = false,
  Optional[Enum['*', 'x86_64', 'noarch']] $arch = '*',
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
      $version_lock_pkg = $facts['os']['release']['major'] ? {
        '8'     => 'python3-dnf-plugin-versionlock',
        default => 'yum-plugin-versionlock'
      }
      version_lock { $pinpackage:
        pkg_name    => $pinpackage,
        pkg_status  => $pinstatus,
        epoch       => $epoch,
        pkg_version => $ensure,
        pin_only    => $pin_only,
        arch        => $arch,
        require     => Package[$version_lock_pkg];
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
