# == Define: pin_package::redhat_version_lock
#
# This module is run only from pin_package
#
# === Parameters
#
# [*pkg_name*]
#   The name of the package to pin
#
# [*epoch*]
#   The epoch of the package to pin
#
# [*pkg_status*]
#   The status of the package to pin
#
# [*pkg_version*]
#   The version of the package to pin
#
# [*pin_only*]
#   Whether to pin only or also install the package
#
# [*arch*]
#   The architecture of the package to pin
#
# [*install_version_lock_package*]
#   Whether to install the versionlock package
#
define pin_package::redhat_version_lock (
  String $pkg_name,
  Integer $epoch,
  String $pkg_status,
  String $pkg_version,
  Boolean $pin_only,
  String $arch,
  Boolean $install_version_lock_package
) {
  assert_private("this define is intended to be called only within ${module_name}")

  if $pkg_status == 'absent' { $replace = false } else { $replace = true }

  $version_lock_package = $facts['os']['release']['major'] ? {
    '8'     => 'python3-dnf-plugin-versionlock',
    default => 'yum-plugin-versionlock'
  }

  if any2bool($install_version_lock_package) {
    unless defined(Package[$version_lock_package]) {
      package { $version_lock_package: ensure => present; }
    }
  }

  if $facts['os']['release']['major'] == '8' {
    file_line { $pkg_name:
      ensure            => $pkg_status,
      path              => '/etc/dnf/plugins/versionlock.list',
      line              => "${pkg_name}-${epoch}:${pkg_version}.${arch}",
      match             => "^${pkg_name}-${epoch}:(\\d)",
      require           => Package[$version_lock_package],
      notify            => Exec["clean_expire_cache_${module_name}_${pkg_name}"],
      match_for_absence => true,
      replace           => $replace;
    }
  } else {
    file_line { $pkg_name:
      ensure            => $pkg_status,
      path              => '/etc/yum/pluginconf.d/versionlock.list',
      line              => "${epoch}:${pkg_name}-${pkg_version}.${arch}",
      match             => "^${epoch}:${pkg_name}-(\\d)",
      require           => Package[$version_lock_package],
      notify            => Exec["clean_expire_cache_${module_name}_${pkg_name}"],
      match_for_absence => true,
      replace           => $replace;
    }
  }

  exec { "clean_expire_cache_${module_name}_${pkg_name}":
    command     => 'yum clean expire-cache',
    path        => ['/bin', '/usr/bin'],
    refreshonly => true;
  }

  # to handle multiple packages install or duplicates: see PUP-1061
  unless any2bool($pin_only) {
    package { $pkg_name:
      ensure  => $pkg_version,
      require => Exec["clean_expire_cache_${module_name}_${pkg_name}"];
    }
  }
}
# vim:ts=2:sw=2
