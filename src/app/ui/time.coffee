module.exports = time =
    today: moment().startOf('day')
    historyLimit: moment().startOf('week').subtract(2, 'weeks')

(updateToday = (->
    # every minute
    setTimeout (->
        time.today = moment().startOf('day')
        updateToday()
        return), moment().startOf('day').add(1, 'day').add(20, 'seconds').valueOf() - (new Date()).getTime()
    return))()


