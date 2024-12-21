defmodule LiveEvent.ScanApp.Gateways.DomainGateway do
  @moduledoc """
  This is the gateway for the domain app.

  As a Gateway Event handler
  * I listen to events
  * I perform side effects
  * I dispatch commands to the Aggregate

  TODO: The problem here is that there is only 1 instance of this event handler, so it processes each event serially.
  I want to process the domain events in parallel.
  """

  use Commanded.Event.Handler,
    application: LiveEvent.ScanApp.Application,
    name: __MODULE__

  alias LiveEvent.ScanApp.Events.{
    DiscoverDomainsRequested,
    DiscoverSubdomainsRequested
  }

  alias LiveEvent.ScanApp.Commands.{
    DiscoverDomainsFail,
    DiscoverDomainsSuccess,
    DiscoverSubdomainsFail,
    DiscoverSubdomainsSuccess
  }

  require Logger

  @spec handle(any(), any()) :: :ok
  def handle(%DiscoverDomainsRequested{scan_id: scan_id, domain: domain}, _metadata) do
    Task.start(fn -> discover_domains(scan_id, domain) end)
  end

  def handle(%DiscoverSubdomainsRequested{scan_id: scan_id, domain: domain}, _metadata) do
    Task.start(fn -> discover_subdomains(scan_id, domain) end)
  end

  # Mock external service call
  defp discover_subdomains(scan_id, domain) do
    Process.sleep(2000)

    case :rand.uniform(100) do
      failure when failure <= 10 ->
        :ok =
          LiveEvent.ScanApp.Application.dispatch(%DiscoverSubdomainsFail{
            scan_id: scan_id,
            domain: domain,
            error: "Failed to discover domains"
          })

      timeout when timeout <= 25 ->
        :ok =
          LiveEvent.ScanApp.Application.dispatch(%DiscoverSubdomainsFail{
            scan_id: scan_id,
            domain: domain,
            error: "Timeout"
          })

      _success ->
        base_domain = String.replace(domain, ~r/^www\./, "")

        # Define possible subdomains
        possible_subdomains = [
          "www.#{base_domain}",
          "api.#{base_domain}",
          "blog.#{base_domain}",
          "dev.#{base_domain}",
          "staging.#{base_domain}",
          "test.#{base_domain}",
          "admin.#{base_domain}",
          "mail.#{base_domain}",
          "support.#{base_domain}",
          "docs.#{base_domain}"
        ]

        # Get random number of subdomains (1 to length of possible list)
        count = :rand.uniform(length(possible_subdomains))
        discovered_subdomains = Enum.take_random(possible_subdomains, count)

        :ok =
          LiveEvent.ScanApp.Application.dispatch(%DiscoverSubdomainsSuccess{
            scan_id: scan_id,
            domain: domain,
            subdomains: discovered_subdomains
          })
    end

    :ok
  end

  # Synchronous call to discover domains, results in dispatching a command
  # How do allow retries?
  @spec discover_domains(String.t(), String.t()) :: :ok
  defp discover_domains(scan_id, domain) do
    Process.sleep(2000)

    case :rand.uniform(100) do
      failure when failure <= 10 ->
        :ok =
          LiveEvent.ScanApp.Application.dispatch(%DiscoverDomainsFail{
            scan_id: scan_id,
            error: "Failed to discover domains"
          })

      timeout when timeout <= 25 ->
        :ok =
          LiveEvent.ScanApp.Application.dispatch(%DiscoverDomainsFail{
            scan_id: scan_id,
            error: "Timeout"
          })

      _success ->
        base_domain = String.replace(domain, ~r/^www\.|\.[^.]+$/, "")

        # Define possible associated domains
        possible_domains = [
          "#{base_domain}1.com",
          "#{base_domain}2.org",
          "#{base_domain}3.net",
          "#{base_domain}-app.com",
          "#{base_domain}-dev.com",
          "#{base_domain}-staging.net",
          "#{base_domain}-prod.org",
          "#{base_domain}-test.com",
          "#{base_domain}-api.net",
          "#{base_domain}-docs.org"
        ]

        # Get random number of domains (1 to length of possible list)
        count = :rand.uniform(length(possible_domains))
        discovered_domains = Enum.take_random(possible_domains, count)

        :ok =
          LiveEvent.ScanApp.Application.dispatch(%DiscoverDomainsSuccess{
            scan_id: scan_id,
            associated_domains: discovered_domains
          })
    end
  end

  # By default skip any problematic events
  def error(error, _event, _failure_context) do
    Logger.error(fn ->
      "#{__MODULE__} encountered an error: #{inspect(error)}"
    end)

    :skip
  end
end
