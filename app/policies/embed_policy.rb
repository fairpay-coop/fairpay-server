class EmbedPolicy < ApplicationPolicy

  def index?
    user.is_super_admin? || user.is_realm_admin? || user.is_embed_owner?
  end

  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record&.realm)
    return true  if user.is_owner?(record)
    false
    # scope.where(:id => record.id).exists?
  end

  def create?
    user.is_super_admin? || user.is_realm_admin?
  end

  class Scope < Scope
    def resolve
      return scope  if user.is_super_admin?
      # for now assume if a a realm admin, then no other filters are relevant
      return scope.where(realm_id: user.admined_realm)  if user.is_realm_admin?
      scope.where(id: user.owned_embed_ids)
    end
  end
end