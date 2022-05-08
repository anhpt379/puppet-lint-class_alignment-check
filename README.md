# puppet-lint-class_alignment-check

[![License](https://img.shields.io/github/license/anhpt379/puppet-lint-class_alignment-check.svg)](https://github.com/anhpt379/puppet-lint-class_alignment-check/blob/master/LICENSE)
[![Test](https://github.com/anhpt379/puppet-lint-class_alignment-check/actions/workflows/test.yml/badge.svg)](https://github.com/anhpt379/puppet-lint-class_alignment-check/actions/workflows/test.yml)
[![Release](https://github.com/anhpt379/puppet-lint-class_alignment-check/actions/workflows/release.yml/badge.svg)](https://github.com/anhpt379/puppet-lint-class_alignment-check/actions/workflows/release.yml)
[![codecov](https://codecov.io/gh/anhpt379/puppet-lint-class_alignment-check/branch/master/graph/badge.svg?token=2DI8JYJ8AZ)](https://codecov.io/gh/anhpt379/puppet-lint-class_alignment-check)
[![RubyGem Version](https://img.shields.io/gem/v/puppet-lint-class_alignment-check.svg)](https://rubygems.org/gems/puppet-lint-class_alignment-check)
[![RubyGem Downloads](https://img.shields.io/gem/dt/puppet-lint-class_alignment-check.svg)](https://rubygems.org/gems/puppet-lint-class_alignment-check)

A puppet-lint plugin to check and fix class params/equals alignment.

## Usage

This plugin provides 2 checks for puppet-lint:

- `class_params_alignment`
- `class_equals_alignment`

It supports `--fix` flag.

> Parameters to classes or defined types must be uniformly indented in two
> spaces from the title. The equals sign should be aligned.
>
> <https://puppet.com/docs/puppet/7/style_guide.html#style_guide_classes-param-indentation-alignment>

```puppet
class name (
  $var1    = 'default',
  $var2    = 'something else',
  $another = 'another default value',
) {

}
```

```puppet
class name (
  Boolean                        $broadcastclient = false,
  Optional[Stdlib::Absolutepath] $config_dir      = undef,
  Enum['running', 'stopped']     $service_ensure  = 'running',
  String                         $package_ensure  = 'present',
) {

}
```
