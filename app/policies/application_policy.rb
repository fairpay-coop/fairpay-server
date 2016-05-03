class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user.has_role? :superadmin
  end

  def show?
    return true  unless record.respond_to?(:id)
    scope.where(:id => record.id).exists?
  end

  def create?
    index?
  end

  def new?
    create?
  end

  def update?
    show?
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  def destroy_all?
    user.has_role? :superadmin  #todo need to understand this better
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
