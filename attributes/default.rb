#
# Cookbook Name:: goenv
# Attributes:: default
#
# Author:: Bram Swenson <bram@craniumisajar.com>
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

default[:goenv][:user]           = "goenv"
default[:goenv][:group]          = "goenv"
default[:goenv][:manage_home]    = true
default[:goenv][:group_users]    = Array.new
default[:goenv][:git_repository] = "https://github.com/alext/goenv.git"
default[:goenv][:git_revision]   = "master"
default[:goenv][:install_prefix] = "/opt"
default[:goenv][:root_path]      = "#{node[:goenv][:install_prefix]}/goenv"
default[:goenv][:user_home]      = "/home/#{node[:goenv][:user]}"
