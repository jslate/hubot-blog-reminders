# Description:
#   Remind people to write for the PLM Tech Blog
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   None
#
# Notes:
#   None
#
# Author:
#   Jonathan Slate (https://github.com/jslate)

cheerio = require('cheerio')
moment = require('moment')
_ = require('underscore')

module.exports = (robot) ->

  ADJECTIVES = ['apathetic', 'careless', 'dull', 'inattentive', 'indifferent', 'lackadaisical',
  'lethargic', 'passive', 'sleepy', 'tired', 'weary', 'asleep on the job', 'comatose', 'dallying',
  'dilatory', 'drowsy', 'flagging', 'idle', 'indolent', 'inert', 'laggard', 'lagging', 'languid',
  'languorous', 'lifeless', 'loafing', 'neglectful', 'out of it', 'procrastinating', 'remiss',
  'shiftless', 'slack', 'slothful', 'slow', 'slow-moving', 'snoozy', 'somnolent', 'supine', 'tardy',
  'torpid', 'trifling', 'unconcerned', 'unenergetic', 'unindustrious', 'unpersevering', 'unready',
  'counterproductive', 'fruitless', 'futile', 'hopeless', 'impractical', 'incompetent', 'ineffective',
  'ineffectual', 'inoperative', 'meaningless', 'no good', 'pointless',
  'stupid', 'unproductive', 'unworkable', 'worthless', 'bootless', 'disadvantageous',
  'dysfunctional', 'expendable', 'feckless', 'good-for-nothing', 'impracticable', 'inept',
  'inutile', 'nonfunctional', 'profitless', 'purposeless', 'unavailing', 'unfunctional', 'unprofitable',
  'unpurposed', 'vain', 'valueless', 'weak', 'banal', 'hackneyed', 'tedious', 'trite', 'uninspired',
  'bromidic', 'common', 'commonplace', 'derivative', 'dime a dozen', 'dull as dishwater',
  'flat', 'ho hum', 'ordinary', 'pedestrian', 'prosaic', 'routine',
  'square', 'tame', 'uncreative', 'unoriginal', 'well-worn', 'amateurish', 'helpless',
  'inadequate', 'incapable', 'inefficient', 'inexperienced', 'unqualified', 'unskilled', 'useless',
  'amateur', 'raw', 'awkward', 'bungling', 'bush-league', 'clumsy', 'disqualified', 'floundering',
  'inexpert', 'insufficient', 'maladroit', 'out to lunch', 'unadapted',
  'unequipped', 'unfit', 'uninitiated', 'unproficient', 'untrained', 'unevolved']

  PLURAL_NOUNS = ['drifters', 'tramps', 'wanderers', 'beggars', 'bums', 'derelicts', 'transients', 'vagabonds', 'vagrants',
  'winos', 'idiots', 'fools', 'rascals', 'brutes', 'oafs', 'nincompoops',
  'ninnies', 'blockheads', 'dolts', 'dunces', 'imbeciles', 'donkeys', 'dopes', 'numbskulls', 'simpletons', 'twits',
  'jackasses', 'nitwits', 'birdbrains', 'boneheads', 'boobs', 'buffoons', 'clods', 'clowns',
  'dimwits', 'dunderheads', 'fatheads', 'ignoramus', 'jerks', 'lunkheads', 'morons', 'numskulls', 'stooges',
  'lamebrains', 'cheats', 'cheaters', 'delinquents', 'frauds', 'hooligans', 'liars', 'mischief-makers', 'pranksters',
  'rapscallions', 'reprobates', 'rogues', 'rowdies', 'ruffians', 'scalawags', 'scoundrels', 'shysters', 'sneaks',
  'swindlers', 'tricksters', 'troublemakers', 'villains', 'whippersnappers', 'bastards', 'miscreants', 'scamps',
  'blackguards', 'heels', 'lowlives', 'deadbeats', 'defeateds', 'duds', 'failures', 'has-beens', 'goldbricks',
  'good-for-nothings', 'goof-offs', 'idlers', 'loafers', 'quitters', 'slouches', 'avoiders']

  pick_random = (array) -> _.shuffle(array)[0]

  insult = -> "#{pick_random(ADJECTIVES)} #{pick_random(PLURAL_NOUNS)}"

  current_date_str = -> moment().format('YYYY-MM-DD')

  have_reminded_today = -> robot.brain.data.blog_reminders[current_date_str()]?

  reprimand = (days, user_name) ->
    "It's been #{days} days since any of you #{insult()} wrote for the blog! " +
    "Someone should soon, how about... #{user_name}? See https://github.com/patientslikeme/tech-blog"

  praise = (author) ->
    "#{author} recently wrote for the blog, I guess you guys aren't _all_ #{insult()} after all! " +
    "Check it out: http://tech.patientslikeme.com/"

  get_most_recent_post = (callback) ->
    robot.http("http://tech.patientslikeme.com/").get() (err, res, body) ->
      $ = cheerio.load(body)
      date_str = $('.article-metadata').first().find('li').first().text().split(':')[1].trim()
      date = moment(date_str, 'MMM, D YYYY')
      days_since = Math.floor(moment.duration(moment().diff(date)).asDays())
      author = $('.article-metadata').first().find('li').eq(1).text().split(':')[1].trim()
      callback({date: date, days_since: days_since, author: author})

  robot.hear /^(.+)$/i, (response) ->

    robot.brain.data.blog_reminders ||= {}
    robot.brain.data.blog_praises ||= {}
    robot.brain.data.blog_reminders_users ||= {}
    robot.brain.data.blog_reminders_users[current_date_str()] ||= []

    if response.match[1] == 'blog reset'
      response.send "resetting reminder for #{current_date_str()}"
      robot.brain.data.blog_reminders[current_date_str()] = undefined
      get_most_recent_post (post) ->
        response.send "forgetting we know about blog post on #{post.date.format('YYYY-MM-DD')}"
        robot.brain.data.blog_praises[post.date.format('YYYY-MM-DD')] = undefined
    else
      get_most_recent_post (post) ->
        # if it is after 1PM and we haven't been reminded today...
        if moment().hour() > 13
          if !have_reminded_today()
            # if it has been more than 30 days since the last post...
            if post.days_since > 30
              random_user = pick_random(robot.brain.data.blog_reminders_users[current_date_str()])
              robot.brain.data.blog_reminders[current_date_str()] = true
              setTimeout () ->
                response.send reprimand(post.days_since, random_user)
              , (Math.floor(Math.random()*30)+30)*6000 # sometime in the next 1/2 - 1 hour
            else if !robot.brain.data.blog_praises[post.date.format('YYYY-MM-DD')]?
              response.send praise(post.author)
              robot.brain.data.blog_praises[post.date.format('YYYY-MM-DD')] = true
        else
          robot.brain.data.blog_reminders_users[current_date_str()].push(response.message.user.name)
