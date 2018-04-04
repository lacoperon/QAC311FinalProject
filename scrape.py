'''
This script is based on the one written here:
https://github.com/bpb27/twitter_scraping

It is only slightly modified
'''

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException, StaleElementReferenceException, NoSuchWindowException
from selenium.webdriver.firefox.options import Options
from time import sleep
import json
import datetime

def format_day(date):
    day = '0' + str(date.day) if len(str(date.day)) == 1 else str(date.day)
    month = '0' + str(date.month) if len(str(date.month)) == 1 else str(date.month)
    year = str(date.year)
    return '-'.join([year, month, day])

def form_url(user, since, until):
    p1 = 'https://twitter.com/search?f=tweets&vertical=default&q=from%3A'
    p2 =  user + '%20since%3A' + since + '%20until%3A' + until + 'include%3Aretweets&src=typd'
    return p1 + p2


def increment_day(date, i):
    return date + datetime.timedelta(days=i)

def getURL(driver, url, num_errors=0):
    try:
        driver.get(url)
    except NoSuchWindowException as e:
        if num_errors > 10:
            print("There were 10 NoSuchWindowExceptions for one page...")
            raise e
        num_errors += 1
        driver = webdriver.Firefox()
        driver = getURL(driver, url, num_errors)
        # Creates a new driver, because the connection to this one has beene lost

        driver.get(url)
    return driver

def run(user, start, end):
    # only edit these if you're having problems
    delay = 1.5  # time to wait on each page load before reading the page
    driver = webdriver.Firefox()  # options are Chrome() Firefox() Safari()

    # don't mess with this stuff
    twitter_ids_filename = '{}_all_ids.json'.format(user)
    days = (end - start).days + 1
    id_selector = '.time a.tweet-timestamp'
    tweet_selector = 'li.js-stream-item'
    user = user.lower()
    ids = []

    for day in range(days):
        d1 = format_day(increment_day(start, 0))
        d2 = format_day(increment_day(start, 1))
        url = form_url(user, d1, d2)
        print(url)
        print(d1)
        driver = getURL(driver, url)
        sleep(delay)

        try:
            found_tweets = driver.find_elements_by_css_selector(tweet_selector)
            increment = 10

            # If the driver is lost track of somewhere in here,
            # we want the process to fail
            while len(found_tweets) >= increment:
                print('scrolling down to load more tweets')
                driver.execute_script('window.scrollTo(0, document.body.scrollHeight);')
                sleep(delay)
                found_tweets = driver.find_elements_by_css_selector(tweet_selector)
                increment += 10

            print('{} tweets found, {} total'.format(len(found_tweets), len(ids)))

            for tweet in found_tweets:
                try:
                    id = tweet.find_element_by_css_selector(id_selector).get_attribute('href').split('/')[-1]
                    ids.append(id)
                except StaleElementReferenceException as e:
                    print('lost element reference', tweet)

        except NoSuchElementException:
            print('no tweets on this day')

        start = increment_day(start, 1)


    try:
        with open(twitter_ids_filename) as f:
            all_ids = ids + json.load(f)
            data_to_write = list(set(all_ids))
            print('tweets found on this scrape: ', len(ids))
            print('total tweet count: ', len(data_to_write))
    except FileNotFoundError:
        with open(twitter_ids_filename, 'w') as f:
            all_ids = ids
            data_to_write = list(set(all_ids))
            print('tweets found on this scrape: ', len(ids))
            print('total tweet count: ', len(data_to_write))

    with open(twitter_ids_filename, 'w') as outfile:
        json.dump(data_to_write, outfile)

    print('all done here')
    driver.close()

if __name__ == "__main__":
    # edit these three variables
    user = 'foxnews'
    start = datetime.datetime(2017, 5, 1)  # year, month, day
    end = datetime.datetime(2017, 6, 30)  # year, month, day
    run(user, start, end)
