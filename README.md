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
