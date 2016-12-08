class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:contact_create, :feedback_create]

  PAYPAL_CERT_PEM = File.read("#{Rails.root}/certs/paypal_cert.pem")
  APP_CERT_PEM = File.read("#{Rails.root}/certs/app_cert.pem")
  APP_KEY_PEM = File.read("#{Rails.root}/certs/app_key.pem")

  def about
  end

  def faq

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

  def pricing
    @current_user = current_user
    @paypal_url = ENV['paypal_url']
    @encrypted = paypal_encrypted
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
	u.created_at - u.user.created_at
      }
      @users = User.group("DATE(created_at)").count
      @users = @users.map{|k,v|
        k = k.to_time.to_i * 1000
        [k, v]
      }.sort_by{|k| k[0]}
      @sites = Site.created_today
      @popular_sites = Site.popular

      @revenue = User.where(is_pro: true).count * 5
      @avg_pro_time = upgrade_times.inject{|sum,el| sum + el}.to_f / upgrades.count
      @mean_pro_time = median upgrade_times
      @pct_new_pro = ((new_users.where(is_pro:true).count.to_f / new_users.count.to_f) * 100).round(2)
      @num_users = User.all.count
      @paying_users = pros.count
      @stats = Stat.all
      @pct_pro = @stats.map{|stat| [stat.date.to_i * 1000, stat.percent_pro] }
      @daily_revenue = @stats.map{|stat| [stat.date.to_i * 1000, stat.new_upgrades * 5] }
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
