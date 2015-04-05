#
# Cookbook Name:: goenv
# Provider:: execute
#
# Author:: Bram Swenson <bram@craniumisajar.com>
#

include Chef::Mixin::Goenv

def load_current_resource
  @path                         = [ goenv_shims_path, goenv_bin_path ] + new_resource.path + system_path
  @environment                  = new_resource.environment
  @environment["PATH"]          = @path.join(":")
  @environment["GOENV_ROOT"]    = goenv_root_path
  @environment["GOENV_VERSION"] = new_resource.go_version if new_resource.go_version

  new_resource.environment(@environment)
end

action :run do
  execute "eval \"$(goenv init -)\"" do
    environment new_resource.environment
  end

  execute new_resource.name do
    command     new_resource.command
    creates     new_resource.creates
    cwd         new_resource.cwd
    environment new_resource.environment
    group       new_resource.group
    returns     new_resource.returns
    timeout     new_resource.timeout
    user        new_resource.user
    umask       new_resource.umask
  end

  new_resource.updated_by_last_action(true)
end

private

  def system_path
    shell_out!("echo $PATH").stdout.chomp.split(':')
  end
