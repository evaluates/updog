class ReviewsController < ApplicationController
  def new
    @stars = params[:stars].to_i
    @review = Review.new
  end
  def create
    @review = Review.create(review_params.merge(user: current_user))
    Drip.event current_user.email, "left a review" if current_user
    flash[:notice] = 'Thanks for your review!'
    redirect_to root_path
  end
  private
  def review_params
    params.require(:review).permit(:comment, :rating)
  end
end
