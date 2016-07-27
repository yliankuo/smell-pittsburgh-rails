class FirebasePushNotification < ActiveRecord::Base


	def self.GLOBAL_TOPIC
		"/topics/GlobalTopic"
	end

	def self.FIREBASE_AUTH_KEY
		"DO-NOT-PUSH-ME"
	end

	def self.FIREBASE_URL
		"https://fcm.googleapis.com/fcm/send"
	end


	def self.push_global(title, body, options=nil)
		send_push_notification(self.GLOBAL_TOPIC, title, body, options)
	end


	private def self.send_push_notification(to, title, body, options=nil)
		json = {}
		json["to"] = to
		json["notification"] = {
			"sound" => "default",
			"click_action" => "FCM_PLUGIN_ACTIVITY",
			"icon" => "fcm_push_icon"
		}
		json["notification"]["title"] = title
		json["notification"]["body"] = body

		# TODO add data
		json["data"] = {}

		# this is important so that devices get message in notification tray from background
		json["priority"] = "high"

		# HTTP request and response handler
		request = "POST"
		headers = '-H "Content-Type:application/json" -H "Authorization:key=' + self.FIREBASE_AUTH_KEY + '"'
		url = self.FIREBASE_URL
		data = json.to_json
		response = `curl -X POST #{headers} "#{url}" -d '#{data}'`
		begin
			json_response = JSON.parse(response)
			unless json_response["message_id"].blank?
				Rails.logger.info("Successfully sent push with id=#{json_response["message_id"]}")
				return
			end
		end
	end

end
