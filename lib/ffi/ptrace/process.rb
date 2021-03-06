require 'ffi/ptrace/text'
require 'ffi/ptrace/data'
require 'ffi/ptrace/user'
require 'ffi/ptrace/user_regs'
require 'ffi/ptrace/user_fpregs'
require 'ffi/ptrace/ptrace'

module FFI
  module PTrace
    class Process

      # The PID of the process
      attr_reader :pid

      # The `text` memory space
      attr_reader :text

      # The `data` memory space
      attr_reader :data

      # The `user-land` arguments memory space.
      attr_reader :user

      #
      # Creates a new Process with the given `pid`.
      #
      # @param [Integer] pid
      #   The ID of the process.
      #
      def initialize(pid)
        @pid = pid

        @text = Text.new(self)
        @data = Data.new(self)
        @user = User.new(self)
      end

      #
      # Retrieves a word at the address, in the `.text` section.
      #
      # @param [Integer] addr
      #   The address to peek at.
      #
      # @return [Integer]
      #   The word at the given address.
      #
      def peek_text(addr)
        ptrace(:ptrace_peektext,FFI::Pointer.new(addr),nil)
      end

      #
      # Retrieves a word at the address, in the `.data` section.
      #
      # @param [Integer] addr
      #   The address to peek at.
      #
      # @return [Integer]
      #   The word at the given address.
      #
      def peek_data(addr)
        ptrace(:ptrace_peekdata,FFI::Pointer.new(addr),nil)
      end

      #
      # Retrieves a word at the address, in user memory.
      #
      # @param [Integer] addr
      #   The address to peek at.
      #
      # @return [Integer]
      #   The word at the given address.
      #
      def peek_user(offset)
        ptrace(:ptrace_peekuser,FFI::Pointer.new(offset),nil)
      end

      #
      # Sets the data at the given address, in the `.text` section.
      #
      # @param [Integer] addr
      #   The address to poke at.
      #
      # @param [Integer] data
      #   The data to set.
      #
      def poke_text(addr,data)
        ptrace(:ptrace_poketext,FFI::Pointer.new(addr),data)
      end

      #
      # Sets the data at the given address, in the `.data` section.
      #
      # @param [Integer] addr
      #   The address to poke at.
      #
      # @param [Integer] data
      #   The data to set.
      #
      def poke_data(addr,data)
        ptrace(:ptrace_pokedata,FFI::Pointer.new(addr),data)
      end

      #
      # Sets the data at the given address, in user memory.
      #
      # @param [Integer] addr
      #   The address to poke at.
      #
      # @param [Integer] data
      #   The data to set.
      #
      def poke_user(offset,data)
        ptrace(:ptrace_pokeuser,FFI::Pointer.new(offset),data)
      end

      #
      # Causes the process to continue executing.
      #
      def continue!
        ptrace(:ptrace_cont)
      end

      #
      # Kills the process.
      #
      def kill!
        ptrace(:ptrace_kill)
      end

      #
      # Causes the process to pause after every instruction.
      #
      def single_step!
        ptrace(:ptrace_singlestep)
      end

      #
      # Reads the values within the registers.
      #
      # @return [UserRegs]
      #   The current registers of the process.
      #
      def regs
        regs = UserRegs.new

        ptrace(:ptrace_getregs,nil,regs)
        return regs
      end

      #
      # Writes values to the registers.
      #
      # @param [UserRegs] new_regs
      #   The new register values to write.
      #
      # @return [UserRegs]
      #   The written registers.
      #
      def regs=(new_regs)
        ptrace(:ptrace_setregs,nil,new_regs)
        return new_regs
      end

      #
      # Reads the values within the floating-point registers.
      #
      # @return [UserFPRegs]
      #   The current floating-point registers of the process.
      #
      def fp_regs
        fp_regs = UserFPRegs.new

        ptrace(:ptrace_getfpregs,nil,fp_regs)
        return fp_regs
      end

      #
      # Writes values to the floating-point registers.
      #
      # @param [UserFPRegs] new_fp_regs
      #   The new floating-point register values to write.
      #
      # @return [UserFPRegs]
      #   The written floating-point registers.
      #
      def fp_regs=(new_fp_regs)
        ptrace(:ptrace_getfpregs,nil,new_fp_regs)
        return fp_regs
      end

      #
      # Attach to the process.
      #
      def attach!
        ptrace(:ptrace_attach)
      end

      #
      # Detaches from the process.
      #
      def detach!
        ptrace(:ptrace_detach)
      end

      #
      # @note
      #  Not implemented.
      #
      def fpx_regs
        raise(RuntimeError,"#{self.class}#fpx_regs not implemented",caller)
      end

      #
      # @note
      #  Not implemented.
      #
      def fpx_regs=(new_regs)
        raise(RuntimeError,"#{self.class}#fpx_regs= not implemented",caller)
      end

      #
      # Causes the process to pause after every system call.
      #
      def syscall_step!
        ptrace(:ptrace_syscall)
      end

      #
      # Sets the ptrace options.
      #
      # @param [Integer] new_options
      #   The ptrace option flags.
      #
      def options=(new_options)
        ptrace(:ptrace_setoptions,nil,new_options)
      end

      #
      # @note
      #  Not implemented.
      #
      def event_mesg
        raise(RuntimeError,"#{self.class}#event_mesg not implemented",caller)
      end

      #
      # @note
      #  Not implemented.
      #
      def signal_info
        raise(RuntimeError,"#{self.class}#signal_info not implemented",caller)
      end

      #
      # @note
      #  Not implemented.
      #
      def signal_info=(new_info)
        raise(RuntimeError,"#{self.class}#signal_info= not implemented",caller)
      end

      protected

      #
      # Calls `ptrace` on the process.
      #
      # @param [Symbol] request
      #   The requested `ptrace` function.
      #
      # @param [Integer] addr
      #   The optional address.
      #
      # @param [FFI::MemoryPointer, Integer] data
      #   The optional data.
      #
      # @return [Integer]
      #   The return value from `ptrace`.
      #
      # @raise [Errno::EACCESS]
      #   The process is not allowed to be traced.
      #
      # @raise [RuntimeError]
      #   Either the process no longer exists or is already being traced.
      #
      # @raise [IOError]
      #   The `ptrace` request was invalid or the memory address was invalid.
      #
      def ptrace(request,addr=nil,data=nil)
        ret = PTrace.ptrace(request,@pid,addr,data)

        if ret == -1
          case PTrace.errno
          when PTrace::EPERM
            raise(Errno::EACCESS,"The requested process (#{@pid}) couldn't be traced. Permission denied")
          when PTrace::ESRCH
            raise(RuntimeError,"The requested process (#{@pid}) doesn't exist, not being traced or not stopped")
          when PTrace::EIO
            raise(IOError,"The ptrace request was invalid or read/write was made from/to invalid area of memory")
          end
        end

        return ret
      end
    end
  end
end
