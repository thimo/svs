# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    add_breadcrumb "Home", "/"
    before_action :default_breadcrumb

    def index
      skip_authorization
      redirect_to admin_members_path
    end

    def show
      skip_authorization
      redirect_to admin_members_path
    end

    private

      def default_breadcrumb
        add_breadcrumb "Beheer", admin_path
      end
  end
end
