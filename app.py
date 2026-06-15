import requests
import pandas as pd
import datetime
import numpy as np 
class ProfitFinderSession():
    "Object that handles communication with the OSRS prices wiki API"
    def __init__(self):
        self.url = "https://prices.runescape.wiki/api/v1/osrs"
        self.session = requests.Session()
        self.session.headers.update( {"User-Agent":"Appname: OSRS Profitfinder - Discord:remco995"})
    
    def _fetch_data(self, suffix, params = {}):
        "internal function that compiles the get request based on parameters"
        url = self.url + suffix
        response= self.session.get(url, params= params)
        data= response.json()["data"]
        return data

    def _fix_datetime(self, unixtime:int):
        if unixtime != np.nan:
            return datetime.datetime.fromtimestamp(int(unixtime))

    def fetch_mapping(self):
        return self._fetch_data("/mapping")

    def fetch_timeseries(self,itemId, timestep):
        valid_timesteps = ["5m", "1h", "6h", "24h"]
        params = {}
        if timestep in valid_timesteps:
            params.update({"id" : itemId, "timestep" : timestep})
            # df= pd.DataFrame(self._fetch_data(suffix= "/timeseries", params=params))
            # df["timestamp"] = df.timestamp.apply(lambda x :datetime.datetime.fromtimestamp(x))
            return df 

    
    def fetch_latest(self):
        response = self._fetch_data("/latest")
        flat_array= []
        for key in response.keys():
            record = {}
            record['id'] = key
            record.update(response[key])
            flat_array.append(record)
        df=pd.DataFrame(flat_array)
        df["lowTime2"] = df.lowTime.apply(lambda x : self._fix_datetime(x))
        # df["highTime"] = df.highTime.apply(lambda x : self._fix_datetime(x))
        return df


    
s= ProfitFinderSession()
df= s.fetch_latest()
#df["timestamp"] = df.timestamp.apply(lambda x :datetime.datetime.fromtimestamp(x))
print(df.head(100))
print(df.iloc(1)[4])
print(s._fix_datetime(0))
    
