class WebhookController < ApplicationController
  protect_from_forgery except: :post
  def challenge
    respond_to do |format|
      c =  params[:challenge]
      format.all { render :html => c, :layout => false }
    end
  end
  def post
    users = params["delta"]["users"]
    users.each do |uid|
      begin
        identity = Identity.find_by(uid: uid)
        Drip.event(identity.email, "Edited a file in dropbox")
      rescue
      end
    end
    render nothing: true
  end
end
