defmodule LiveEvent.ScanApp.ProcessManagers.ScanProcessManagerTest do
  use ExUnit.Case

  alias LiveEvent.ScanApp.ProcessManagers.Scan

  alias LiveEvent.ScanApp.Events.{
    DiscoverDomainsSucceeded,
    DiscoverDomainsFailed,
    DiscoverSubdomainsSucceeded,
    DiscoverSubdomainsFailed
  }

  alias LiveEvent.ScanApp.Commands.{
    DiscoverSubdomainsRequest,
    DiscoverDomainsRequest,
    CompleteScan,
    FailScan
  }

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
        domain: "example.com",
        subdomains: ["subdomain1.example.com", "subdomain2.example.com"]
      }

      assert %CompleteScan{scan_id: "123"} = Scan.handle(state, event)
    end

    @tag capture_log: true
    test "retries & then fails scan after max domain discovery retries" do
      state = %Scan{scan_id: "123"}

      event = %DiscoverDomainsFailed{
        scan_id: "123",
        domain: "example.com",
        error: "API Error"
      }

      assert [%DiscoverDomainsRequest{scan_id: "123", domain: "example.com"}] =
               Scan.handle(%{state | domain_retries: 2}, event)

      assert %FailScan{error: "Max DomainDiscovery retries reached"} =
               Scan.handle(%{state | domain_retries: 3}, event)
    end

    # TODO: The fact that logs are ignored here is a red flag!
    # Process Managers should be pure, so the responsibility to log this information should be handled elsewhere.
    @tag capture_log: true
    test "fails scan after max subdomain discovery retries" do
      state = %Scan{scan_id: "123"}

      event = %DiscoverSubdomainsFailed{
        scan_id: "123",
        domain: "example.com",
        error: "API Error"
      }

      assert [%DiscoverSubdomainsRequest{scan_id: "123", domain: "example.com"}] =
               Scan.handle(%{state | subdomain_retries: 2}, event)

      assert %FailScan{
               scan_id: "123",
               error: "Max SubdomainDiscovery retries reached"
             } = Scan.handle(%{state | subdomain_retries: 3}, event)
    end
  end
end
