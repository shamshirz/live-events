defmodule LiveEvent.ScanApp.ScanIntegrationTest do
  use ExUnit.Case

  alias LiveEvent.ScanApp.Aggregates.Scan

  alias LiveEvent.ScanApp.Commands.{
    StartScan,
    DiscoverDomains,
    DiscoverSubdomains,
    CompleteScan
  }

  describe "scan" do
    test "starts a scan" do
      # Start a scan - cmd -> event
      # Discover domains - cmd -> [event]
      # Discover subdomains - [cmd] -> [event]
      # Complete scan - cmd -> event
      scan_id = UUID.uuid4()
      domain = "example.com"
      associated_domains = ["example1.com"]
      subdomains = ["sub1.example.com", "sub2.example.com"]

      commands = [
        %StartScan{scan_id: scan_id, domain: domain},
        %DiscoverDomains{
          scan_id: scan_id,
          domain: domain,
          associated_domains: associated_domains
        },
        %DiscoverSubdomains{scan_id: scan_id, domain: domain, subdomains: subdomains},
        %DiscoverSubdomains{
          scan_id: scan_id,
          domain: hd(associated_domains),
          subdomains: subdomains
        },
        %CompleteScan{scan_id: scan_id}
      ]

      final_state =
        Enum.reduce(commands, %Scan{}, fn command, state ->
          {:ok, event} = Scan.execute(state, command)
          new_state = Scan.apply(state, event)
          new_state
        end)

      IO.inspect(final_state)
      assert false
    end
  end
end
