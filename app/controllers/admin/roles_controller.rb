class Admin::RolesController < Admin::BaseController
  before_action :create_role, only: [:new, :create]
  before_action :set_role, only: [:show, :edit, :update, :resend_password, :destroy, :impersonate]
  before_action :add_breadcrumbs

  def index
    # TODO filter on roles without resource
    @roles = policy_scope(Role).asc
  end

  def new
  end

  def edit
  end

  private

    def create_role
      @role = if action_name == 'new'
                Role.new
              else
                Role.new(role_params)
              end
      authorize @role
    end

    def set_role
      @role = Role.find(params[:id])
      authorize @role
    end

    def role_params
      params.require(:role).permit(:name, :description)
    end

    def add_breadcrumbs
      add_breadcrumb 'Rollen', admin_roles_path
      unless @role.nil?
        if @role.new_record?
          add_breadcrumb 'Nieuw'
        else
          add_breadcrumb @role.email, [:edit, :admin, @role]
        end
      end
    end

end