defmodule LiveEvent.ScanApp.Router do
  use Commanded.Commands.Router

  alias LiveEvent.ScanApp.Aggregates.Scan

  alias LiveEvent.ScanApp.Commands.{
    StartScan,
    RequestSubdomainDiscovery,
    DiscoverDomains,
    DiscoverSubdomains,
    CompleteScan
  }

  middleware(Commanded.Middleware.Logger)

  identify(Scan,
    by: :scan_id,
    prefix: "scan-"
  )

  dispatch(
    [StartScan, DiscoverDomains, RequestSubdomainDiscovery, DiscoverSubdomains, CompleteScan],
    to: Scan
  )
end
