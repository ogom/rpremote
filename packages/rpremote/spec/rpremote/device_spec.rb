# frozen_string_literal: true

RSpec.describe Rpremote::Device do
  describe ".main_port" do
    it "selects CDC 0 from a three-port R2P2 device" do
      ports = %w[
        /dev/cu.usbmodem1101
        /dev/cu.usbmodem1103
        /dev/cu.usbmodem1105
      ]

      expect(described_class.main_port(nil, available_ports: ports)).to eq("/dev/cu.usbmodem1101")
    end

    it "selects CDC 0 from a two-port PicoRuby 3.4 R2P2 device" do
      ports = %w[
        /dev/cu.usbmodem1101
        /dev/cu.usbmodem1103
      ]

      expect(described_class.main_port(nil, available_ports: ports)).to eq("/dev/cu.usbmodem1101")
    end

    it "rejects multiple R2P2 devices" do
      ports = %w[
        /dev/cu.usbmodem1101
        /dev/cu.usbmodem1103
        /dev/cu.usbmodem1105
        /dev/cu.usbmodem2101
        /dev/cu.usbmodem2103
        /dev/cu.usbmodem2105
      ]

      expect { described_class.main_port(nil, available_ports: ports) }
        .to raise_error(described_class::MultipleDevicesError, /multiple R2P2 devices/)
    end

    it "reports when no port exists" do
      expect { described_class.main_port(nil, available_ports: []) }
        .to raise_error(described_class::NotFoundError, /not found/)
    end
  end
end
