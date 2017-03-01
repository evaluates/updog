class PaymentsController < ApplicationController
  def checkout
    @price = session[:price].to_f
    begin
      charge = Stripe::Charge.create(
        :source => params[:stripeToken],
	      :amount => (@price * 100).to_i,
	      :currency => "usd"
      )
      current_user.update!(is_pro: true)
      current_user.create_upgrading! source: 'stripe', price: (@price / 100.to_f)
      flash[:notice] = "Card charged successfully!"
      ContactMailer.receipt(current_user.email, charge[:id], @price).deliver_now!
      redirect_to '/thanks'
    rescue => e
      flash[:notice] = e.message
      redirect_to '/pricing'
    end
  end
end
