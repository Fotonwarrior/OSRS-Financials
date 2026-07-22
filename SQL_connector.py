from sqlalchemy import create_engine, inspect
import pandas as pd
from dotenv import load_dotenv
import os

load_dotenv()


class Sql_Handler:
    def __init__(self):
        self.engine = create_engine(os.environ["OSRS_DWH_URL"])

    def save_dataobject(self, dataframe: pd.DataFrame, tablename: str) -> None:
        """Function to safe a dataframe to persistent storage"""
        if inspect(self.engine).has_table(tablename):
            dataframe.to_sql(name=tablename, con=self.engine, index=False, chunksize=500, method="multi", if_exists= 'append')
        else:
            raise ValueError(f"No databaseobject available for {tablename}")
        

