class ProfilePolicy < ApplicationPolicy

  def index?
    # todo: factor this to a shared applicationpolicy method
    EmbedPolicy.new(user, Embed).index?
  end
  #
  def show?
    return true  if user.is_super_admin? || user.has_role?(:admin, record.realm)
    # return true  if user.is_owner?(record)
    return true  if user.profile_id == record.id

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
      return scope.where(realm: user.admined_realm)  if user.is_realm_admin?
      scope.where(id: user.profile_id)
    end
  end

end