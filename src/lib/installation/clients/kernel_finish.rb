# ------------------------------------------------------------------------------
# Copyright (c) 2006-2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:
#  kernel_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Jiri Srain <jsrain@suse.cz>
#
# $Id$
#

module Yast
  class KernelFinishClient < Client
    def main
      textdomain "installation"

      Yast.import "ModulesConf"
      Yast.import "Kernel"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end

      Builtins.y2milestone("starting kernel_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      case @func
      when "Info"
        return {
          "steps" => 1,
          # progress step title
          "title" => _(
            "Updating kernel module dependencies..."
          ),
          "when"  => [:installation, :update, :autoinst]
        }
      when "Write"
        ModulesConf.Save(true)

        # on SGI Altix add fetchop and mmtimer to /etc/modules-load.d/*.conf
        if Ops.greater_than(SCR.Read(path(".target.size"), "/proc/sgi_sn"), 0)
          Builtins.y2milestone("found SGI Altix, adding fetchop and mmtimer")
          Kernel.AddModuleToLoad("fetchop")
          Kernel.AddModuleToLoad("mmtimer")
        end

        # Write list of modules to load after system gets up
        Kernel.SaveModulesToLoad
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("kernel_finish finished")
      deep_copy(@ret)
    end
  end
end
