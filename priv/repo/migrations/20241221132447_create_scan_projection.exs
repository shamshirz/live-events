defmodule LiveEvent.Repo.Migrations.CreateScanProjection do
  use Ecto.Migration

  def change do
    create table(:scan_projections, primary_key: false) do
      add :scan_id, :string, primary_key: true
      add :domain, :string, null: false
      add :status, :string, null: false
      add :domains, {:array, :string}, default: []
      add :subdomains, :map, default: %{}
      add :score, :float
      add :duration_seconds, :integer
      add :created_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps()
    end

    create index(:scan_projections, [:status])
  end
end
