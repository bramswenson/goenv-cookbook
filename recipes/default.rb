#
# Cookbook Name:: goenv
# Recipe:: default
#
# Author:: Bram Swenson
#
# Copyright 2015, Bram Swenson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.set[:goenv][:root] = goenv_root_path

case node[:platform]
when "ubuntu", "debian"
  include_recipe "apt"
end

include_recipe "build-essential::default"
include_recipe "git::default"
package "curl"

case node[:platform]
when "redhat", "centos", "amazon", "oracle"
  package "openssl-devel"
  package "zlib-devel"
  package "gcc"
  package "glibc-devel"
when "ubuntu", "debian"
  package "libc6-dev"
  package "automake"
  package "libtool"
  package "openssl"
  package 'libssl-dev'
end

group node[:goenv][:group] do
  members node[:goenv][:group_users] if node[:goenv][:group_users]
end

user node[:goenv][:user] do
  shell "/bin/bash"
  group node[:goenv][:group]
  supports :manage_home => node[:goenv][:manage_home]
  home node[:goenv][:user_home]
end

directory node[:goenv][:root] do
  owner node[:goenv][:user]
  group node[:goenv][:group]
  mode "2775"
  recursive true
end

with_home_for_user(node[:goenv][:user]) do

  git node[:goenv][:root] do
    repository node[:goenv][:git_repository]
    reference node[:goenv][:git_revision]
    user node[:goenv][:user]
    group node[:goenv][:group]
    action :sync

    notifies :create, "template[/etc/profile.d/goenv.sh]", :immediately
  end

end

template "/etc/profile.d/goenv.sh" do
  source "goenv.sh.erb"
  mode "0644"
  variables(
    :goenv_root => node[:goenv][:root],
  )

  notifies :create, "ruby_block[initialize_goenv]", :immediately
end

ruby_block "initialize_goenv" do
  block do
    ENV['GOENV_ROOT'] = node[:goenv][:root]
    ENV['PATH'] = "#{node[:goenv][:root]}/bin:#{node[:goenv][:root]}/shims:#{ENV['PATH']}"
  end

  action :nothing
end

# goenv init creates these directories as root because it is called
# from /etc/profile.d/goenv.sh But we want them to be owned by goenv
%w{shims versions plugins}.each do |dir_name|
  directory "#{node[:goenv][:root]}/#{dir_name}" do
    owner node[:goenv][:user]
    group node[:goenv][:group]
    mode "2775"
    action [:create]
  end
end
