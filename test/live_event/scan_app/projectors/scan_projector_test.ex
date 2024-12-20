defmodule LiveEvent.ScanApp.Projectors.ScanProjectorTest do
  # TODO: I don't like this. The projector is "effect-ful" when using Ecto.Projector. Makes testing worse than returning a projection struct as a result.
  use LiveEvent.DataCase

  alias LiveEvent.ScanApp.Projections.Scan

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverDomainsSucceeded,
    DiscoverSubdomainsSucceeded,
    ScanCompleted,
    ScanFailed
  }

  alias LiveEvent.ScanApp.Projectors.Scan, as: ScanProjector

  describe "scan projections" do
    test "creates scan projection on scan started" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      started_at = DateTime.utc_now()

      event = %ScanStarted{
        scan_id: scan_id,
        domain: domain,
        started_at: started_at
      }

      :ok = ScanProjector.handle(event, %{})

      assert %Scan{
               scan_id: ^scan_id,
               domain: ^domain,
               status: :started,
               started_at: ^started_at
             } = Repo.get!(Scan, scan_id)
    end

    test "updates scan with discovered domains" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      setup_initial_scan(scan_id, domain)

      associated_domains = ["example1.com", "example2.com"]

      event = %DiscoverDomainsSucceeded{
        scan_id: scan_id,
        associated_domains: associated_domains
      }

      :ok = ScanProjector.handle(event, %{})

      assert %Scan{
               scan_id: ^scan_id,
               domains: ^associated_domains,
               status: :domains_discovered
             } = Repo.get!(Scan, scan_id)
    end

    test "updates scan with discovered subdomains" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      setup_scan_with_domains(scan_id, domain, ["example1.com"])

      subdomains = ["sub1.example1.com", "sub2.example1.com"]

      event = %DiscoverSubdomainsSucceeded{
        scan_id: scan_id,
        domain: "example1.com",
        subdomains: subdomains
      }

      :ok = ScanProjector.handle(event, %{})

      assert %Scan{
               scan_id: ^scan_id,
               subdomains: %{"example1.com" => ^subdomains}
             } = Repo.get!(Scan, scan_id)
    end

    test "completes scan with score and timestamp" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      setup_scan_with_subdomains(scan_id, domain)

      score = 42
      completed_at = DateTime.utc_now()

      event = %ScanCompleted{
        scan_id: scan_id,
        score: score,
        completed_at: completed_at
      }

      :ok = ScanProjector.handle(event, %{})

      assert %Scan{
               scan_id: ^scan_id,
               status: :completed,
               score: ^score,
               completed_at: ^completed_at
             } = Repo.get!(Scan, scan_id)
    end

    test "marks scan as failed with error message" do
      scan_id = UUID.uuid4()
      domain = "example.com"
      setup_initial_scan(scan_id, domain)

      error = "Something went wrong"

      event = %ScanFailed{
        scan_id: scan_id,
        error: error
      }

      :ok = ScanProjector.handle(event, %{})

      assert %Scan{
               scan_id: ^scan_id,
               status: :failed,
               error: ^error
             } = Repo.get!(Scan, scan_id)
    end
  end

  # Helper functions to set up test data

  defp setup_initial_scan(scan_id, domain) do
    %Scan{
      scan_id: scan_id,
      domain: domain,
      status: :started,
      started_at: DateTime.utc_now()
    }
    |> Repo.insert!()
  end

  defp setup_scan_with_domains(scan_id, domain, associated_domains) do
    setup_initial_scan(scan_id, domain)
    |> Ecto.Changeset.change(%{
      domains: associated_domains,
      status: :domains_discovered
    })
    |> Repo.update!()
  end

  defp setup_scan_with_subdomains(scan_id, domain) do
    setup_scan_with_domains(scan_id, domain, ["example1.com"])
    |> Ecto.Changeset.change(%{
      subdomains: %{"example1.com" => ["sub1.example1.com"]},
      status: :subdomains_discovered
    })
    |> Repo.update!()
  end
end
