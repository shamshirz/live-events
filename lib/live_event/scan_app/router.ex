defmodule LiveEvent.ScanApp.Router do
  use Commanded.Commands.Router

  alias LiveEvent.ScanApp.Aggregates.Scan

  alias LiveEvent.ScanApp.Commands.{
    StartScan,
    DiscoverDomainsSuccess,
    DiscoverDomainsFail,
    DiscoverSubdomainsRequest,
    DiscoverSubdomainsSuccess,
    DiscoverSubdomainsFail,
    DiscoverDomainsRequest,
    CompleteScan,
    FailScan
  }

  middleware(Commanded.Middleware.Logger)

  identify(Scan,
    by: :scan_id,
    prefix: "scan-"
  )

  dispatch(
    [
      StartScan,
      DiscoverDomainsFail,
      DiscoverDomainsRequest,
      DiscoverDomainsSuccess,
      DiscoverSubdomainsFail,
      DiscoverSubdomainsRequest,
      DiscoverSubdomainsSuccess,
      CompleteScan,
      FailScan
    ],
    to: Scan
  )
end
