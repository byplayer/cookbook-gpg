# Encoding: utf-8

require_relative 'spec_helper'
require 'chef-vault'
$: << File.join(File.dirname(__FILE__), '../../..')
require 'libraries/helper_gpg_interface'
require 'libraries/helper_key_header'

describe 'gpg::lwrp:load_key_from_string' do
  include BswTech::ChefSpec::LwrpTestHelper

  def cookbook_under_test
    'bsw_gpg'
  end

  def lwrps_under_test
    'load_key_from_string'
  end

  %w(key_contents for_user).each do |attr_to_include|
    it "fails if we only supply #{attr_to_include}" do
      # arrange

      # act
      action = lambda {
        temp_lwrp_recipe <<-EOF
          bsw_gpg_load_key_from_string 'some key' do
            #{attr_to_include} 'value'
          end
        EOF
      }

      # assert
      expect(action).to raise_exception Chef::Exceptions::ValidationFailed
    end
  end

  it 'works properly when importing a secret key that is not already there' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    # noinspection RubyResolve
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq [{
                                           :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :username => 'root'
                                       }]
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'works properly when importing a public key that is not already there' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:public_key))

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'works properly when importing a key with multiple usernames that is not already there' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         usernames=['the username 1', 'the username 2'],
                                                         id='the id',
                                                         type=:public_key))

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'does not do anything if the correct public key is already there' do
    # arrange
    key = BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                      username='the username',
                                      id='the id',
                                      type=:public_key)
    stub_gpg_interface(current=[key], draft=key)

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to be_empty
    expect(@keytrusts_imported).to be_empty
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(false)
  end

  it 'does not do anything if a key with multiple usernames is already there' do
    # arrange
    key = BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                      usernames=['the username 1', 'the username 2'],
                                      id='the id',
                                      type=:public_key)
    stub_gpg_interface(current=[key], draft=key)

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to be_empty
    expect(@keytrusts_imported).to be_empty
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(false)
  end

  it 'does not do anything if the correct secret key is already there' do
    # arrange
    key = BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                      username='the username',
                                      id='the id',
                                      type=:secret_key)
    stub_gpg_interface(current=[key], draft=key)

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to be_empty
    expect(@keytrusts_imported).to be_empty
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(false)
  end

  it 'does update the key if a different public key is already there' do
    # arrange
    current_key = BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                              username='the username',
                                              id='the id',
                                              type=:public_key)
    new_key = BswTech::Gpg::KeyHeader.new(fingerprint='5D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username 2',
                                          id='the id',
                                          type=:public_key)
    stub_gpg_interface(current=[current_key], draft=new_key)

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'does update the key if a different secret key is already there' do
    # arrange
    current_key = BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                              username='the username',
                                              id='the id',
                                              type=:secret_key)
    new_key = BswTech::Gpg::KeyHeader.new(fingerprint='5D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username 2',
                                          id='the id',
                                          type=:secret_key)
    stub_gpg_interface(current=[current_key], draft=new_key)

    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq [{
                                           :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :username => 'root'
                                       }]
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'runs the commands as the proper user' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'someone_else'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'someone_else',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'someone_else'
                                  }]
    expect(@keytrusts_imported).to eq [{
                                           :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :username => 'someone_else'
                                       }]
  end

  it 'overwrites the existing public key for the user if the fingerprint has changed' do
    # arrange
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username',
                                          id='the id',
                                          type=:public_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:public_key))
    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_public => :default,
                                     :keyring_secret => :default,
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'overwrites an existing key with a single username and multiple usernames on the new key' do
    # arrange
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username',
                                          id='the id',
                                          type=:public_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         usernames=['the username', 'the username 2'],
                                                         id='the id',
                                                         type=:public_key))
    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
          for_user 'root'
        end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_public => :default,
                                     :keyring_secret => :default,
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'overwrites an existing key with multiple usernames and multiple usernames on the new key' do
    # arrange
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          usernames=['the username 2', 'the username 3'],
                                          id='the id',
                                          type=:public_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         usernames=['the username', 'the username 2'],
                                                         id='the id',
                                                         type=:public_key))
    # act
    temp_lwrp_recipe <<-EOF
            bsw_gpg_load_key_from_string 'some key' do
              key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
              for_user 'root'
            end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_public => :default,
                                     :keyring_secret => :default,
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'overwrites an existing key with multiple usernames and a single username on the new key' do
    # arrange
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          usernames=['the username 2', 'the username 3'],
                                          id='the id',
                                          type=:public_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         usernames='the username 2',
                                                         id='the id',
                                                         type=:public_key))
    # act
    temp_lwrp_recipe <<-EOF
                bsw_gpg_load_key_from_string 'some key' do
                  key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
                  for_user 'root'
                end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_public => :default,
                                     :keyring_secret => :default,
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'overwrites the existing secret key for the user if the fingerprint has changed' do
    # arrange
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username',
                                          id='the id',
                                          type=:secret_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'root'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_public => :default,
                                     :keyring_secret => :default,
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq [{
                                           :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :username => 'root'
                                       }]
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'allows specifying a custom keyring file with a public key' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:public_key))
    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
          for_user 'root'
          keyring_file_public 'something.gpg'
        end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => 'something.gpg',
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => 'something.gpg',
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    # Trustdb doesn't like trusting keys in non default keyrings
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'complains if a custom keyring is used with a secret key but a public keyring file is not specified' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    action = lambda {
      temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'root'
        keyring_file_secret 'something.gpg'
      end
      EOF
    }

    # act + assert
    expect(action).to raise_exception "bsw_gpg_load_key_from_string[some key] (lwrp_gen::default line 1) had an error: RuntimeError: keyring_file_secret is a custom file (something.gpg) but no keyring_file_public was specified.  It's not a good idea to import a private key without a public keyring to also import the associated public key!"
  end

  it 'complains if a custom keyring is used with a secret key but a secret keyring file is not specified' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    action = lambda {
      temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
          for_user 'root'
          keyring_file_public 'something.gpg'
        end
      EOF
    }

    # act + assert
    expect(action).to raise_exception 'bsw_gpg_load_key_from_string[some key] (lwrp_gen::default line 1) had an error: RuntimeError: keyring_file_public is a custom file (something.gpg) but no keyring_file_secret was specified.  Cannot import a private key without a secret keyring to put it in!'
  end

  it 'allows specifying a custom keyring file with a secret key' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
          for_user 'root'
          keyring_file_secret 'something.gpg'
          keyring_file_public 'something_pub.gpg'
        end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_secret => 'something.gpg',
                                           :keyring_public => 'something_pub.gpg',
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_secret => 'something.gpg',
                                      :keyring_public => 'something_pub.gpg',
                                      :username => 'root'
                                  }]
    # Trustdb doesn't like trusting keys in non default keyrings
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'removes a public key from only the custom keyring when a keyring is specified and removal is required' do
    # assert
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username',
                                          id='the id',
                                          type=:public_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:public_key))
    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PUBLIC KEY BLOCK-----'
        for_user 'root'
        keyring_file_public 'something.gpg'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => 'something.gpg',
                                           :keyring_secret => :default,
                                           :type => :public_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PUBLIC KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_public => 'something.gpg',
                                     :keyring_secret => :default,
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PUBLIC KEY BLOCK-----',
                                      :keyring_public => 'something.gpg',
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    # Trustdb doesn't like trusting keys in non default keyrings
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'removes a secret key from only the custom keyring when a keyring is specified and removal is required' do
    # arrange
    current = BswTech::Gpg::KeyHeader.new(fingerprint='6D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                          username='the username',
                                          id='the id',
                                          type=:secret_key)
    stub_gpg_interface(current=[current],
                       draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    # act
    temp_lwrp_recipe <<-EOF
      bsw_gpg_load_key_from_string 'some key' do
        key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
        for_user 'root'
        keyring_file_secret 'something.gpg'
        keyring_file_public 'something_pub.gpg'
      end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_secret => 'something.gpg',
                                           :keyring_public => 'something_pub.gpg',
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to eq [{
                                     :username => 'root',
                                     :keyring_secret => 'something.gpg',
                                     :keyring_public => 'something_pub.gpg',
                                     :key_header => current
                                 }]
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_secret => 'something.gpg',
                                      :keyring_public => 'something_pub.gpg',
                                      :username => 'root'
                                  }]
    # Trustdb doesn't like trusting keys in non default keyrings
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'tells the GPG interface to not force trustdb checks by default' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))

    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
          for_user 'root'
        end
    EOF

    # assert
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.disable_trust_db_check).to eq nil
  end

  it 'tells the GPG interface to disable trustdb checks if we tell it to' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))

    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
          for_user 'root'
          disable_trust_db_check true
        end
    EOF

    # assert
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.disable_trust_db_check).to eq true
    expect(@trustdb_suppress).to eq true
  end

  it 'tells the GPG interface to enable trustdb checks if we tell it to' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))

    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
          for_user 'root'
          keyring_file_secret 'foo.gpg'
          keyring_file_public 'foo_pub.gpg'
          disable_trust_db_check false
        end
    EOF

    # assert
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.disable_trust_db_check).to eq false
    expect(@trustdb_suppress).to eq false
  end

  it 'will not trust the newly imported key if we tell it so' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))

    # act
    temp_lwrp_recipe <<-EOF
          bsw_gpg_load_key_from_string 'some key' do
            key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
            for_user 'root'
            force_import_owner_trust false
          end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_public => :default,
                                           :keyring_secret => :default,
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    # noinspection RubyResolve
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_public => :default,
                                      :keyring_secret => :default,
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq []
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end

  it 'will trust newly imported keys into non-default keyrings if forced' do
    # arrange
    stub_gpg_interface(draft=BswTech::Gpg::KeyHeader.new(fingerprint='4D1CF3288469F260C2119B9F76C95D74390AA6C9',
                                                         username='the username',
                                                         id='the id',
                                                         type=:secret_key))
    # act
    temp_lwrp_recipe <<-EOF
        bsw_gpg_load_key_from_string 'some key' do
          key_contents '-----BEGIN PGP PRIVATE KEY BLOCK-----'
          for_user 'root'
          keyring_file_secret 'something.gpg'
          keyring_file_public 'something_pub.gpg'
          force_import_owner_trust true
        end
    EOF

    # assert
    expect(@current_key_checks).to eq([{
                                           :username => 'root',
                                           :keyring_secret => 'something.gpg',
                                           :keyring_public => 'something_pub.gpg',
                                           :type => :secret_key
                                       }])
    expect(@base64_used).to eq('-----BEGIN PGP PRIVATE KEY BLOCK-----')
    expect(@keys_deleted).to be_empty
    expect(@keys_imported).to eq [{
                                      :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                      :keyring_secret => 'something.gpg',
                                      :keyring_public => 'something_pub.gpg',
                                      :username => 'root'
                                  }]
    expect(@keytrusts_imported).to eq [{
                                           :base64 => '-----BEGIN PGP PRIVATE KEY BLOCK-----',
                                           :keyring_secret => 'something.gpg',
                                           :keyring_public => 'something_pub.gpg',
                                           :username => 'root'
                                       }]
    resource = @chef_run.find_resource 'bsw_gpg_load_key_from_string', 'some key'
    expect(resource.updated_by_last_action?).to eq(true)
  end
end
