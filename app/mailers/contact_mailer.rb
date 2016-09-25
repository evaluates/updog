class ContactMailer < ActionMailer::Base
  default from: "noreply@updog.co"
  default to: "Jesse Shawl <jesseshawl@gmail.com>"
  def new_message(message)
    @message = message
    mail subject: "Message from #{message['email']}", reply_to: message['email']
  end
end