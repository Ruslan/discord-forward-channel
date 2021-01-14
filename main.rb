require 'rubygems'
require 'httparty'
require 'json'
require 'pry'
require 'yaml'


class DiscordRepost
  def initialize(channel_to, channel_from, bot_token, user_cookie, user_token)
    @channel_to = channel_to
    @channel_from = channel_from
    @bot_token = bot_token
    @user_cookie = user_cookie
    @user_token = user_token
  end

  def get_fresh
    headers = ['authority: discord.com',
      "authorization: #{@user_token}",
      'accept-language: ru',
      'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36',
      'accept: */*',
      'sec-fetch-site: same-origin',
      'sec-fetch-mode: cors',
      'sec-fetch-dest: empty',
      "referer: https://discord.com/channels/#{@channel_from}/#{@channel_from}",
      "cookie: #{@user_cookie}"]
    headers = headers.map { |h| h.split(':', 2) }.to_h
    data = HTTParty.get("https://discord.com/api/v8/channels/#{@channel_from}/messages?limit=50", headers: headers)
    data.parsed_response
  end

  def post_msg(msg)
    data = HTTParty.post(
      "https://discord.com/api/channels/#{@channel_to}/messages",
      headers: { 'Authorization' => "Bot #{@bot_token}", "Content-type" => "application/json" },
      debug_output: $stdout,
      body: { content: msg }.to_json
    )
  end

  def call
    data = get_fresh
    return unless get_fresh[0]
    @last = get_fresh[0]['id'] unless @last
    new_msg = data.select  { |x| x['id'].to_i > @last.to_i }
    new_msg_list = new_msg.map { |msg| msg_to_string(msg) }.reverse.join("\n")
    @last = get_fresh[0]['id']
    @base_nonce = @last.to_i
    if new_msg_list.to_s.size > 0
      puts "send #{new_msg_list}"
      post_msg(new_msg_list)
    end
    puts "last msg: #{@last}"
  end

  def msg_to_string(msg)
    content = msg['content']
    content.gsub!(/<@!?(\d+)>/) do |a|
      "#{msg['mentions'].find { |m| m['id'] == $1 }&.dig('username') || $1 }"
    end
    "**#{msg['author']['username']}**: #{content}"
  end
end

f = YAML.safe_load(File.read('config.yaml'))
auth = f['auth']
channels = f['channels'].map do |channel|
  DiscordRepost.new(channel['to'], channel['from'], auth['bot_token'], auth['user_cookie'], auth['user_token'])
end

loop do
  channels.map(&:call)
  sleep 3
end
