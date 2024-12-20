defmodule LiveEvent.ScanApp.ProcessManagers.ScanProcessManagerTest do
  use ExUnit.Case

  alias LiveEvent.ScanApp.ProcessManagers.Scan

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverDomainsRequested,
    DiscoverDomainsSucceeded,
    DiscoverDomainsFailed,
    DiscoverSubdomainsRequested,
    DiscoverSubdomainsSucceeded,
    DiscoverSubdomainsFailed,
    ScanCompleted,
    ScanFailed
  }

  alias LiveEvent.ScanApp.Commands.{
    DiscoverSubdomainsRequest,
    CompleteScan,
    FailScan
  }

  describe "routing" do
    test "interested in scan started events" do
      assert {:start, "123"} = Scan.interested?(%ScanStarted{scan_id: "123"})
    end

    test "interested in domain discovery events" do
      assert {:continue, "123"} = Scan.interested?(%DiscoverDomainsRequested{scan_id: "123"})
      assert {:continue, "123"} = Scan.interested?(%DiscoverDomainsSucceeded{scan_id: "123"})
      assert {:continue, "123"} = Scan.interested?(%DiscoverDomainsFailed{scan_id: "123"})
    end

    test "interested in subdomain discovery events" do
      assert {:continue, "123"} = Scan.interested?(%DiscoverSubdomainsRequested{scan_id: "123"})
      assert {:continue, "123"} = Scan.interested?(%DiscoverSubdomainsSucceeded{scan_id: "123"})
      assert {:continue, "123"} = Scan.interested?(%DiscoverSubdomainsFailed{scan_id: "123"})
    end

    test "stops on completion events" do
      assert {:stop, "123"} = Scan.interested?(%ScanCompleted{scan_id: "123"})
      assert {:stop, "123"} = Scan.interested?(%ScanFailed{scan_id: "123"})
    end
  end

  describe "command dispatch" do
    test "dispatches subdomain discovery commands when domains are discovered" do
      state = %Scan{
        scan_id: "123",
        pending_domains: ["example.com"]
      }

      event = %DiscoverDomainsSucceeded{
        scan_id: "123",
        associated_domains: ["example2.com", "example3.com"]
      }

      commands = Scan.handle(state, event)

      assert [
               %DiscoverSubdomainsRequest{scan_id: "123", domain: "example.com"},
               %DiscoverSubdomainsRequest{scan_id: "123", domain: "example2.com"},
               %DiscoverSubdomainsRequest{scan_id: "123", domain: "example3.com"}
             ] ==
               commands
               |> Enum.sort_by(& &1.domain)
    end

    test "dispatches complete scan command when all subdomains are discovered" do
      state = %Scan{
        scan_id: "123",
        pending_domains: ["example.com"]
      }

      event = %DiscoverSubdomainsSucceeded{
        scan_id: "123",
        domain: "example.com"
      }

      assert %CompleteScan{scan_id: "123"} = Scan.handle(state, event)
    end

    test "fails scan after max domain discovery retries" do
      state = %Scan{scan_id: "123"}

      event = %DiscoverDomainsFailed{
        scan_id: "123",
        error: "API Error"
      }

      assert [] = Scan.handle(%{state | domain_retries: 2}, event)

      assert %FailScan{error: "Max DomainDiscovery retries reached"} =
               Scan.handle(%{state | domain_retries: 3}, event)
    end

    test "fails scan after max subdomain discovery retries" do
      state = %Scan{scan_id: "123"}

      event = %DiscoverSubdomainsFailed{
        scan_id: "123",
        error: "API Error"
      }

      assert [] = Scan.handle(%{state | subdomain_retries: 2}, event)

      assert %FailScan{
               scan_id: "123",
               error: "Max SubdomainDiscovery retries reached"
             } = Scan.handle(%{state | subdomain_retries: 3}, event)
    end
  end
end
