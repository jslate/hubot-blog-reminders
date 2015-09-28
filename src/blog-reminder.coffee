cheerio = require('cheerio')
moment = require('moment')
_ = require('underscore')

module.exports = (robot) ->

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
              response.send "It's been #{Math.floor(days_since_last_post.asDays())} days since someone wrote for the blog! Someone should soon, how about... #{random_user}?"
            , (Math.floor(Math.random()*30)+30)*6000 # sometime in the next 1/2 - 1 hour


