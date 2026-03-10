require 'slack-ruby-client'
require 'google/cloud/ai_platform'
require 'google/api/httpbody_pb'
require 'reline'
require 'json'

module Gemini
  class CLI
    def initialize
      # Slack クライアント初期化
      Slack.configure { |config| config.token = ENV['SLACK_TOKEN'] }
      @slack_client = Slack::Web::Client.new
      @channel_id = ENV['SLACK_CHANNEL_ID']

      # Vertex AI Gemini クライアント初期化
      @location = ENV['GCP_LOCATION'] || 'us-central1'
      @project_id = ENV['GCP_PROJECT_ID']
      @model_id = ENV['GCP_MODEL_ID'] || 'gemini-1.5-flash'
      @ai_client = Google::Cloud::AIPlatform.prediction_service(region: @location)
      @endpoint = "projects/#{@project_id}/locations/#{@location}/publishers/google/models/#{@model_id}"

      # セッション状態
      @history = []
    end

    def start
      puts "🚀 Gemini Slack CLI Started (Type 'exit' or 'quit' to stop)"
      puts "Target Slack Channel: #{@channel_id}"
      puts "--------------------------------------------------"

      loop do
        input = Reline.readline("input > ", true)
        break if input.nil? || ['exit', 'quit'].include?(input.downcase)
        next if input.strip.empty?

        process_question(input)
      end

      puts "Session ended."
    end

    private

    def process_question(input)
      # 1. Slackにユーザーの質問を送信して新規スレッドを作成
      response = post_to_slack(input, role: :user, thread_ts: nil)
      thread_ts = response['ts']

      # 2. Geminiで回答生成
      print "Gemini is thinking..."
      answer = ask_gemini(input)
      print "\r" # "Thinking..." を消去

      # 3. ターミナルに表示
      puts "Gemini: #{answer}"
      puts "--------------------------------------------------"

      # 4. 同じスレッドにGeminiの回答を投稿
      post_to_slack(answer, role: :model, thread_ts: thread_ts)
    end

    def post_to_slack(text, role:, thread_ts: nil)
      prefix = role == :user ? "👤 *User*" : "🤖 *Gemini*"
      payload = {
        channel: @channel_id,
        text: "#{prefix}:\n#{text}",
        thread_ts: thread_ts
      }
      @slack_client.chat_postMessage(**payload)
    end

    def ask_gemini(input)
      # 今回の質問を履歴に追加
      @history << { role: 'user', parts: [{ text: input }] }

      parameters = { temperature: 0.7, maxOutputTokens: 2048 }

      begin
        response = @ai_client.stream_raw_predict(
          endpoint: @endpoint,
          http_body: Google::Api::HttpBody.new(data: { contents: @history, generationConfig: parameters }.to_json)
        )

        full_answer = ""
        response.each do |chunk|
          data = JSON.parse(chunk.data)
          part = data.dig("candidates", 0, "content", "parts", 0, "text")
          full_answer += part if part
        end

        # モデルの回答を履歴に追加
        @history << { role: 'model', parts: [{ text: full_answer }] }
        full_answer
      rescue => e
        "Error: #{e.message}"
      end
    end
  end
end
