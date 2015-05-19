require 'spec_helper'
describe 'maw' do

  context 'with defaults for all parameters' do
    it { should contain_class('maw') }
  end
end
