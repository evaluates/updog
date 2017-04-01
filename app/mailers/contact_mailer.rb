class ContactMailer < ActionMailer::Base
  default from: "jesse@updog.co"
  default to: "Jesse Shawl <jesse@updog.co>"
  def new_message(message)
    @message = message
    mail subject: "Message from #{message['email']}", reply_to: message['email']
  end
  def user_mailer(email, link, input)
    @input = input
    @link = link
    mail subject: "New message from #{link}", to: email, from: "#{link} <jesse@updog.co>"
  end
  def feedback_create params
    @how = params[:how]
    @email = params[:email]
    mail subject: "UpDog.co Feedback", reply_to: @email
  end
end
