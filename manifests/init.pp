# == Define: pin_package
#
# This module is used to pin/unpin a specific package version.
# If you pin a package version, "yum update" won't update that package
#
# === Parameters
#
# [*ensure*]
#   The version to pin. If you use 'latest', it will unpin the package
#   and remove it.
#
# [*pinpackage*]
#   the package name
#
# [*unpin*]
#  if set to true, it will unpin the package and remove it.
#
# [*pin_only*]
#  if set to true, it will only pin the package, but not install it.
#  This is useful if you have mutual dependencies issues.
#
# [*allow_downgrade*]
#  if set to false, it will not allow downgrades. Default is true.
#
# [*arch*]
#  the architecture to pin. Default is '*'
#
# [*epoch*]
#  the epoch to pin. Default is 0
#
# [*install_version_lock_package*]
#  if set to true, it will install the yum-versionlock package. Default is true.
#
# === Requires
#
# Nothing.
#
# === Examples
#
#  to pin a package:
#
#  pin_package { 'apache':
#    ensure => '0.5-40';
#  }
#
#  to unpin a previously pinned package. You need to re-use the last used
#  version (unfrotunately 'file_line' can match, but cannot delete only with
#  match) and use whatever value (true, yes, ok, wow, boom):
#
#  pin_package { 'apache':
#    ensure => '0.5-40',
#    unpin  => true;
#  }
#
#  If you have mutual dependencies issues, you set pin_only to true, and you use
#  the package resource with "require" against pin_package define. Example:
#
#  pin_package { ['salt-minion', 'salt-common']:
#    ensure => $my_version,
#    pin_only  => true;
#  }
#
#  package { ['salt-minion', 'salt-common']:
#    ensure  => $my_version,  # you could also use latest here, because you have already pinned
#    require => Pin_package['salt-minion', 'salt-common'];
#  }
#
#
define pin_package (
  String $ensure,
  String $pinpackage                    = $name,
  Boolean $unpin                        = false,
  Boolean $pin_only                     = false,
  Enum['*', 'x86_64', 'noarch'] $arch   = '*',
  # RedHat family only
  Integer $epoch                        = 0,
  Boolean $install_version_lock_package = true,
  # Debian family only
  Boolean $allow_downgrade              = true,
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
          ensure          => $ensure,
          install_options => ['--allow-downgrades'],
          require         => [
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
