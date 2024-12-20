defmodule LiveEvent.ScanApp.ScanIntegrationTest do
  use ExUnit.Case

  import Commanded.Assertions.EventAssertions, only: [assert_receive_event: 3]

  alias LiveEvent.ScanApp.Aggregates.Scan

  alias LiveEvent.ScanApp.Events.{
    DiscoverSubdomainsRequested,
    DiscoverSubdomainsSucceeded,
    ScanCompleted
  }

  alias LiveEvent.ScanApp.Commands.{
    StartScan,
    DiscoverDomainsSuccess,
    DiscoverSubdomainsSuccess,
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
        %DiscoverDomainsSuccess{
          scan_id: scan_id,
          associated_domains: associated_domains
        },
        %DiscoverSubdomainsSuccess{
          scan_id: scan_id,
          domain: hd(associated_domains),
          subdomains: subdomains
        },
        %DiscoverSubdomainsSuccess{
          scan_id: scan_id,
          domain: domain,
          subdomains: subdomains
        },
        %CompleteScan{scan_id: scan_id}
      ]

      {final_state, events} = process_commands(commands, %Scan{})

      assert %ScanCompleted{scan_id: ^scan_id} = hd(events)
    end
  end

  # We need to handle when the Multi is returned
  @spec process_commands(list(struct()), struct()) :: {struct(), list(events :: struct())}
  defp process_commands(commands, state) do
    Enum.reduce(commands, {state, []}, fn command, {state, past_events} ->
      events = Scan.execute(state, command)

      events =
        if is_struct(events, Commanded.Aggregate.Multi) do
          {state, events} = Commanded.Aggregate.Multi.run(events)
          events
        else
          events
        end

      {Enum.reduce(events, state, fn ev, acc -> Scan.apply(acc, ev) end), events ++ past_events}
    end)
  end
end
