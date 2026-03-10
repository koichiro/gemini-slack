require 'test_helper'

class GeminiCLITest < Minitest::Test
  def setup
    # 環境変数のモック
    ENV['SLACK_TOKEN'] = 'test-token'
    ENV['SLACK_CHANNEL_ID'] = 'C123'
    ENV['GCP_PROJECT_ID'] = 'test-project'

    # クライアント初期化のモック
    @mock_slack = mock('slack_client')
    Slack::Web::Client.stubs(:new).returns(@mock_slack)
    
    @mock_ai = mock('ai_client')
    Google::Cloud::AIPlatform.stubs(:prediction_service).returns(@mock_ai)

    # 標準出力をキャプチャしてテスト実行時の出力を抑制
    @cli = Gemini::CLI.new
  end

  def test_initialize
    assert_equal 'C123', @cli.instance_variable_get(:@channel_id)
    assert_equal 'test-project', @cli.instance_variable_get(:@project_id)
  end

  def test_post_to_slack
    @mock_slack.expects(:chat_postMessage).with(
      channel: 'C123',
      text: "👤 *User*:\nHello",
      thread_ts: nil
    ).returns({ 'ts' => '12345.678' })

    response = @cli.send(:post_to_slack, "Hello", role: :user)
    assert_equal '12345.678', response['ts']
  end

  def test_ask_gemini_success
    # チャンクのシミュレーション
    chunk = mock('chunk')
    chunk.stubs(:data).returns({
      "candidates" => [{
        "content" => { "parts" => [{ "text" => "Hello from Gemini" }] }
      }]
    }.to_json)

    @mock_ai.expects(:stream_raw_predict).returns([chunk])

    answer = @cli.send(:ask_gemini, "Hi")
    assert_equal "Hello from Gemini", answer
    
    # 履歴の確認
    history = @cli.instance_variable_get(:@history)
    assert_equal 2, history.size
    assert_equal "Hi", history[0][:parts][0][:text]
    assert_equal "Hello from Gemini", history[1][:parts][0][:text]
  end

  def test_ask_gemini_error
    @mock_ai.expects(:stream_raw_predict).raises(StandardError.new("API Error"))

    answer = @cli.send(:ask_gemini, "Hi")
    assert_match(/Error: API Error/, answer)
  end

  def test_process_question
    # 標準出力を一時的に捨てる
    @cli.stubs(:puts)
    @cli.stubs(:print)

    # post_to_slack と ask_gemini を組み合わせてテスト
    @cli.expects(:post_to_slack).with("Hi", role: :user, thread_ts: nil).returns({ 'ts' => '999' })
    @cli.expects(:ask_gemini).with("Hi").returns("Response")
    @cli.expects(:post_to_slack).with("Response", role: :model, thread_ts: '999')

    @cli.send(:process_question, "Hi")
  end
end
