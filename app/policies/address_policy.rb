class AddressPolicy < ApplicationPolicy

  def index?
    # todo: factor this to a shared applicationpolicy method
    EmbedPolicy.new(user, Embed).index?
  end
  #
  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record.realm)
    # return true  if user.is_owner?(record)
    return true  if user.profile_id == record.profile&.id
    #todo: let payee see payor info & address
    # scope.where(:id => record.id).exists?
    false
  end
  #
  # def create?
  #   # user.is_super_admin? || user.is_realm_admin? #todo: embed owner?
  #   true  #todo think about end user needs here
  # end

  class Scope < Scope
    def resolve
      return scope  if user.is_super_admin?
      # for now assume if a a realm admin, then no other filters are relevant
      if user.is_realm_admin?
        return scope.where(profile_id: Profile.select(:id).where(realm_id: user.admined_realm))
      end
      scope.where(profile_id: user.profile_id)
    end
  end

end