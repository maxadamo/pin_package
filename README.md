# pin_package

#### Table of Contents

1. [Description](#description)
1. [Usage](#usage)
    * [Pinning](#pinning)
    * [Unpinning](#unpinning)
    * [Mutual dependency loop](#mutual-dependency-loop)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

This module force packages pinning on Ubuntu and CentOS.

Pinned packages cannot be upgraded, unless they're unpinned or their version is changed.

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

### Mutual dependency loop

If you have mutual dependencies issues, you can set `pin_only` to `true`, and you use
the `package` resource with `require` against pin_package define. Example:

```puppet
pin_package::pin { ['salt-minion', 'salt-common']:
  ensure => $my_version,
  pin_only  => true;
}

package { ['salt-minion', 'salt-common']:
  ensure  => $my_version,  # you could also use latest here, because you have already pinned
  require => Pin_package::Pin['salt-minion', 'salt-common'];
}
```

## Limitations

* only Debian/RedHat families are supported

## Development

Feel free to make pull requests and/or open issues on [my GitHub Repository](https://github.com/maxadamo/pin_package)

## Release Notes/Contributors

[Massimiliano Adamo](mailto:maxadamo@gmail.com)
