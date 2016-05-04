class TransactionPolicy < ApplicationPolicy

  def index?
    EmbedPolicy.new(user, Embed).index?
  end

  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record.realm)
    return true  if EmbedPolicy.new(user, record.embed).show?
    return true  if [record.payee&.profile_id, record.payor&.profile_id].compact.include?(user.profile_id)
    # scope.where(:id => record.id).exists?
    return false
  end

  def create?
    # user.is_super_admin? || user.is_realm_admin? || user.is_owner(record.embed)
    show?
  end

  class Scope < Scope
    def resolve
      return scope  if user.is_super_admin?
      # for now assume if a a realm admin, then no other filters are relevant
      if user.is_realm_admin?
        return scope.where(embed_id: Embed.select(:id).where(realm_id: user.admined_realm))
      end
      scope.where(id: user.owned_embed_ids)
      #todo: payor scope
    end
  end

end