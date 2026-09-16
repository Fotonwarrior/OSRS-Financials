import requests
import pandas as pd
import datetime
import numpy as np 
from SQL_connector import Sql_Handler
from apscheduler.schedulers.background import BackgroundScheduler
import time

class ProfitFinderSession():
    "Object that handles communication with the OSRS prices wiki API and returns data in dataframe form"
    def __init__(self):
        self.url = "https://prices.runescape.wiki/api/v1/osrs"
        self.session = requests.Session()
        self.session.headers.update( {"User-Agent":"Appname: OSRS Profitfinder - Discord:remco995"})
        self.sql_handler = Sql_Handler()

    def full_run(self):
        print(f'{datetime.datetime.now()}:job started')
        self.fetch_mapping()
        self.fetch_latest()
        print(f'{datetime.datetime.now()}:job done!')

    def _fetch_data(self, suffix: str, params: dict = {})-> dict:
        "internal function that compiles the get request based on parameters"
        url = self.url + suffix
        response= self.session.get(url, params= params)
        data= response.json()
        return data

    def _fix_datetime(self, unixtime:int)->datetime.datetime:
        "internal function that handles the conversion of unixtime integers to human-readible datetime objects"
        try:
            return datetime.datetime.fromtimestamp(int(unixtime))
        except:
            return

    def fetch_mapping(self)-> pd.DataFrame:
        response= self._fetch_data("/mapping")
        df= pd.DataFrame(response)
        df['ingested_at'] = datetime.datetime.now()
        self.sql_handler.save_dataobject(dataframe=df, tablename="mapping", strategy="replace")


    def fetch_timeseries(self,itemId, timestep)-> pd.DataFrame:
        valid_timesteps = ["5m", "1h", "6h", "24h"]
        params = {}
        if timestep in valid_timesteps:
            params.update({"id" : itemId, "timestep" : timestep})
            response=self._fetch_data(suffix= "/timeseries", params=params)
            df= pd.DataFrame(response["data"])
            df["timestamp"] = df.timestamp.apply(lambda x :datetime.datetime.fromtimestamp(x))
            return df 

    def fetch_latest(self)-> pd.DataFrame:
        response = self._fetch_data("/latest")["data"]
        flat_array= []

        for key in response.keys():
            record = {}
            record['id'] = key
            record.update(response[key])
            flat_array.append(record)

        df=pd.DataFrame(flat_array)
        df["lowTime"] = df.lowTime.apply(lambda x : self._fix_datetime(x))
        df["highTime"] = df.highTime.apply(lambda x : self._fix_datetime(x))
        df['ingested_at'] = datetime.datetime.now()
        df = df.rename(columns={"highTime": "hightime", "lowTime": "lowtime"})
        self.sql_handler.save_dataobject(dataframe=df, tablename="pricelog", strategy="append")



    
s= ProfitFinderSession()
s.full_run()                      # meteen één keer

sched = BackgroundScheduler(timezone="UTC")
sched.add_job(s.full_run, "interval", minutes=5, max_instances=1, coalesce=True)
sched.start()     

while True:
    time.sleep(1)