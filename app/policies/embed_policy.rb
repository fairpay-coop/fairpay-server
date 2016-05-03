class EmbedPolicy < ApplicationPolicy

  def index?
    user.is_super_admin? || user.is_realm_admin? || user.is_embed_owner?
  end

  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record.realm)
    return true  if user.is_owner?(record)
    false
    # scope.where(:id => record.id).exists?
  end

  def create?
    user.is_super_admin? || user.is_realm_admin?
  end

end