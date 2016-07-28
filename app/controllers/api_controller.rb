class ApiController < ApplicationController

  # protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token, :only => [:smell_report_create]


  # POST /api/v1/smell_reports
  #
  # PARAMS
  # "latitude" : Double *
  # "longitude" : Double *
  # "user_hash" : String *
  # "smell_value" : Integer *
  # "smell_description" : String
  # "feelings_symptoms" : String
  # "horizontal_accuracy" : Double
  # "vertical_accuracy" : Double
  # "submit_achd_form" : Boolean
  # "email" : String
  #
  def smell_report_create
    smell_report = SmellReport.new
    smell_report.latitude = params["latitude"].to_f unless params["latitude"].blank?
    smell_report.longitude = params["longitude"].to_f unless params["longitude"].blank?
    smell_report.user_hash = params["user_hash"] unless params["user_hash"].blank?
    smell_report.smell_value = params["smell_value"].to_i unless params["smell_value"].blank?
    smell_report.smell_description = params["smell_description"] unless params["smell_description"].blank?
    smell_report.feelings_symptoms = params["feelings_symptoms"] unless params["feelings_symptoms"].blank?
    smell_report.horizontal_accuracy = params["horizontal_accuracy"] unless params["horizontal_accuracy"].blank?
    smell_report.vertical_accuracy = params["vertical_accuracy"] unless params["vertical_accuracy"].blank?
    smell_report.submit_achd_form = params["submit_achd_form"] unless params["submit_achd_form"].blank?

    if smell_report.save
      # success
      response = {
        :latitude => smell_report.latitude,
        :longitude => smell_report.longitude,
        :user_hash => smell_report.user_hash,
        :smell_value => smell_report.smell_value,
        :smell_description => smell_report.smell_description,
        :feelings_symptoms => smell_report.feelings_symptoms,
        :horizontal_accuracy => smell_report.horizontal_accuracy,
        :vertical_accuracy => smell_report.vertical_accuracy
      }
      # send push notifications for specific smell values (1-5)
      FirebasePushNotification.push_smell_report_to_topic(smell_report, "/topics/SmellReport-#{smell_report.smell_value}")
      # send email
      if smell_report.submit_achd_form
        # TODO mailer
        #if params["email"].blank?
      end
    else
      # fail
      response = {
        :error => "failed to create smell report from submitted form."
      }
    end

    render :json => response, :layout => false
  end


  # GET /api/v1/smell_reports
  #
  # PARAMS: none
  #
  def smell_report_index
    start_time = params["start_time"]
    end_time = params["end_time"]
    aggregate = params["aggregate"]
    timezone_offset = params["timezone_offset"]

    if start_time
      start_datetime = Time.at(start_time.to_i).to_datetime if start_time
    else
      start_datetime = Time.at(SmellReport.first.created_at).to_datetime
    end

    if end_time
      end_datetime = Time.at(end_time.to_i + 1).to_datetime if end_time
    else
      end_datetime = Time.now.to_datetime
    end

    @reports = SmellReport.where(:created_at => start_datetime...end_datetime).order('created_at ASC')

    if aggregate == "created_at"
        reports_aggr = []
        offset_str = "+00:00"
        if timezone_offset
            a = timezone_offset.to_i
            # Convert the timezone offset returned from JavaScript
            # to a string for ruby's localtime method
            timezone_sign = ((a <=> 0) ? "-" : "+").to_s # reverse the sign
            timezone_hr = (a.abs/60).to_s.rjust(2, "0") # get the hour part
            timezone_min = (a.abs%60).to_s.rjust(2, "0") # get the minute part
            offset_str = timezone_sign + timezone_hr + ":" + timezone_min
        end
        start_datetime.to_date.upto(end_datetime.to_date).each do |date|
            date_str = date.to_s
            reports_aggr << @reports.select{|u| u.created_at.utc.localtime(offset_str).to_date.to_s == date_str}
            #Rails.logger.info(date.to_s)
        end
        # Convert created_at to utc time string
        for i in 0..reports_aggr.size()-1
            for j in 0..reports_aggr[i].size()-1
                reports_aggr[i][j].created_at = reports_aggr[i][j].created_at.utc.to_s
            end
        end
        @reports = reports_aggr
    elsif aggregate == "month"
        reports_aggr = SmellReport.order('created_at ASC').group("year(created_at)").group("month(created_at)").count
        @reports = {month: reports_aggr.keys}
    end

    render :json => @reports.to_json(:only => [:month, :latitude, :longitude, :smell_value, :smell_description, :feelings_symptoms, :created_at])
  end

end
