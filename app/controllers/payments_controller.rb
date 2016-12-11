class PaymentsController < ApplicationController
  def checkout
    @price = ab_test(:price, '4.99', '5', '9.99', '14.99', '19.99').to_f
    begin
      charge = Stripe::Charge.create(
        :source => params[:stripeToken],
	      :amount => @price * 100,
	      :currency => "usd"
      )
      current_user.update!(is_pro: true)
      current_user.create_upgrading! source: 'stripe', price: (@price / 100.to_f)
      flash[:notice] = "Card charged successfully!"
      ContactMailer.receipt(current_user.email, charge[:id]).deliver_now!
      redirect_to '/thanks'
    rescue => e
      flash[:notice] = e.message
      redirect_to '/pricing'
    end
  end
end
