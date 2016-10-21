class PaymentsController < ApplicationController
  def checkout
    begin
      charge = Stripe::Charge.create(
        :source => params[:stripeToken],
	      :amount => 500,
	      :currency => "usd"
      )
      current_user.update!(is_pro: true)
      flash[:notice] = "You are now a pro user! Thank you!"
      ContactMailer.receipt(current_user.email, charge[:id]).deliver_now!
      redirect_to '/'
    rescue => e
      flash[:notice] = e.message
      redirect_to '/pricing'
    end
  end
end
