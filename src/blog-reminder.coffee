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

  robot.brain.data.blog_reminders ||= {}

  robot.hear /^(.+)$/i, (response) ->
    if response.match[1] == 'blog reset'
      date_str = moment().format('YYYY-MM-DD')
      response.send "resetting reminder for #{date_str}"
      robot.brain.data.blog_reminders[date_str] = undefined
    else
      # if it is after 1PM and we haven't been reminded today...
      if moment().hour() > 13 && !robot.brain.data.blog_reminders[moment().format('YYYY-MM-DD')]?
        robot.http("http://tech.patientslikeme.com/").get() (err, res, body) ->
          $ = cheerio.load(body)
          date_str = $('.article-metadata').first().find('li').first().text().split(':')[1].trim()
          days_since_last_post = moment.duration(moment().diff(moment(date_str, 'MMM, D YYYY')))

          # if it has been more than 30 days since the last post...
          if days_since_last_post > 30
            random_user = _.shuffle(robot.brain.data.users)[0].name
            robot.brain.data.blog_reminders[moment().format('YYYY-MM-DD')] = true

            setTimeout () ->
              response.send "It's been #{Math.floor(days_since_last_post.asDays())} days since " +
              "any of you #{_.shuffle(ADJECTIVES)[0]} #{_.shuffle(PLURAL_NOUNS)[0]} wrote for the blog! " +
              "Someone should soon, how about... #{random_user}? See https://github.com/patientslikeme/tech-blog"
            , (Math.floor(Math.random()*30)+30)*6000 # sometime in the next 1/2 - 1 hour

