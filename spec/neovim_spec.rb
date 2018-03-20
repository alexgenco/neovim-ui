require "fileutils"
require "socket"
require "timeout"

RSpec.describe Neovim do
  describe ".ui" do
    shared_context :event_handling do
      let(:pipe) { IO.pipe }
      let(:rd) { pipe[0] }
      let(:wr) { pipe[1] }
      let(:fiber) { Fiber.new { ui.run } }

      let(:ui) do
        Neovim.ui do |ui|
          ui.dimensions = [10, 10]

          ui.backend(&backend_config)

          ui.frontend do |frontend|
            frontend.attach(rd)
          end

          ui.on(:redraw) do |message|
            Fiber.yield(:redraw, message)
          end

          ui.on(:input) do |key|
            Fiber.yield(:input, key)
          end
        end
      end

      it "yields redraw events" do
        2.times do
          type, event = fiber.resume
          expect(type).to eq(:redraw)
          expect(event.method_name).to eq("redraw")
        end
      end

      it "yields input events" do
        2.times { fiber.resume }

        wr.print("i")

        type, key = fiber.resume
        expect(type).to eq(:input)
        expect(key).to eq("i")
      end

      it "forwards keystrokes to nvim" do
        2.times { fiber.resume }

        wr.print("i"); fiber.resume

        type, event = fiber.resume
        expect(type).to eq(:redraw)
        expect(event.method_name).to eq("redraw")
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
