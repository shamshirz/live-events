defmodule LiveEvent.ScanApp.Aggregates.ScanTest do
  # TODO: Never test internal state.
  use ExUnit.Case

  alias LiveEvent.ScanApp.Aggregates.Scan

  alias LiveEvent.ScanApp.Commands.{
    StartScan,
    DiscoverDomainsSuccess,
    DiscoverSubdomainsSuccess,
    CompleteScan,
    DiscoverSubdomainsRequest,
    DiscoverDomainsFail,
    DiscoverSubdomainsFail
  }

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverDomainsSucceeded,
    DiscoverSubdomainsRequested,
    DiscoverSubdomainsSucceeded,
    ScanCompleted,
    DiscoverDomainsFailed,
    DiscoverSubdomainsFailed
  }

  describe "start scan" do
    test "starts a new scan" do
      scan_id = UUID.uuid4()
      domain = "example.com"

      command = %StartScan{
        scan_id: scan_id,
        domain: domain
      }

      assert %{executions: [_one, _two]} = Scan.execute(%Scan{}, command)
    end
  end

  describe "discover domains" do
    test "discovers associated domains" do
      initial_state = Scan.new("123id", "example.com")
      associated_domains = ["example1.com", "example2.com"]

      command = %DiscoverDomainsSuccess{
        scan_id: "123id",
        associated_domains: associated_domains
      }

      assert [
               %DiscoverDomainsSucceeded{
                 scan_id: "123id",
                 associated_domains: ^associated_domains
               }
             ] =
               Scan.execute(initial_state, command)
    end
  end

  describe "request subdomain discovery" do
    test "requests subdomain discovery for a domain" do
      initial_state = Scan.new("123id", "example.com")

      command = %DiscoverSubdomainsRequest{
        scan_id: "123id",
        domain: "example.com"
      }

      assert [
               %DiscoverSubdomainsRequested{
                 scan_id: "123id",
                 domain: "example.com"
               }
             ] = Scan.execute(initial_state, command)
    end
  end

  describe "discover subdomains" do
    test "discovers subdomains for a domain" do
      initial_state = %Scan{
        scan_id: "123id",
        domain: "example.com",
        status: :domains_discovered
      }

      subdomains = ["sub1.example.com", "sub2.example.com"]

      command = %DiscoverSubdomainsSuccess{
        scan_id: "123id",
        domain: "example.com",
        subdomains: subdomains
      }

      assert [
               %DiscoverSubdomainsSucceeded{
                 scan_id: "123id",
                 domain: "example.com",
                 subdomains: ^subdomains
               }
             ] = Scan.execute(initial_state, command)
    end
  end

  describe "complete scan" do
    test "completes the scan with a score" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      domains = ["example1.com", "example2.com"]

      subdomains = %{
        "example1.com" => ["sub1.example1.com", "sub2.example1.com"],
        "example2.com" => ["sub1.example2.com", "sub2.example2.com"]
      }

      initial_state = %Scan{
        scan_id: scan_id,
        domain: domain,
        status: :subdomains_discovered,
        domains: domains,
        subdomains: subdomains
      }

      command = %CompleteScan{
        scan_id: scan_id
      }

      assert [%ScanCompleted{scan_id: ^scan_id} = event] = Scan.execute(initial_state, command)

      assert event.score > 0
      assert event.domains == domains
      assert event.subdomains == subdomains
      assert %DateTime{} = event.completed_at
    end
  end

  describe "state transitions" do
    test "applies scan started event" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      event = %ScanStarted{scan_id: scan_id, domain: domain, started_at: DateTime.utc_now()}

      state = Scan.apply(%Scan{}, event)

      assert state.scan_id == scan_id
      assert state.domain == domain
      assert state.status == :started
    end

    test "applies domains discovered event" do
      scan_id = UUID.uuid4()
      domains = ["example1.com", "example2.com"]
      event = %DiscoverDomainsSucceeded{scan_id: scan_id, associated_domains: domains}

      state = Scan.apply(%Scan{scan_id: scan_id}, event)

      assert state.domains == domains
      assert state.status == :domains_discovered
    end

    test "applies discover subdomains requested event" do
      scan_id = UUID.uuid4()
      domain = "example.com"

      event = %DiscoverSubdomainsRequested{
        scan_id: scan_id,
        domain: domain
      }

      initial_state = %Scan{scan_id: scan_id, status: :started}
      state = Scan.apply(initial_state, event)

      # State should not change on subdomain request
      assert state == initial_state
    end

    test "applies discovered subdomains event" do
      scan_id = UUID.uuid4()
      domain = "example1.com"
      subdomains = ["sub1.example1.com", "sub2.example1.com"]

      initial_state = %Scan{
        scan_id: scan_id,
        domains: [domain],
        subdomains: %{}
      }

      event = %DiscoverSubdomainsSucceeded{
        scan_id: scan_id,
        domain: domain,
        subdomains: subdomains
      }

      state = Scan.apply(initial_state, event)

      assert state.subdomains[domain] == subdomains
    end

    test "applies scan completed event" do
      scan_id = UUID.uuid4()
      score = 42
      event = %ScanCompleted{scan_id: scan_id, score: score}

      state = Scan.apply(%Scan{scan_id: scan_id}, event)

      assert state.status == :completed
      assert state.score == score
    end
  end

  describe "domain discovery failures" do
    test "handles domain discovery failure" do
      initial_state = Scan.new("123id", "example.com")
      error_message = "API timeout"

      command = %DiscoverDomainsFail{
        scan_id: "123id",
        error: error_message
      }

      assert [
               %DiscoverDomainsFailed{
                 scan_id: "123id",
                 error: ^error_message
               }
             ] = Scan.execute(initial_state, command)
    end

    test "maintains state after domain discovery failure" do
      initial_state = %Scan{
        scan_id: "123id",
        domain: "example.com",
        status: :started
      }

      event = %DiscoverDomainsFailed{
        scan_id: "123id",
        error: "API timeout"
      }

      state = Scan.apply(initial_state, event)
      assert state.status == :started
    end
  end

  describe "subdomain discovery failures" do
    test "handles subdomain discovery failure" do
      initial_state = %Scan{
        scan_id: "123id",
        domain: "example.com",
        status: :domains_discovered
      }

      error_message = "Subdomain API error"

      command = %DiscoverSubdomainsFail{
        scan_id: "123id",
        domain: "example.com",
        error: error_message
      }

      assert [
               %DiscoverSubdomainsFailed{
                 scan_id: "123id",
                 domain: "example.com",
                 error: ^error_message
               }
             ] = Scan.execute(initial_state, command)
    end

    test "maintains state after subdomain discovery failure" do
      initial_state = %Scan{
        scan_id: "123id",
        domain: "example.com",
        status: :domains_discovered,
        domains: ["example.com"],
        subdomains: %{}
      }

      event = %DiscoverSubdomainsFailed{
        scan_id: "123id",
        domain: "example.com",
        error: "API timeout"
      }

      state = Scan.apply(initial_state, event)
      assert state.status == :domains_discovered
      assert state.subdomains == %{}
    end
  end
end
