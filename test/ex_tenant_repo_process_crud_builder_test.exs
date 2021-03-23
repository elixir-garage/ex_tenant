defmodule ExTenantRepoProcessCrudUsingBuilderTest do
  use ExUnit.Case

  alias ExTenant.Support.ExTenantBuilderRepository, as: TenantRepo
  alias ExTenant.RepoUsingBuilder, as: Repo

  setup do
    {:ok, tenant} = TenantRepo.create_tenant("foo")
    {:ok, bar_tenant} = TenantRepo.create_tenant("bar")
    #
    # this normally would be handled by a plug in PHX..
    #
    IO.puts "tenant:"
    IO.inspect tenant

    Repo.put_tenant_id(tenant.tenant_id)

    {:ok, tenant: tenant, bar_tenant: bar_tenant}
  end

  describe "test the schema - comment crud" do
    test "creates a comment on a post" do
      post = TenantRepo.create_post("test-p-name", "test-p-body")
      
  #    created_comment = TenantRepo.create_comment("test-c-name", "test-c-body", post.id)
  #    retrieved_commment = TenantRepo.get_comment(created_comment.id)

  #    assert retrieved_commment.id == created_comment.id
  #    assert retrieved_commment.name == created_comment.name
  #    assert retrieved_commment.post_id == created_comment.post_id
  #    assert retrieved_commment.tenant_id == created_comment.tenant_id
    end
  end

  #describe "test the schema - post crud" do
  #  test "creates a post in the tenant" do
  #    created_post = TenantRepo.create_post("test-post-name", "test-post-body")
  #    retrieved_post = TenantRepo.get_post(created_post.id)

  #    assert retrieved_post.id == created_post.id
  #    assert retrieved_post.name == created_post.name
  #    assert retrieved_post.tenant_id == created_post.tenant_id
  #  end
  #end
end