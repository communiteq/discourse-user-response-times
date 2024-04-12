class ResponseTimeCalculator

  def self.update_response_times
    existing_user_ids = UserCustomField.where(name: "response_time_seconds").pluck("user_id")

    DB.query(<<~SQL, percentile: SiteSetting.user_response_times_percentile, days: SiteSetting.user_response_times_days).each do |response_obj|
      SELECT
        user_id,
        EXTRACT(epoch FROM AVG(response_time))::int AS avg_response_seconds,
        EXTRACT(epoch FROM percentile_cont(:percentile/100.0) WITHIN GROUP (ORDER BY response_time))::int AS perc_response_seconds
      FROM
      (
        WITH FilteredTopics AS (
            SELECT
                id,
                user_id,
                created_at
            FROM topics
            WHERE created_at > CURRENT_DATE - INTERVAL ':days days'
              AND archetype = 'private_message'
              AND user_id NOT IN (SELECT id FROM users WHERE admin = true)
        ),
        RelevantPosts AS (
            SELECT
                ft.id AS topic_id,
                p.user_id,
                p.post_number,
                p.created_at - ft.created_at AS response_time
            FROM FilteredTopics ft
            JOIN posts p ON ft.id = p.topic_id
            WHERE p.user_id <> ft.user_id
              AND p.post_type = 1
              AND p.user_id NOT IN (SELECT id FROM users WHERE admin = true)
              AND p.user_id > 0
        )
        SELECT DISTINCT ON (topic_id)
            topic_id,
            user_id,
            post_number,
            response_time
        FROM
            RelevantPosts
        ORDER BY
            topic_id,
            post_number ASC
      ) response_time_per_topic
      GROUP BY user_id;
    SQL
      user = User.find(response_obj.user_id)
      if user
        existing_user_ids -= [user.id]
        case SiteSetting.user_response_times_mode
        when "percentile"
          response_time = response_obj.perc_response_seconds
        when "average"
          response_time = response_obj.avg_response_seconds
        end
        user.custom_fields["response_time_seconds"] = response_time
        user.save_custom_fields
      end
    end

    # clean up old records that were left behind
    UserCustomField.where(name: "response_time_seconds").where(user_id: [existing_user_ids]).delete_all
  end
end
