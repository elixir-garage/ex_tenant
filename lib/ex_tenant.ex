defmodule ExTenant do
  @moduledoc """
    Call the `use ExTenant` macro to inject all the required behaviour into your
    Application Repo module to enable all multi-tenancy functions.

    Setup
    -----

    In the application `Config` file the `repo` and `tenanted_field` settings need to be configured.
    ExTenant will default the tenanted_field setting to be `tenant_id`.

    Config
    ------

      config :ex_tenant,
        tenant_repo: MyAppRepo,
        tenanted_field: "tenant_id",
        get_tenant_from_subdomain_func: &your_application_get_tenant_from_subdomain_function/1

    - If the `repo` is not configured ExTenant will raise an exception.
    - the `get_tenant_from_subdomain_func` is optional if you decide to use the Plug - see example below

    Repo
    ----

    In your application `Repo` file call the `use` macro as per this example

      def YourApplication.Repo do
        use ExTenant,
          config: [
            otp_app: :name_of_your_elixir_phoenix_app_as_atom,
            adapter: Ecto.Adapters.Postgres,
            tenanted_field: "tenant_id"
          ]
      end

    In order to get the `tenant_id` into the progress dictionary in Phoenix
    we recommend to use a plug - there you should retrieve the `tenant name`
    from something like the `sub domain` in the url. Then using the `tenant name`
    retrieve the `tenant`, and call:

    - Repo.put_tenant_id(tenant_id)

    To insert the `tenant_id` into the process dictionary.

    Plug
    ----

    - An example of how a Plug can be used to insert the tenant_id into the process dictionary

    - Take a look at the module `ExTenant.SubdomainPlug`


    From here all your Repo callbacks (Repo.get/Repo.one/Repo.all etc) will
    have a where clause applied to them with the `tenant_id` injected into the clause.

    In order to set the `tenant_id` on `insert` and `update` functions the tenant_id
    needs to be inserted into the attributes to be inserted. The `tenanted_schema`
    macro & the `tenanted()` function inserts the correct `belongs_to` tenanted foreign
    key based relationship.

    Further the `cast_tenant` method overloads the standard `Ecto.Changeset.cast` function
    by injecting the `tenant_id` into the params and allowed keys. This function raises
    exceptions when the `Repo` was not configured correctly in `config.exs` and also
    if the `tenant_id` value is not set in the process_dictionary.

    Ecto Schema/Changeset
    ---------------------

      defmodule Post do
        use ExTenant.Schema
        use ExTenant.Changeset

        tenanted_schema "posts" do
          field(:name, :string)
          field(:body, :string)

          tenanted()
        end

        defp changeset(attrs) do
          %__MODULE__{}
          |> cast_tenanted(params, [:name, :body])
        end
      end

    NB: If the `tenant_id` is not set in the changeset, Repo.insert/update callbacks
    will raise a `Postgrex.Error` (not_null_violation)

    Migrations
    ----------

    - documentation to be added.

  """

  @doc false
  defmacro __using__(opts) do
    config = Keyword.get(opts, :config)
    tenanted_field = config[:tenanted_field]
    application = config[:otp_app]
    database_adapter = config[:adapter]
    tenant_key = {__CALLER__.module, String.to_atom(tenanted_field)}

    quote do
      import ExTenant
      require Ecto.Query
      use Ecto.Repo, otp_app: unquote(application), adapter: unquote(database_adapter)

      generate_put_tenant_function(unquote(tenant_key))
      generate_get_tenant_function(unquote(tenant_key))
      generate_default_options_callback(unquote(tenanted_field))
      generate_inject_tenant_id_callback(unquote(tenanted_field))
      generate_prepare_query_callback(unquote(tenanted_field))
    end
  end

  @doc false
  defmacro generate_prepare_query_callback(tenanted_field) do
    quote do
      def prepare_query(operation, query, opts) do
        tenant_field = String.to_existing_atom(unquote(tenanted_field))

        cond do
          opts[:skip_tenant_id] || opts[:schema_migration] ->
            {query, opts}

          tenant_id = opts[tenant_field] ->
            filtered_where =
              query
              |> Ecto.Query.where(
                [q],
                inject_where(q, tenant_field, tenant_id, :==)
              )

            {filtered_where, opts}

          true ->
            raise ExTenant.TenantNotSetError
        end
      end
    end
  end

  @doc false
  defmacro generate_inject_tenant_id_callback(tenant_field) do
    quote do
      def inject_tenant_id(params) do
        string_params = for {key, val} <- params, into: %{}, do: {"#{key}", val}

        string_params
        |> Map.put(unquote(tenant_field), get_tenant_id())
      end
    end
  end

  @doc false
  defmacro generate_default_options_callback(tenanted_field) do
    quote do
      def default_options(_operation) do
        [
          {
            String.to_existing_atom(unquote(tenanted_field)),
            get_tenant_id()
          }
        ]
      end
    end
  end

  @doc false
  defmacro generate_put_tenant_function(tenant_key) do
    quote do
      def put_tenant_id(tenant_id) do
        Process.put(unquote(tenant_key), tenant_id)
      end
    end
  end

  @doc false
  defmacro generate_get_tenant_function(tenant_key) do
    quote do
      def get_tenant_id() do
        Process.get(unquote(tenant_key))
      end
    end
  end

  @doc false
  defmacro inject_where(t, f, v, sign) do
    {sign, [context: Elixir, import: Kernel],
     [
       {:field, [], [t, {:^, [], [f]}]},
       {:^, [], [v]}
     ]}
  end
end
