#-- vim:sw=2:et
#++
#
# :title: A.L.I.C.E chatbot plugin
#
# Author:: Casey Link <unnamedrambler@gmail.com>
# Copyright:: (C) 2008 Casey Link
#
# Uses www.pandorabots.com to "unleash virtual personalities" on irc.

class AlicePlugin < Plugin
  Config.register Config::BooleanValue.new('alice.enabled',
    :default => false,
    :desc => "Enable and disable the plugin")
  Config.register Config::StringValue.new('alice.botid',
    #:default => "a211adf15e36b67b",
    :default => "923c98f3de35606b", #God
    :desc => "The pandorabot.com botid.")

  def initialize
    super
    @custid = nil
    class << @registry
      def store(val)
        val
      end
      def restore(val)
        val
      end
    end
  end

  def help(plugin, topic="")
    "alice plugin: a chatbot that uses bots from pandorabot.com. usage: alice <statement> will send the statement to the bot. alice enable/disable will toggle the bot's responses on or off. alice status to see the status of the bot. to change which bot is being talked to edit the alice.botid config value."
  end

  def ask_question(m, params)
    return unless @bot.config['alice.enabled']
    return unless @bot.config['alice.botid']
    question = params[:question].to_s
    botid = @bot.config['alice.botid']
    uri = "http://www.pandorabots.com/pandora/talk-xml"
    botid = "botid=#{botid}"
    input = "input=#{CGI.escape(question)}"
    
    body = nil
    if @registry.has_key?( m.sourcenick )
      custid = "custid=#{@registry[ m.sourcenick ]}"
      body = [botid,custid,input].join("&")
    else
      body = [botid,input].join("&")
    end

    response = @bot.httputil.post(uri, body)
    debug response
    if response.class == Net::HTTPOK
      xmlDoc = REXML::Document.new(response.body)
      status = xmlDoc.elements["result"].attributes["status"]
      custid = xmlDoc.elements["result"].attributes["custid"]
      unless @registry.has_key?( m.sourcenick )
        @registry[ m.sourcenick ] = custid
      end
      case status
      when "0"
        m.reply xmlDoc.elements["result/that"].get_text.value.ircify_html
      else
        m.reply "Say again?"
      end
    else
      m.reply "Excuse me?" # the http request failed
    end
  end

  def enable(m, params)
    @bot.config['alice.enabled'] = true
    m.okay
  end

  def disable(m, params)
    @bot.config['alice.enabled'] = false
    m.okay
  end

  def status(m, params)
    msg = "Alice is "
    if @bot.config['alice.enabled']
      msg << "enabled. "
    else
      msg << "disabled. "
    end
    msg << "Currently using bot #{@bot.config['alice.botid']}."
    m.reply msg
  end

end    

plugin = AlicePlugin.new
plugin.map 'alice enable', :action => "enable"
plugin.map 'alice disable', :action => "disable"
plugin.map 'alice status', :action => "status"
plugin.map 'alice *question', :action => "ask_question", :threaded => true

