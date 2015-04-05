#
# Cookbook Name:: goenv
# Provider:: go
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

include Chef::Mixin::Goenv

action :install do
  resource_descriptor = "goenv_go[#{new_resource.name}] (version #{new_resource.go_version})"
  if !new_resource.force && go_version_installed?(new_resource.go_version)
    Chef::Log.debug "#{resource_descriptor} is already installed so skipping"
  else
    Chef::Log.info "#{resource_descriptor} is building, this may take a while..."

    start_time = Time.now
    #out = new_resource.patch ?
    #  goenv_command("install --patch #{new_resource.go_version}", patch: new_resource.patch) :
    #  goenv_command("install #{new_resource.go_version}")
    #
    #unless out.exitstatus == 0
    #  raise Chef::Exceptions::ShellCommandFailed, "\n" + out.format_for_exception
    #end

    Chef::Log.debug("#{resource_descriptor} build time was #{(Time.now - start_time)/60.0} minutes.")

    chmod_options = {
      user: node[:goenv][:user],
      group: node[:goenv][:group],
      cwd: goenv_root_path
    }

    unless Chef::Platform.windows?
      shell_out("chmod -R 0775 versions/#{new_resource.go_version}", chmod_options)
      shell_out("find versions/#{new_resource.go_version} -type d -exec chmod +s {} \\;", chmod_options)
    end

    new_resource.updated_by_last_action(true)
  end

  if new_resource.global && !goenv_global_version?(new_resource.name)
    Chef::Log.info "Setting #{resource_descriptor} as the goenv global version"
    out = goenv_command("global #{new_resource.go_version}")
    unless out.exitstatus == 0
      raise Chef::Exceptions::ShellCommandFailed, "\n" + out.format_for_exception
    end
    new_resource.updated_by_last_action(true)
  end
end
