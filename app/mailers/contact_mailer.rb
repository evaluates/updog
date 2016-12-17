class ContactMailer < ActionMailer::Base
  default from: "jesse@updog.co"
  default to: "Jesse Shawl <jesse@updog.co>"
  def new_message(message)
    @message = message
    mail subject: "Message from #{message['email']}", reply_to: message['email']
  end
  def notify(cc)
    mail subject: "Updog.co payment failed", to: cc, cc: 'jesse@updog.co'
  end
  def send_welcome(email)
    mail subject: "Welcome to UpDog!", to: email
  end
  def receipt(email, id, price)
    @id = id
    @time = Time.now
    @price = price
    mail subject: "UpDog Payment Receipt", to: email
  end
  def user_mailer(email, link, input)
    @input = input
    @link = link
    mail subject: "New message from #{link}", to: email, from: "#{link} <jesse@updog.co>"
  end
  def daily_summary
    @users = User.created_today
    @sites = Site.created_today
    @popular_sites = Site.popular
    mail subject: "UpDog.co Daily Summary"
  end
  def feedback_create params
    @how = params[:how]
    @email = params[:email]
    mail subject: "UpDog.co Feedback", reply_to: @email
  end
end
