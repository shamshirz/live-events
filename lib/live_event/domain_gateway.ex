defmodule LiveEvent.DomainGateway do
  @moduledoc """
  This is the gateway for the domain app.

  As a Gateway Event handler
  * I listen to events
  * I perform side effects
  * I dispatch commands to the Aggregate
  """

  use Commanded.Event.Handler,
    application: LiveEvent.ScanApp.Application,
    name: __MODULE__,
    consistency: :strong

  alias LiveEvent.ScanApp.Events.{
    ScanStarted,
    DiscoverSubdomainsRequested
  }

  alias LiveEvent.ScanApp.Commands.{DiscoverDomains, DiscoverSubdomains}

  require Logger

  def handle(%ScanStarted{scan_id: scan_id, domain: domain}, _metadata) do
    discover_domains(scan_id, domain)
  end

  def handle(%DiscoverSubdomainsRequested{scan_id: scan_id, domain: domain}, _metadata) do
    discover_subdomains(scan_id, domain)
  end

  # Mock external service call
  defp discover_subdomains(scan_id, domain) do
    # For each discovered domain, simulate an async API call to find subdomains
    Task.start(fn ->
      # Simulate different processing times for each domain
      Process.sleep(:rand.uniform(3000))

      # Mock external service response with dynamic subdomains
      Logger.info("Finding subdomains for #{domain}")

      # In a real app, this would make an HTTP call to an external service
      base_domain = String.replace(domain, ~r/^www\./, "")

      discovered_subdomains = [
        "www.#{base_domain}",
        "api.#{base_domain}",
        "blog.#{base_domain}",
        "dev.#{base_domain}",
        "staging.#{base_domain}"
      ]

      :ok =
        LiveEvent.ScanApp.Application.dispatch(%DiscoverSubdomains{
          scan_id: scan_id,
          domain: domain,
          subdomains: discovered_subdomains
        })
    end)

    :ok
  end

  # How do I implement retry here?
  @spec discover_domains(String.t(), String.t()) :: :ok
  defp discover_domains(scan_id, domain) do
    # Simulate async API call to discover associated domains
    Task.start(fn ->
      # Simulate external API delay
      Process.sleep(2000)

      base_domain = String.replace(domain, ~r/^www\.|\.[^.]+$/, "")

      discovered_domains = [
        "#{base_domain}1.com",
        "#{base_domain}2.org",
        "#{base_domain}3.net"
      ]

      # Mock external service response
      :ok =
        LiveEvent.ScanApp.Application.dispatch(%DiscoverDomains{
          scan_id: scan_id,
          domain: domain,
          associated_domains: discovered_domains
        })
    end)
  end

  # By default skip any problematic events
  def error(error, _event, _failure_context) do
    Logger.error(fn ->
      "#{__MODULE__} encountered an error: #{inspect(error)}"
    end)

    :skip
  end
end
