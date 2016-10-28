class PagesController < ApplicationController

  def about
  end

  def pricing
    @current_user = current_user
    @paypal_url = paypal_url
  end

  def paypal_url
    values = {
      :business => 'jesse-seller@jshawl.com',
      :cmd => '_cart',
      :upload => 1,
      :return => "http://localhost:3000/",
      :invoice => Time.now.to_i,
      "amount_1" => 5,
      "item_name_1" => "UpDog Pro",
      "item_number_1" => 1,
      "quantity_1" => 1
    }
    "https://www.sandbox.paypal.com/cgi-bin/webscr?" + values.to_query
  end

  def source
  end

  def contact
  end

  def thanks
    redirect_to '/pricing' unless current_user && current_user.is_pro?
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
    if current_user && current_user.email == 'jesseshawl@gmail.com'
      @users = {}
      @count = User.all.count
      User.all.sort_by(&:created_at).reverse.each do |user|
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
