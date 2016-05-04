class OfferPolicy < ApplicationPolicy

  def index?
    EmbedPolicy.new(user, Embed).index?
  end

  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record.realm)
    return true  if CampaignPolicy.new(user, record.campaign).show?
    # scope.where(:id => record.id).exists?
    return false
  end

  def create?
    user.is_super_admin? || user.is_realm_admin? || user.is_owner(record.embed)
  end

  class Scope < Scope
    def resolve
      return scope  if user.is_super_admin?
      # for now assume if a a realm admin, then no other filters are relevant
      if user.is_realm_admin?
        return scope.where(campaign_id: Campaign.select(:id).where(realm_id: user.admined_realm))
      end
      scope.where(campaign_id: user.owned_campaign_ids)
    end
  end

end