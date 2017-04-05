class ReviewsController < ApplicationController
  def new
    @stars = params[:stars].to_i
    @review = Review.new
  end
  def create
    @review = Review.create(review_params)
    if current_user
      @review.update(user_id: current_user.id)
      Drip.event current_user.email, "left a review"
    end
    flash[:notice] = 'Thanks for your review!'
    redirect_to root_path
  end
  private
  def review_params
    params.require(:review).permit(:comment, :rating)
  end
end
