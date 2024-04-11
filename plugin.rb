# name: discourse-user-response-times
# about: Show the average PM response time for a user
# meta_topic_id: 1234
# version: 0.1
# authors: Communiteq
# url: https://github.com/communiteq/discourse-user-response-times

enabled_site_setting :user_response_times_enabled

after_initialize do
  add_to_serializer(:user_card, :response_time_seconds) do
    object.custom_fields && object.custom_fields["response_time_seconds"].to_i
  end
end

