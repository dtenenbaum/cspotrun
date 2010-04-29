class Emailer < ActionMailer::Base
  

  def notify_success(url, job, filesize)
    subject    "CSpotRun Job ##{job.id} has completed successfully!"
    recipients job.email
    bcc SYSADMIN_EMAIL
    hostname = `hostname`.chomp.downcase
    from       "cspotrun-noreply@#{hostname}"
    sent_on    Time.now
    body :url => url, :job => job, :filesize => filesize
  end

  def notify_failure(job, event, tail)
    subject "ERROR: An instance of CSpotRun Job ##{job.id} has failed!!!!"
    recipients job.email
    bcc SYSADMIN_EMAIL
    hostname = `hostname`.chomp.downcase
    from       "cspotrun-noreply@#{hostname}"
    sent_on    Time.now
    body :job => job, :event => event, :tail => tail, :instance => Instance.find(event.instance_id)
  end

end
