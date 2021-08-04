# pin_package

#### Table of Contents

1. [Description](#description)
1. [Notes on this version](#notes-on-this-version)
1. [Usage](#usage)
    * [Pinning](#pinning)
    * [Unpinning](#unpinning)
    * [Mutual dependencies handling](#mutual-dependencies-handling)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

This module installs packages and forces version pinning on Debian and RedHat based distribution (Debian, Ubuntu, RedHat, CentOS...).

Pinned packages cannot be upgraded, unless they're unpinned or their version number is changed.

## Notes on this version

This is a transition version, where you can use either `pin_package` or `pin_package::pin`. The latter will be removed in the coming version.

## Usage

### Pinning

```puppet
pin_package::pin { 'apache':
  ensure => '0.5-40';
}
```

### Unpinning

```puppet
pin_package::pin { 'apache':
  ensure => '0.5-40',
  unpin  => true;
}
```

### Mutual dependencies handling

If you have mutual dependencies issues, you can set `pin_only` to `true`, and you use the `package` resource with `require` against pin_package define. Example:

```puppet
pin_package::pin { ['salt-minion', 'salt-common']:
  ensure   => $my_version,
  pin_only => true;
}

package { ['salt-minion', 'salt-common']:
  ensure  => $my_version,  # you can also use latest here, because you have already pinned
  require => Pin_package::Pin['salt-minion', 'salt-common'];
}
```

## Limitations

* only Debian/RedHat families are supported: Debian, Ubuntu, RedHat, CentOS...
* no test available

## Development

Feel free to make pull requests and/or open issues on [my GitHub Repository](https://github.com/maxadamo/pin_package)

Please make a pull request to add `$facts['os']['name']` (or tell me the string to add) for any missing OS, like as Scientific Linux or Oracle Linux

## Release Notes/Contributors

[Massimiliano Adamo](mailto:maxadamo@gmail.com)
