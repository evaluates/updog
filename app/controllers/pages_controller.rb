class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:contact_create, :feedback_create]

  PAYPAL_CERT_PEM = File.read("#{Rails.root}/certs/paypal_cert.pem")
  APP_CERT_PEM = File.read("#{Rails.root}/certs/app_cert.pem")
  APP_KEY_PEM = File.read("#{Rails.root}/certs/app_key.pem")

  def about
  end

  def faq
    @price = '10.00'
  end

  def feedback
  end

  def feedback_create
    ContactMailer.feedback_create(params).deliver_now!
    flash[:notice] = "Feedback sent successfully!"
    redirect_to feedback_path
  end

  def tos
  end

  def account
    if current_user.nil?
      return redirect_to root_path
    end
    identities = current_user.identities
    @google = identities.find_by_provider('google')
    @dropbox = identities.find_by_provider('dropbox')
    @identities = [
      {provider: 'Google', account: @google},
      {provider: 'Dropbox', account: @dropbox}
    ]
  end

  def pricing
    @current_user = current_user
    @paypal_url = ENV['paypal_url']
    @encrypted = paypal_encrypted
    @price = '10.00'
    @reviews = Review.all
    @subscribed = PaymentNotification.where(user_id: current_user.id).any? if current_user && current_user.is_pro
  end

  def paypal_encrypted
    id = current_user ? current_user.id : 0
    values = {
      :business => 'jesse@updog.co',
      :cmd => '_cart',
      :upload => 1,
      :return => ENV['paypal_return'],
      :notify_url => ENV['paypal_notify'],
      :cert_id => ENV['paypal_cert_id'],
      :invoice => id,
      "amount_1" => session[:price],
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
      upgrades = Upgrading.all
      new_users = User.where('created_at > ?', Date.parse('2016-10-17'))
      pros = User.where(is_pro:true)
      upgrade_times = upgrades.map {|u|
        u.created_at - u.user.created_at if u.user
      }.compact
      @users = User.group("DATE(created_at)").count
      @users = @users.map{|k,v|
        k = k.to_time.to_i * 1000
        [k, v]
      }.sort_by{|k| k[0]}
      @sites = Site.created_today
      @popular_sites = []#Site.popular
      @avg_pro_time = upgrade_times.inject{|sum,el| sum + el}.to_f / upgrades.count
      @mean_pro_time = median upgrade_times
      @num_users = User.count
      @paying_users = pros.count
      @stats = Stat.order("created_at DESC").limit(70)
      # @pct_pro = @stats.map{|stat| [stat.date.to_i * 1000, stat.percent_pro] }
      @stats_by_week = {}
      @stats.each do |stat|
        ts = stat.date.beginning_of_week.to_i * 1000
        @stats_by_week[ts] ||= {}
        @stats_by_week[ts][:new_users] ||= 0
        @stats_by_week[ts][:new_users] += stat.new_users
        @stats_by_week[ts][:new_upgrades] ||= 0
        @stats_by_week[ts][:new_upgrades] += stat.new_upgrades
        @stats_by_week[ts][:percent_pro] = stat.percent_pro
      end
      # @daily_revenue = @weekly_revenue.to_a

      if params[:email]
        @user = User.find_by(email: URI.decode(params[:email]))
      end
    else
      redirect_to root_path
    end
  end
  def median(array)
    sorted = array.sort
    len = sorted.length
    begin
      (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    rescue
      0
    end
  end

end
