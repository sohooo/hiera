begin test_name "Lookup data with a scope"

  agents.each do |agent|

    teardown do
      apply_manifest_on agent, <<-PP
      file { '#{agent['hieradatadir']}':
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
      }
      file { '/etc/puppet/scope.yaml': ensure => absent }
      file { '/etc/puppet/scope.json': ensure => absent }
      PP
    end

    step 'Setup'
      apply_manifest_on agent, <<-PP
      file { '#{agent['hieradatadir']}/global.yaml':
        ensure  => present,
        content => "---
          http_port: 8080
          ntp_servers: ['0.ntp.puppetlabs.com', '1.ntp.puppetlabs.com']
          users:
            pete:
              uid: 2000
              gid: 2000
              shell: '/bin/bash'
            tom:
              uid: 2001
              gid: 2001
              shell: '/bin/bash'
        "
      }

      file { '#{agent['hieradatadir']}/production.yaml':
        ensure  => present,
        content => "---
          http_port: 9090
          monitor: enable
          ntp_servers: ['0.ntp.puppetlabs.com', '1.ntp.puppetlabs.com']
        "
      }

      file { '/etc/puppet/scope.yaml':
        ensure  => present,
        content => "---
          environment: production
        "
      }
      PP

    step "Try to lookup string data using a scope from a yaml file"
      on agent, hiera('monitor', '--yaml', '/etc/puppet/scope.yaml'),
        :acceptable_exit_codes => [0] do
        assert_output <<-OUTPUT
          STDOUT> enable
        OUTPUT
      end

    # TODO: Add a test for supplying scope from a json file.
    # We need to workout the requirement on the json gem.
    step "Try to lookup string data using a scope from a yaml file"

  end

end
