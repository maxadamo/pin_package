# == Define: pin_package::version_lock
#
# This module is run only from pin_package
#
define pin_package::version_lock (
  $pkg_name,
  $epoch,
  $pkg_status,
  $pkg_version,
  $pin_only,
  $arch
) {

  assert_private("this define is intended to be called only within ${module_name}")

  if $pkg_status == 'absent' { $replace = false } else { $replace = true }

  if $facts['os']['release']['major'] == '8' {
    file_line { $pkg_name:
      ensure            => $pkg_status,
      path              => '/etc/dnf/plugins/versionlock.list',
      line              => "${pkg_name}-${epoch}:${pkg_version}.${arch}",
      match             => "^${pkg_name}-${epoch}:(\\d)",
      require           => Package['python3-dnf-plugin-versionlock'],
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
      require           => Package['yum-plugin-versionlock'],
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
