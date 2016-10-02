class SubscriptionsController < ApplicationController
  def checkout
    @amount = 10
    charge = Stripe::Customer.create(
      :source => params[:stripeToken],
      :plan => 'Pro'
    )
    current_user.subscriptions.create(
      stripe_id: charge[:id],
      active_until: DateTime.strptime(charge[:created].to_s,'%s') + 1.month
    )
    flash[:notice] = "Successfully created a charge"
    redirect_to '/'
  end
  def destroy

    customer = Stripe::Customer.retrieve(current_user.subscriptions.first.stripe_id)
    customer.subscriptions.first.delete
    current_user.subscriptions.destroy_all
    redirect_to :back
  end
end
