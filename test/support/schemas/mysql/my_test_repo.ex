defmodule ExTenant.Test.Support.Schemas.Mysql.MyTestRepo do
  @moduledoc """
    we need to test the schema without any of our code
  """
  use Ecto.Repo, otp_app: :ex_tenant, adapter: Ecto.Adapters.MyXQL
end
