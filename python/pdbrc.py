histfile_g = None


def pdbrc_setup():
    import readline
    import pathlib
    import atexit

    global histfile_g

    histfile_g = pathlib.Path('{{trim (command_output "realpath ~")}}')
    histfile_g /= ".cache"
    histfile_g /= "python"
    histfile_g.mkdir(parents=True, exist_ok=True)
    histfile_g /= "pdb.history"
    try:
        readline.read_history_file(histfile_g)
    except IOError:
        pass

    atexit.register(readline.write_history_file, histfile_g)
    readline.set_history_length(5000)


def pdbrc_save_history():
    import readline

    global histfile_g

    if histfile_g:
        readline.write_history_file(histfile_g)
