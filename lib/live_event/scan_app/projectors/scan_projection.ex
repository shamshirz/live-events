defmodule LiveEvent.ScanApp.Projectors.ScanProjection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:scan_id, :string, []}
  schema "scan_projections" do
    field :domain, :string
    field :status, Ecto.Enum, values: [:started, :discovering_subdomains, :completed, :failed]
    field :domains, {:array, :string}, default: []
    field :subdomains, :map, default: %{}
    field :score, :float
    field :duration_seconds, :integer
    field :created_at, :utc_datetime
    field :completed_at, :utc_datetime

    timestamps()
  end

  def changeset(scan, attrs) do
    scan
    |> cast(attrs, [
      :scan_id,
      :domain,
      :status,
      :domains,
      :subdomains,
      :score,
      :duration_seconds,
      :created_at,
      :completed_at
    ])
    |> validate_required([:scan_id, :domain, :status])
  end
end
