class AchdMailer < ApplicationMailer

  default :from => "smellpgh-reports@cmucreatelab.org",
          :to => ACHD_EMAIL_RECIPIENT,
          :content_type => "text/plain"


  # ASSERT: zipcode is not blank and is a zipcode in Allegheny County
  # ASSERT: achd_form does not need to be a saved record (and should not be)
  def email(achd_form,street_address=nil,zipcode)
    @smell_report = achd_form.smell_report
    @street_address = street_address
    @zipcode = zipcode
    @phone_number = achd_form.phone
    @name = achd_form.name.blank? ? "Smell PGH App User (id: #{@smell_report.anonymized_user_hash})" : achd_form.name
    @address = achd_form.address

    mail(:subject => "Smell Report")
  end

end
