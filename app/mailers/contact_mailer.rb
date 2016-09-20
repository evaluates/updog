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
end
