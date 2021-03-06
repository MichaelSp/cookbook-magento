# coding: utf-8
define :magento_database do

  include_recipe 'mysql::server'
  include_recipe 'mysql::client'
  include_recipe 'mysql-chef_gem'

  execute 'mysql-install-mage-privileges' do
    command <<-EOH
    /usr/bin/mysql -u root -p#{node[:mysql][:server_root_password]} < \
    /etc/mysql/mage-grants.sql
    EOH
    action :nothing
  end

  template '/etc/mysql/mage-grants.sql' do
    path '/etc/mysql/mage-grants.sql'
    source 'grants.sql.erb'
    owner 'root'
    group 'root'
    mode 0600
    variables(database: node[:magento][:db])
    notifies :run, resources(execute: 'mysql-install-mage-privileges'),
             :immediately
  end

  execute "create #{node[:magento][:db][:database]} database" do
    command <<-EOH
    /usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} \
    create #{node[:magento][:db][:database]}
    EOH
    not_if do
      require 'rubygems'
      Gem.clear_paths
      require 'mysql'
      m = Mysql.new('localhost', 'root', node[:mysql][:server_root_password])
      m.list_dbs.include?(node[:magento][:db][:database])
    end
  end

  # Save node data after writing the MYSQL root password, so that a failed
  # chef-client run that gets this far doesn't cause an unknown password to get
  # applied to the box without being saved in the node data.
  unless Chef::Config[:solo]
    ruby_block 'save node data' do
      block do
        node.save
      end
      action :create
    end
  end

end
