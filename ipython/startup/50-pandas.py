try:
    import numpy as np
    import pandas as pd

    # display all columns
    pd.set_option("display.max_colwidth", 1000)

    # do not resume rows
    pd.options.display.max_rows = 500
    # do not resume cols
    pd.options.display.max_cols = 40

    # display all columns
    pd.set_option("display.expand_frame_repr", False)

    # pd.set_option('display.max_cols', 10000)
    date_parser = lambda date: pd.datetime.strptime(date, "%Y-%m-%d %H:%M:%S.%f")
except:
    pass
