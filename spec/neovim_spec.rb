require "fileutils"
require "socket"

RSpec.describe Neovim do
  describe ".ui" do
    shared_context :event_handling do
      let(:pipe) { IO.pipe }
      let(:rd) { pipe[0] }
      let(:wr) { pipe[1] }

      let(:events) do
        Enumerator.new do |enum|
          Neovim.ui do |ui|
            ui.dimensions = [10, 10]

            ui.backend(&backend_config)

            ui.frontend do |frontend|
              frontend.attach(rd)
            end

            ui.on(:redraw) do |event|
              enum.yield(:redraw, event)
            end

            ui.on(:redraw, :resize) do |event|
              enum.yield(:redraw_resize, event)
            end

            ui.on(:input) do |event|
              enum.yield(:input, event)
            end

            ui.on(:input, :j) do |event|
              enum.yield(:input_j, event)
            end
          end.run
        end
      end

      it "yields redraw events" do
        expect(events).to be_any do |type, event|
          type == :redraw &&
            event.name == :resize &&
            event.arguments == [12, 10]
        end
      end

      it "yields redraw events by name" do
        expect(events).to be_any do |type, event|
          type == :redraw_resize &&
            event.name == :resize &&
            event.arguments == [12, 10]
        end
      end

      it "yields input events" do
        wr.print("j")

        expect(events).to be_any do |type, event|
          type == :input &&
            event.name == :input &&
            event.arguments == ["j"]
        end
      end

      it "yields input events by key" do
        wr.print("j")

        expect(events).to be_any do |type, event|
          type == :input_j &&
            event.name == :input &&
            event.arguments == ["j"]
        end
      end

      it "forwards keystrokes to nvim" do
        wr.print("i")

        expect(events).to be_any do |type, event|
          type == :redraw &&
            event.name == :mode_change &&
            event.arguments.include?("insert")
        end
      end
    end

    describe "child backend" do
      include_context :event_handling do
        let(:backend_config) do
          lambda do |backend|
            backend.attach_child(["nvim", "-u", "NONE", "--embed"])
          end
        end
      end
    end

    describe "unix socket backend" do
      include_context :event_handling do
        around do |spec|
          nvim_pid = spawn(
            {"NVIM_LISTEN_ADDRESS" => socket_path},
            "nvim", "-u", "NONE", "--headless",
            [:out, :err] => File::NULL
          )

          begin
            begin
              Socket.unix(socket_path).close
            rescue Errno::ENOENT, Errno::ECONNREFUSED
              retry
            end

            spec.run
          ensure
            Process.kill(:KILL, nvim_pid)
            Process.waitpid(nvim_pid)
          end
        end

        let(:socket_path) do
          "/tmp/nvim-#{$$}.sock".tap do |path|
            FileUtils.rm_f(path)
          end
        end


        let(:backend_config) do
          lambda do |backend|
            backend.attach_unix(socket_path)
          end
        end
      end
    end

    describe "tcp socket backend" do
      include_context :event_handling do
        around do |spec|
          nvim_pid = spawn(
            {"NVIM_LISTEN_ADDRESS" => "#{host}:#{port}"},
            "nvim", "-u", "NONE", "--headless",
            [:out, :err] => File::NULL
          )

          begin
            begin
              Socket.tcp(host, port).close
            rescue Errno::ECONNREFUSED
              retry
            end

            spec.run
          ensure
            Process.kill(:KILL, nvim_pid)
            Process.waitpid(nvim_pid)
          end
        end

        let(:host) { "127.0.0.1" }

        let(:port) do
          server = TCPServer.new(host, 0)

          begin
            server.addr[1]
          ensure
            server.close
          end
        end

        let(:backend_config) do
          lambda do |backend|
            backend.attach_tcp(host, port)
          end
        end
      end
    end
  end
end
