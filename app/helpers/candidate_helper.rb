module CandidateHelper
  def invitation_mail(key)
    mail_to 'candidate@email.com', target: '_blank', body: body(key), cc: "adi.bartal@klarna.com", subject: 'Klarna Home Exercise' do
      image_tag 'mail', class: 'envelope'
    end
  end

  private

  def body(key)
    <<-BODY
 Hello ___CANDIDATE_NAME___________

 Thanks for taking the time to interview with Klarna. We really enjoyed meeting you and you seem like a good fit so we'd like to continue the process.

 As you may recall, the next step is a short programming exercise, which is available at http://www.klarnaisrael.com/exercise
 As we've discussed, the aim of the home exercise is to give you a chance to show us your programming style and abilities in a non-stressful environment.

 Your API key is: #{key}

 We encourage you to use the language and technologies that you feel most comfortable with. We can handle anything you throw at us.

 There's no pressure, but the sooner you hand this in the sooner we can progress ever onwards. Do let us know if you have any questions.

 Enjoy & Good Luck!

 ____YOUR_NAME___________

   BODY
  end
end
