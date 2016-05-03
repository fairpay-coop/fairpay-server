class ActiveAdmin::PagePolicy < ApplicationPolicy

  class DashboardPolicy < ApplicationPolicy
    def dashboard?
      true
    end
    def index?
      true
    end

    def show?
      true
    end

  end

end