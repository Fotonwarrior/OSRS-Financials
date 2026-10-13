from sqlalchemy import create_engine, inspect, text
import pandas as pd
from dotenv import load_dotenv
import os

load_dotenv()


class Sql_Handler:
    def __init__(self):
        self.engine = create_engine(os.environ["OSRS_DWH_URL"])

    def save_dataobject(self, dataframe: pd.DataFrame, tablename: str, strategy: str) -> None:
        """Function to safe a dataframe to persistent storage"""
        if not inspect(self.engine).has_table(tablename):
            raise ValueError(f"No databaseobject available for {tablename}")

        # pandas' "replace" drops the table, which fails when views depend on it
        # and discards the schema from SQL Scripts/. Instead, empty the table and
        # append, in one transaction so readers never see an empty table.
        with self.engine.begin() as conn:
            if strategy == "replace":
                conn.execute(text(f'DELETE FROM "{tablename}"'))
            dataframe.to_sql(name=tablename, con=conn, index=False, chunksize=500, method="multi", if_exists="append")
        

