class OfferPolicy < ApplicationPolicy

  def index?
    EmbedPolicy.new(user, Embed).index?
  end

  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record.realm)
    return false  unless EmbedPolicy.new(user, record.embed).show?
    # scope.where(:id => record.id).exists?
  end

  def create?
    user.is_super_admin? || user.is_realm_admin? || user.is_owner(record.embed)
  end

end