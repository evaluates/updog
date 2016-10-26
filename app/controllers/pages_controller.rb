class PagesController < ApplicationController

  def about
  end

  def pricing
    @current_user = current_user
  end

  def source
  end

  def contact
  end

  def thanks
  end

  def contact_create
    errors = []
    if params[:email].blank?
      errors << 'Email address can’t be blank.'
    end
    if params[:content].blank?
      errors << 'Message can’t be blank.'
    end
    if errors.any?
      flash.now[:notice] = errors.join '<br>'
      return render 'contact'
    end
    ContactMailer.new_message(params).deliver_now!
    flash[:notice] = "Message sent successfully! We'll get back to you as soon as possible."
    redirect_to contact_path
  end

  def admin
    if current_user && current_user.id == 1
      @users = {}
      @count = User.all.count
      User.all.sort_by(&:created_at).each do |user|
        time = user.created_at.strftime("%F")
        @users[time] ||= []
        @users[time] << user
      end
      @users = @users
    else
      redirect_to root_path
    end
  end
end
