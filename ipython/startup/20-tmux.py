import os
import subprocess

if "TMUX" in os.environ:
    try:
        if "TMUX_INSTALL" in os.environ:
            tmux = os.environ["TMUX_INSTALL"] + "/bin/tmux"
        else:
            tmux = "tmux"
        txt = subprocess.check_output(
            f"{tmux} show-env | sed -n 's/^DISPLAY=//p'", shell=True
        )
        txt = txt.decode(encoding="UTF-8")
        display = txt.splitlines()[0]
        os.environ["DISPLAY"] = display
    except:
        pass
