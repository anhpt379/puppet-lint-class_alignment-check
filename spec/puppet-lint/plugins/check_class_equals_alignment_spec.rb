require 'spec_helper'

describe 'class_equals_alignment' do
  let(:msg) { 'indentation of = is not properly aligned (expected in column %d, but found it in column %d)' }

  context 'with fix disabled' do
    context 'selectors inside a resource' do
      let(:code) do
        <<-END
          class foo (
            $ensure  = $ensure,
            $require = $ensure ? {
              present => Class['tomcat::install'],
              absent  => undef;
            },
            $foo     = bar,
          ) {}
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selectors in the middle of a resource' do
      let(:code) do
        <<-END
          class foo (
            $ensure = $ensure ? {
              present => directory,
              absent  => undef,
            },
            $owner  = 'tomcat6',
          ) {}
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selector inside a resource' do
      let(:code) do
        <<-END
          $ensure = $ensure ? {
            present => directory,
            absent  => undef,
          },
          $owner  = 'foo4',
          $group  = 'foo4',
          $mode   = '0755',
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selector inside a hash inside a resource' do
      let(:code) do
        <<-END
          $server = {
            ensure => ensure => $ensure ? {
              present => directory,
              absent  => undef,
            },
            ip     => '192.168.1.1'
          },
          $owner  = 'foo4',
          $group  = 'foo4',
          $mode   = '0755',
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'nested hashes with correct indentation' do
      let(:code) do
        <<-END
          class lvs::base (
            $virtualeservers = {
              '192.168.2.13' => {
                vport        => '11025',
                service      => 'smtp',
                scheduler    => 'wlc',
                protocol     => 'tcp',
                checktype    => 'external',
                checkcommand => '/path/to/checkscript',
                real_servers => {
                  'server01' => {
                    real_server => '192.168.2.14',
                    real_port   => '25',
                    forwarding  => 'masq',
                  },
                  'server02' => {
                    real_server => '192.168.2.15',
                    real_port   => '25',
                    forwarding  => 'masq',
                  }
                }
              }
            }
          ) {}
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'single resource with a misaligned =' do
      let(:code) do
        <<-END
          class foo (
            $foo = 1,
            $bar = 2,
            $gronk = 3,
            $baz  = 4,
            $meh = 5,
          ) {}
        END
      end

      it 'should detect four problems' do
        expect(problems).to have(4).problems
      end

      it 'should create four warnings' do
        expect(problems).to contain_warning(format(msg, 20, 18)).on_line(2).in_column(18)
        expect(problems).to contain_warning(format(msg, 20, 18)).on_line(3).in_column(18)
        expect(problems).to contain_warning(format(msg, 20, 19)).on_line(5).in_column(19)
        expect(problems).to contain_warning(format(msg, 20, 18)).on_line(6).in_column(18)
      end
    end

    context 'complex resource with a misaligned =' do
      let(:code) do
        <<-END
          class foo (
            $foo = 1,
            $bar   = $baz ? {
              gronk => 2,
              meh => 3,
            },
            $meep = 4,
            $bah= 5,
          ) {}
        END
      end

      it 'should detect three problems' do
        expect(problems).to have(3).problems
      end

      it 'should create three warnings' do
        expect(problems).to contain_warning(format(msg, 19, 18)).on_line(2).in_column(18)
        expect(problems).to contain_warning(format(msg, 19, 20)).on_line(3).in_column(20)
        expect(problems).to contain_warning(format(msg, 19, 17)).on_line(8).in_column(17)
      end
    end

    context 'resource with unaligned = in commented line' do
      let(:code) do
        <<-END
          class foo (
            $ensure = directory,
            # $purge = true,
          ) {}
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multiline resource with a single line of params' do
      let(:code) do
        <<-END
          class mymodule::do_thing (
            $whatever = 'bar', $one = 'two',
          ) {}
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'resource with aligned = too far out' do
      let(:code) do
        <<-END
          class foo (
            $ensure  = file,
            $mode    = '0444',
          ) {}
        END
      end

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should create 2 warnings' do
        expect(problems).to contain_warning(format(msg, 21, 22)).on_line(2).in_column(22)
        expect(problems).to contain_warning(format(msg, 21, 22)).on_line(3).in_column(22)
      end
    end

    context 'resource with multiple params where one is an empty hash' do
      let(:code) do
        <<-END
          class foo (
            $a = true,
            $b = {
            }
          ) {}
        END
      end

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multiline resource with multiple params on a line' do
      let(:code) do
        <<-END
          class test (
            $a = 'foo', $bb = 'bar',
            $ccc = 'baz',
          ) {}
        END
      end

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should create 2 warnings' do
        expect(problems).to contain_warning(format(msg, 18, 16)).on_line(2).in_column(16)
        expect(problems).to contain_warning(format(msg, 18, 29)).on_line(2).in_column(29)
      end
    end
  end

  context 'with fix enabled' do
    before do
      PuppetLint.configuration.fix = true
    end

    after do
      PuppetLint.configuration.fix = false
    end

    context 'single resource with a misaligned =' do
      let(:code) do
        <<-END
          class foo (
            $foo = 1,
            $bar = 2,
            $gronk = 3,
            $baz  = 4,
            $meh = 5,
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class foo (
            $foo   = 1,
            $bar   = 2,
            $gronk = 3,
            $baz   = 4,
            $meh   = 5,
          ) {}
        END
      end

      it 'should detect four problems' do
        expect(problems).to have(4).problems
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(format(msg, 20, 18)).on_line(2).in_column(18)
        expect(problems).to contain_fixed(format(msg, 20, 18)).on_line(3).in_column(18)
        expect(problems).to contain_fixed(format(msg, 20, 19)).on_line(5).in_column(19)
        expect(problems).to contain_fixed(format(msg, 20, 18)).on_line(6).in_column(18)
      end

      it 'should align the class_paramss' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'complex resource with a misaligned =' do
      let(:code) do
        <<-END
          class foo (
            $foo = 1,
            $bar  = $baz ? {
              gronk => 2,
              meh => 3,
            },
            $meep= 4,
            $bah = 5,
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class foo (
            $foo  = 1,
            $bar  = $baz ? {
              gronk => 2,
              meh => 3,
            },
            $meep = 4,
            $bah  = 5,
          ) {}
        END
      end

      it 'should detect three problems' do
        expect(problems).to have(3).problems
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(format(msg, 19, 18)).on_line(2).in_column(18)
        expect(problems).to contain_fixed(format(msg, 19, 18)).on_line(7).in_column(18)
        expect(problems).to contain_fixed(format(msg, 19, 18)).on_line(8).in_column(18)
      end

      it 'should align the class_paramss' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'resource with aligned = too far out' do
      let(:code) do
        <<-END
          class foo (
            $ensure  = file,
            $mode    = '0444',
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class foo (
            $ensure = file,
            $mode   = '0444',
          ) {}
        END
      end

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should create 2 warnings' do
        expect(problems).to contain_fixed(format(msg, 21, 22)).on_line(2).in_column(22)
        expect(problems).to contain_fixed(format(msg, 21, 22)).on_line(3).in_column(22)
      end

      it 'should realign the class_paramss with the minimum whitespace' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'resource with unaligned = and no whitespace between param and =' do
      let(:code) do
        <<-END
          class test (
            $param1 = 'foo',
            $param2= 'bar',
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class test (
            $param1 = 'foo',
            $param2 = 'bar',
          ) {}
        END
      end

      it 'should detect 1 problem' do
        expect(problems).to have(1).problem
      end

      it 'should fix the problem' do
        expect(problems).to contain_fixed(format(msg, 21, 20)).on_line(3).in_column(20)
      end

      it 'should add whitespace between the param and the class_params' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline resource with multiple params on a line' do
      let(:code) do
        <<-END
          class test (
            $a = 'foo', $bb = 'bar',
            $ccc = 'baz',
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class test (
            $a   = 'foo',
            $bb  = 'bar',
            $ccc = 'baz',
          ) {}
        END
      end

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should fix 2 problems' do
        expect(problems).to contain_fixed(format(msg, 18, 16)).on_line(2).in_column(16)
        expect(problems).to contain_fixed(format(msg, 18, 29)).on_line(2).in_column(29)
      end

      it 'should move the extra param onto its own line and realign' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline resource with multiple params on a line, extra one longer' do
      let(:code) do
        <<-END
          class test (
            $a = 'foo', $bbccc = 'bar',
            $ccc = 'baz',
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class test (
            $a     = 'foo',
            $bbccc = 'bar',
            $ccc   = 'baz',
          ) {}
        END
      end

      it 'should detect 2 problems' do
        expect(problems).to have(3).problems
      end

      it 'should fix 2 problems' do
        expect(problems).to contain_fixed(format(msg, 20, 16)).on_line(2).in_column(16)
        expect(problems).to contain_fixed(format(msg, 20, 32)).on_line(2).in_column(32)
        expect(problems).to contain_fixed(format(msg, 20, 18)).on_line(3).in_column(18)
      end

      it 'should move the extra param onto its own line and realign' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
