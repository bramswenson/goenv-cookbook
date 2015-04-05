#
# Cookbook Name:: goenv
# Library:: mixin_goenv
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

require 'chef/mixin/shell_out'

class Chef
  module Mixin
    module Goenv
      include Chef::Mixin::ShellOut

      def goenv_command(cmd, options = {})
        unless goenv_installed?
          Chef::Log.error("goenv is not yet installed. Unable to run " +
                          "goenv_command:`#{cmd}`. Are you trying to use " +
                          "`goenv_command` at the top level of your recipe? " +
                          "This is known to cause this error")
          raise "goenv not installed. Can't run goenv_command"
        end

        default_options = {
          :user => node[:goenv][:user],
          :group => node[:goenv][:group],
          :cwd => goenv_root_path,
          :env => {
            'GOENV_ROOT' => goenv_root_path
          },
          :timeout => 3600
        }
        if patch = options.delete(:patch)
          Chef::Log.info("Patch found at: #{patch}")
          unless filterdiff_installed?
            Chef::Log.error("Cannot find filterdiff. Please install patchutils to be able to use patches.")
            raise "Cannot find filterdiff. Please install patchutils to be able to use patches."
          end
          shell_out("curl -fsSL #{patch} | filterdiff -x ChangeLog | #{goenv_bin_path}/goenv #{cmd}", Chef::Mixin::DeepMerge.deep_merge!(options, default_options))
        else
          shell_out("#{goenv_bin_path}/goenv #{cmd}", Chef::Mixin::DeepMerge.deep_merge!(options, default_options))
        end
      end

      def goenv_installed?
        out = shell_out("ls #{goenv_bin_path}/goenv")
        out.exitstatus == 0
      end

      def go_version_installed?(version)
        out = goenv_command("prefix", :env => { 'GOENV_VERSION' => version })
        out.exitstatus == 0
      end

      def filterdiff_installed?
        out = shell_out("which filterdiff")
        out.exitstatus == 0
      end

      def goenv_global_version?(version)
        out = goenv_command("global")
        unless out.exitstatus == 0
          raise Chef::Exceptions::ShellCommandFailed, "\n" + out.format_for_exception
        end

        global_version = out.stdout.chomp
        global_version == version
      end

      def gem_binary_path_for(version)
        "#{goenv_prefix_for(version)}/bin/gem"
      end

      def goenv_prefix_for(version)
        out = goenv_command("prefix", :env => { 'GOENV_VERSION' => version })

        unless out.exitstatus == 0
          raise Chef::Exceptions::ShellCommandFailed, "\n" + out.format_for_exception
        end

        prefix = out.stdout.chomp
      end

      def goenv_bin_path
        ::File.join(goenv_root_path, "bin")
      end

      def goenv_shims_path
        ::File.join(goenv_root_path, "shims")
      end

      def goenv_root_path
        node[:goenv][:root_path]
      end

      # Ensures $HOME is temporarily set to the given user. The original
      # $HOME is preserved and re-set after the block has been yielded
      # to.
      #
      # This is a workaround for CHEF-3940. TL;DR Certain versions of
      # `git` misbehave if configuration is inaccessible in $HOME.
      #
      # More info here:
      #
      #   https://github.com/git/git/commit/4698c8feb1bb56497215e0c10003dd046df352fa
      #
      def with_home_for_user(username, &block)

        time = Time.now.to_i

        ruby_block "set HOME for #{username} at #{time}" do
          block do
            ENV['OLD_HOME'] = ENV['HOME']
            ENV['HOME'] = begin
              require 'etc'
              Etc.getpwnam(username).dir
            rescue ArgumentError # user not found
              "/home/#{username}"
            end
          end
        end

        yield

        ruby_block "unset HOME for #{username} #{time}" do
          block do
            ENV['HOME'] = ENV['OLD_HOME']
          end
        end
      end
    end
  end
end

Chef::Recipe.send(:include, Chef::Mixin::Goenv)
