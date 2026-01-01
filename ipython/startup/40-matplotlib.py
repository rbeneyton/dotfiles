try:
    import matplotlib as mpl
    import matplotlib.pyplot as plt

    plt.rcParams["figure.figsize"] = (15, 8)

    # latex
    # mpl.rc('font',**{'family':'sans-serif','sans-serif':['Helvetica']})
    mpl.rc("text", usetex=False)

    import seaborn as sns

    sns.set()
    sns.set_context("notebook")
    sns.set_palette(sns.color_palette("hls", 10))
    import itertools

    color = itertools.cycle(sns.color_palette())

    def show(block=False):
        root = plt.gcf().canvas._tkcanvas.winfo_toplevel()
        plt.gcf().show()
        if block:
            root.mainloop()

    def agg():
        mpl.use("Agg")
except:
    pass
