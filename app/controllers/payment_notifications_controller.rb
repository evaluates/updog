class PaymentNotificationsController < ApplicationController
  protect_from_forgery :except => [:create]
  def create
    unless paypal_verify params
      p params
      p 'paypal failed verification'
      return render nothing: true
    end
    if params[:txn_type] == 'subscr_payment'
      @user = User.find(params[:custom])
      PaymentNotification.create!(params: params, user_id: @user.id, payer_id: params[:payer_id])
      @user.update(is_pro: true)
      Upgrading.create!(user:@user)
    end
    if ['subscr_cancel','subscr_eot','subscr_failed'].include? params[:txn_type]
      pn = PaymentNotification.find_by(payer_id: params[:payer_id])
      @user = pn.user
      @user.update(is_pro: false)
    end
    render nothing: true
  end
  def paypal_verify params
    query = 'cmd=_notify-validate'
    params.each_pair {|key, value| query = query + '&' + key + '=' + URI.encode(value) if key != 'register/pay_pal_ipn.html/pay_pal_ipn' }
    paypal_url = ENV['paypal_host']+"?#{query}"
    HTTParty.post(paypal_url).body == "VERIFIED"
  end
end
