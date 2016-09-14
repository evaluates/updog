class ContactMailer < ActionMailer::Base
  default from: "<noreply@yourdomain.com>"
  default to: "Jesse Shawl <jesse@jshawl.com>"
  def new_message(message)
    @message = message
    mail subject: "Message from #{message.name}"
  end
end