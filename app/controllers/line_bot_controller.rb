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

      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.text == "説明"
            #全体の使い方
            message = {
              type: 'text',
              text: "下記から選択ください！\n\n①今日の予定を知りたい ⇒ 今日の予定\n②予定を追加したい ⇒ 予定追加"
            }
          elsif event.text == "今日の予定"
            #今日の予定がリクエスト
            #今日の予定をDBより抽出
            today_calendar = Calendar.where(user: user, date: Date.today.strftime('%Y%m%d')).select("content")

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
              text: "#{date}の予定\n#{today_plans}"
            }
          elsif event.text == "追加"
            #予定追加する際の、送信内容を送信
            message = {
              type: 'text',
              text: "下記に倣って、送信ください！\n\n追加\n日付（半角数字8桁）\n内容"
            }
          elsif event.text.slice(0,2) == "追加"
            #予定追加のリクエスト
            user = event['source']['userId']
            date = event.text.slice(3,8)
            content = event.text.slice(12..)
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
              text: "下記から選択ください！\n①予定を追加したい ⇒ 予定追加\n②今日の予定を知りたい ⇒ 今日の予定"
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

end
