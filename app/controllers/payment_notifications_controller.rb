class PaymentNotificationsController < ApplicationController
  protect_from_forgery :except => [:create]
  def create
    params.each { |k, v| params[k] = v.force_encoding('ISO-8859-1').encode('UTF-8') }
    PaymentNotification.create!(:params => params, :user_id => params[:invoice], :status => params[:payment_status], :transaction_id => params[:txn_id])
    User.find(params[:invoice]).create_upgrading! source: 'paypal'
    render :nothing => true
  end
end
