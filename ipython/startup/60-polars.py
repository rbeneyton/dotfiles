try:
    import polars as pl
    import polars.selector as cs

    # expand up to 40 columns
    pl.Config().set_tbl_cols(40)
    # pl.config.set_tbl_width_chars(width) ?

    # expand rows until 500
    pl.Config().set_tbl_rows(500)

except:
    pass
