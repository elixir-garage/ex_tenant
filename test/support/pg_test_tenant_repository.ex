defmodule ExTenant.Support.PgTestTenantRepository do
  alias ExTenant.Test.Support.Schemas.Postgres.{Tenant, Post, Comment}
  alias ExTenant.Test.Support.Schemas.Postgres.PgTestRepo

  # ----- TestRepo functions that DO NOT use the ex_tenant macros ------#

  def create_tenant(name) do
    %{"name" => name}
    |> Tenant.changeset()
    |> PgTestRepo.insert()
  end

  def create_post(name, body, tenant_id) do
    %{"name" => name, "body" => body, "tenant_id" => tenant_id}
    |> Post.changeset()
    |> PgTestRepo.insert()
  end

  def create_post_without_tenant_id(name, body) do
    %{"name" => name, "body" => body}
    |> Post.changeset_without_tenant_id()
    |> PgTestRepo.insert()
  end

  def create_comment(name, body, post_id, tenant_id) do
    %{"name" => name, "body" => body, "post_id" => post_id, "tenant_id" => tenant_id}
    |> Comment.changeset()
    |> PgTestRepo.insert()
  end
end
