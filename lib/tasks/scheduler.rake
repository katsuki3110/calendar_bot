desc "This task is called by the Heroku scheduler add-on"
task :push_notificate => :environment do
  #リマインドメッセージの初期化
  remind_message = ""
  remind_users = Calendar.where(date: Date.tomorrow.strftime('%Y%m%d')).select("user").distinct

  if remind_users.present?
    for i in 0..remind_users.count - 1 do
      #userを一つづつ処理する
      remind_user = remind_users[i].user
      remind_calendars = Calendar.where(user: remind_user)

      for j in 0..remind_calendars.count - 1 do
        #各userのcontent毎に処理する
        remind_content = remind_calendars[j].content
        if j == 0
          remind_message = "・" + remind_content
        else
          remind_message = remind_message + "\n・" + remind_content
        end
      end

      message = {
        type: 'text',
        text: "明日の予定は、\n\n" + remind_message + "\n\nです！"
      }
      client ||= Line::Bot::Client.new {|config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
      #プッシュ通知送信
      client.push_message(remind_user, message)

    end
  end

end
