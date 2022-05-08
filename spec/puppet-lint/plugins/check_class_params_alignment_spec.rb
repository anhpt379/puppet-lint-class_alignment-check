require 'spec_helper'

describe 'class_params_alignment' do
  let(:msg) { 'indentation of $ is not properly aligned (expected in column %d, but found it in column %d)' }

  context 'with fix disabled' do
    context 'with correct indentation' do
      let(:code) do
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

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'single resource with a misaligned $' do
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
        expect(problems).to contain_warning(format(msg, 13, 11)).on_line(3).in_column(11)
        expect(problems).to contain_warning(format(msg, 13, 11)).on_line(4).in_column(11)
        expect(problems).to contain_warning(format(msg, 13, 11)).on_line(5).in_column(11)
        expect(problems).to contain_warning(format(msg, 13, 12)).on_line(6).in_column(12)
      end
    end

    context 'complex resource with a misaligned $' do
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
        expect(problems).to contain_warning(format(msg, 13, 11)).on_line(3).in_column(11)
        expect(problems).to contain_warning(format(msg, 13, 15)).on_line(7).in_column(15)
        expect(problems).to contain_warning(format(msg, 13, 17)).on_line(8).in_column(17)
      end
    end

    context 'resource with unaligned $ in commented line' do
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

    context 'resource with aligned $ too far out' do
      let(:code) do
        <<-END
          class foo (
                $ensure  = file,
                $mode    = '0444',
          ) {}
        END
      end

      it 'should detect 0 problems' do
        expect(problems).to have(0).problems
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

      it 'should detect 0 problems' do
        expect(problems).to have(0).problems
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

    context 'single resource with a misaligned $' do
      let(:code) do
        <<-END
          class foo (
            $foo = 1,
              $bar = 2,
              $gronk = 3,
                $baz = 4,
          $meh = 5,
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class foo (
            $foo = 1,
            $bar = 2,
            $gronk = 3,
            $baz = 4,
            $meh = 5,
          ) {}
        END
      end

      it 'should detect four problems' do
        expect(problems).to have(4).problems
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(format(msg, 13, 15)).on_line(3).in_column(15)
        expect(problems).to contain_fixed(format(msg, 13, 15)).on_line(4).in_column(15)
        expect(problems).to contain_fixed(format(msg, 13, 17)).on_line(5).in_column(17)
        expect(problems).to contain_fixed(format(msg, 13, 11)).on_line(6).in_column(11)
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
          $bar = $baz ? {
              gronk => $a,
              meh => $b,
            },
          $meep= 4,
          $bah = 5,
          ) {}
        END
      end

      let(:fixed) do
        <<-END
          class foo (
            $foo = 1,
            $bar = $baz ? {
              gronk => $a,
              meh => $b,
            },
            $meep= 4,
            $bah = 5,
          ) {}
        END
      end

      it 'should detect three problems' do
        expect(problems).to have(3).problems
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(format(msg, 13, 11)).on_line(3).in_column(11)
        expect(problems).to contain_fixed(format(msg, 13, 11)).on_line(7).in_column(11)
        expect(problems).to contain_fixed(format(msg, 13, 11)).on_line(8).in_column(11)
      end

      it 'should align the class_paramss' do
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
            $a = 'foo', $bb = 'bar',
            $ccc = 'baz',
          ) {}
        END
      end

      it 'should detect 1 problem' do
        expect(problems).to have(1).problems
      end

      it 'should fix 1 problem' do
        expect(problems).to contain_fixed(format(msg, 13, 11)).on_line(3).in_column(11)
      end

      it 'should move the extra param onto its own line and realign' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline resource with inline variables' do
      let(:code) do
        <<-END
          class name (
            Boolean $key1 = false,
            Enum['never', 'allow', 'try', 'demand'] $key2,
          $materializer_version = $foo ? {
              default => "foo ${bar} baz ${gronk} qux 0.4.1-1.el${::facts['operatingsystemmajrelease']}"
          }) { }
        END
      end

      let(:fixed) do
        <<-END
          class name (
            Boolean                                 $key1 = false,
            Enum['never', 'allow', 'try', 'demand'] $key2,
                                                    $materializer_version = $foo ? {
              default => "foo ${bar} baz ${gronk} qux 0.4.1-1.el${::facts['operatingsystemmajrelease']}"
          }) { }
        END
      end

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should fix 2 problems' do
        expect(problems).to contain_fixed(format(msg, 53, 21)).on_line(2).in_column(21)
        expect(problems).to contain_fixed(format(msg, 53, 11)).on_line(4).in_column(11)
      end

      it 'should move the extra param onto its own line and realign' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
