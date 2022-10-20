# frozen_string_literal: true

require 'spec_helper'

describe 'graphql::puppetserver' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it {
        is_expected.to contain_package('graphql-client').with({
                                                                'ensure' => 'present',
                                                                'provider' => 'puppetserver_gem',
                                                              })
      }
    end
  end
end
