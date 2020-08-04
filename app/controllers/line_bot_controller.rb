class LineBotController < ApplicationController

  protect_from_forgery except: :callback

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    #メッセージ取得
    events = client.parse_events_from(body)
    events.each do |event|

      #説明内容を格納
      explanation = "下記から選択し、送信ください！\n\n①今日の予定を知りたい\n⇒今日の予定\n②予定を追加したい\n⇒予定追加"
      #予定追加時の送信内容
      add_plan = "下記に倣って、送信ください！\n\n'追加'と記載\n日付（半角数字8桁）\n内容"
      #user情報の取得
      user = event['source']['userId']

      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'] == "説明"
            #全体の使い方
            message = {
              type: 'text',
              text: explanation
            }
          elsif event.message['text'] == "今日の予定"

            #今日の予定を一覧で抽出
            #今日の予定をDBより抽出
            today_calendar = Calendar.where(user: user, date: Date.today.strftime('%Y%m%d')).select("content")

            #今日の予定があるか確認
            if today_calendar.present?
              #今日の予定を初期化
              today_plans = ""
              #該当するユーザーの今日の予定内容を抽出
              for num in 0..today_calendar.count - 1 do
                if num == 0
                  today_plans = "・" + today_calendar[num].content
                else
                  today_plans = "#{today_plans}\n・#{today_calendar[num].content}"
                end
              end

              #今日の予定を送信
              message = {
                type: 'text',
                text: today_plans
              }
            else
              #今日の予定がない場合
              message = {
                type: 'text',
                text: "今日の予定はなし！"
              }
            end

          elsif event.message['text'] == "予定追加"
            #予定追加する際の、送信内容を送信
            message = {
              type: 'text',
              text: add_plan
            }

          elsif event.message['text'].slice(0,2) == "追加"
            #予定追加のリクエスト
            date = event.message['text'].slice(3,8)
            content = event.message['text'].slice(12..)
            #リクエストされた予定をDBに保存
            plan = Calendar.new(user: user, date: date, content: content)
            if plan.save
              message = {
                type: 'text',
                text: "追加しました！前日にリマインドしやす！"
              }
            else
              message = {
                type: 'text',
                text: "送信された内容に不備があります。もう一度送信ください。"
              }
            end

          else
            message = {
              type: 'text',
              text: explanation
            }
          end
        end
        client.reply_message(event['replyToken'], message)
      end
    end

  end


  private

    def client
      @client ||= Line::Bot::Client.new {|config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end

    def push_notification
      #リマインドメッセージの初期化
      remind_message = ""
      remind_users = Calendar.select("user").dinstinct

      for i in 0..remind_users.count - 1 do
        #userを一つづつ処理する
        remind_user = remind_users[i].user
        remind_calendars = Calendar.where(user: remind_user)

        for j in 0..remind_calendars.count - 1 do
          #各userのcontent毎に処理する
          remind_content = remind_calendars[j].content
          if num == 0
            remind_message = "・" + remind_content
          else
            remind_message = remind_message + "\n・" + remind_content
          end
        end

        message = {
          to:   remind_user,
          type: 'text',
          text: remind_message
        }
        #プッシュ通知送信
        client.reply_message(event['replyToken'], message)

      end
    end


end
