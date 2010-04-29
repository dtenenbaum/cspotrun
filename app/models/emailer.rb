class Emailer < ActionMailer::Base
  

  def notify_success(url, job)
    subject    "CSpotRun Job ##{job.id} has completed successfully!"
    recipients job.email
    bcc SYSADMIN_EMAIL
    hostname = `hostname`.chomp.downcase
    from       "cspotrun-noreply@#{hostname}"
    sent_on    Time.now
    body :url => url, :job => job
  end

end
