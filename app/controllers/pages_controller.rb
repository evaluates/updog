class PagesController < ApplicationController
  PAYPAL_CERT_PEM = File.read("#{Rails.root}/certs/paypal_cert.pem")
  APP_CERT_PEM = File.read("#{Rails.root}/certs/app_cert.pem")
  APP_KEY_PEM = File.read("#{Rails.root}/certs/app_key.pem")
  def about
  end

  def pricing
    @current_user = current_user
    @paypal_url = ENV['paypal_url']
    @encrypted = paypal_encrypted
  end

  def paypal_encrypted
    values = {
      :business => 'jesse@updog.co',
      :cmd => '_cart',
      :upload => 1,
      :return => ENV['paypal_return'],
      :notify_url => ENV['paypal_notify'],
      :cert_id => ENV['paypal_cert_id'],
      :invoice => current_user.id,
      "amount_1" => 5,
      "item_name_1" => "UpDog Pro",
      "item_number_1" => 1,
      "quantity_1" => 1
    }
    signed = OpenSSL::PKCS7::sign(OpenSSL::X509::Certificate.new(APP_CERT_PEM),        OpenSSL::PKey::RSA.new(APP_KEY_PEM, ''), values.map { |k, v| "#{k}=#{v}" }.join("\n"), [], OpenSSL::PKCS7::BINARY)
    OpenSSL::PKCS7::encrypt([OpenSSL::X509::Certificate.new(PAYPAL_CERT_PEM)], signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"),        OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")
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
