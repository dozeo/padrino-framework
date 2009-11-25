module Padrino
  module Tasks
    module Adapter

      class << self

        ADAPTERS = %w[thin mongrel webrick]

        # Start for the given options a rackup handler
        def start(options)

          ENV["PADRINO_ENV"] ||= options.environment.to_s

          boot = options.chdir ? File.join(options.chdir, options.boot) : options.boot
          unless File.exist?(boot)
            puts "=> Could not find boot file: #{boot.inspect} !!!"
            exit
          end
          require boot

          puts "=> Padrino/#{Padrino.version} has taken the stage #{options.environment} on port #{options.port}"

          if options.daemonize?

            stop # Need to stop a process if it exists

            fork do
              Process.setsid
              exit if fork
              File.umask 0000
              puts "=> Padrino server has been daemonized with pid #{Process.pid}"
              STDIN.reopen "/dev/null"
              STDOUT.reopen "/dev/null", "a"
              STDERR.reopen STDOUT

              FileUtils.mkdir_p("tmp/pids") unless File.exist?("tmp/pids")
              pid = "tmp/pids/server.pid"

              if pid
                File.open(pid, 'w'){ |f| f.write("#{Process.pid}") }
                at_exit { File.delete(pid) if File.exist?(pid) }
              end

              Padrino.run!(options.host, options.port, options.adapter)

            end
          else
            Padrino.run!(options.host, options.port, options.adapter)
          end
        end

        # Method that stop (if exist) a running Padrino.application
        def stop
          if File.exist?("tmp/pids/server.pid")
            pid = File.read("tmp/pids/server.pid").to_i
            print "=> Sending SIGTERM to process with pid #{pid} wait "
            Process.kill(15, pid) rescue nil
            1.step(5) { |i| sleep i; print "."; $stdout.flush }
            puts " done."
          end
        end

      end
    end
  end
end