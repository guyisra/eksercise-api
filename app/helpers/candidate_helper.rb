# frozen_string_literal: true

module CandidateHelper
  def invitation_mail(key, template)
    mail_to 'candidate@email.com', target: '_blank', body: body(template, key), cc: 'adi.bartal@klarna.com', subject: 'Klarna Home Exercise' do
      image_tag asset_path('mail.svg'), class: 'envelope'
    end
  end

  private

  def body(template, key)
    ERB.new(template).result(binding)
  end
end
