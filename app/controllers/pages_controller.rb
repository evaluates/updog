class PagesController < ApplicationController

  def about
  end

  def pricing
    @current_user = current_user
    @subscriptions = current_user && current_user.subscriptions || []
  end

  def source
  end

  def contact
  end

  def contact_create
    ContactMailer.new_message(params).deliver_now!
    flash[:notice] = "Message sent successfully! We'll get back to you as soon as possible."
    redirect_to contact_path
  end

  def admin
    if current_user && current_user.id == 1
      @users = User.all
      @sites = Site.all
    else
      redirect_to root_path
    end
  end
end
