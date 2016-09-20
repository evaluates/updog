class SubscriptionsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:hook, :update_card]
  def checkout
    begin
      @amount = 10
      charge = Stripe::Customer.create(
        :source => params[:stripeToken],
        :plan => 'Pro'
      )
      current_user.subscriptions.create(
        stripe_id: charge[:id],
        active_until: DateTime.strptime(charge[:created].to_s,'%s') + 1.month
      )
      flash[:notice] = "You are now a pro user! Thank you!"
      redirect_to '/'
    rescue => e
      flash[:notice] = e.message
      redirect_to '/pricing'
    end

  end
  def destroy
    customer = Stripe::Customer.retrieve(current_user.subscriptions.first.stripe_id)
    customer.subscriptions.first.delete
    current_user.subscriptions.destroy_all
    redirect_to :back
  end
  def hook
    begin
      event = Stripe::Event.retrieve(params["id"])
      type = event.type
      customer = event.data.object.customer
    rescue => e
      type = "invoice.payment_succeeded"
      customer = User.first.subscriptions.first.stripe_id
    end
    case type
      when "invoice.payment_succeeded" #renew subscription
	      Subscription.find_by_stripe_id(customer).renew
      when "invoice.payment_failed" #renew subscription
	      Subscription.find_by_stripe_id(customer).notify
    end
    render status: :ok, json: "success"
  end
  def update_card
    begin
      customer = Stripe::Customer.retrieve(current_user.subscriptions.first.stripe_id)
      card = customer.sources.create(card: params["stripeToken"])
      card.save
      customer.default_source = card.id
      customer.save
      flash[:notice] = "Card updated successfully!"
    rescue Stripe::InvalidRequestError => e
      flash[:notice] = e.message
    end
    redirect_to '/pricing'
  end
end
