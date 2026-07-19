#!{{trim (command_output "realpath ~")}}/.cargo/bin/rust-script
// usage: hypr-ws.rs go <1-9> [move]     workspace N on the focused monitor
//        hypr-ws.rs step <+1|-1> [move] prev/next, clamped to the monitor's set
//        hypr-ws.rs watch               daemon: binds each monitor's tag decade
//                                       (ids = monitor_id*10 + [1..9]) to its
//                                       runtime name, and on monitor removal
//                                       adopts its windows onto the remaining
//                                       tags (Ei -> Mi). no monitor name is
//                                       ever read from the config
// use hyprland's IPC socket directly

use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;

fn socket(name: &str) -> String {
    format!(
        "{}/hypr/{}/{name}",
        std::env::var("XDG_RUNTIME_DIR").unwrap(),
        std::env::var("HYPRLAND_INSTANCE_SIGNATURE").unwrap()
    )
}

// one connection per request, like hyprctl
fn request(msg: &str) -> String {
    let mut s = UnixStream::connect(socket(".socket.sock")).unwrap();
    s.write_all(msg.as_bytes()).unwrap();
    let mut reply = String::new();
    s.read_to_string(&mut reply).unwrap();
    reply
}

// integer value of the first "key": occurrence in hyprland's json reply
fn field(json: &str, key: &str) -> i64 {
    let needle = format!("\"{key}\":");
    let rest = json[json.find(&needle).unwrap() + needle.len()..].trim_start();
    let end = rest
        .find(|c: char| !c.is_ascii_digit() && c != '-')
        .unwrap();
    rest[..end].parse().unwrap()
}

// (name, id, active workspace id) per monitor
fn monitors() -> Vec<(String, i64, i64)> {
    let mut v: Vec<(String, i64, i64)> = Vec::new();
    for line in request("monitors").lines() {
        if let Some(rest) = line.strip_prefix("Monitor ") {
            let (name, rest) = rest.split_once(" (ID ").unwrap();
            let id = rest.split(')').next().unwrap().parse().unwrap();
            v.push((name.to_string(), id, 0));
        } else if let Some(rest) = line.trim_start().strip_prefix("active workspace: ") {
            v.last_mut().unwrap().2 = rest.split_whitespace().next().unwrap().parse().unwrap();
        }
    }
    v
}

// bind every monitor's tag decade to its runtime name; persistent:true
// materializes the full set so each waybar bar shows all nine tags
fn sync_decades() {
    let mons = monitors();
    let mut batch = String::new();
    for (name, id, _) in &mons {
        for tag in 1..=9 {
            batch += &format!("keyword workspace {},monitor:{name},persistent:true;", id * 10 + tag);
        }
    }
    // relocate tag workspaces stranded on the wrong monitor (hyprland grabs a
    // free workspace for a freshly connected output before the rules above exist)
    for line in request("workspaces").lines() {
        if let Some(rest) = line.strip_prefix("workspace ID ") {
            let mut words = rest.split_whitespace();
            let id: i64 = words.next().unwrap().parse().unwrap();
            let on = words.nth(3).unwrap().trim_end_matches(':');
            if (1..=9).contains(&(id % 10)) {
                if let Some((owner, ..)) = mons.iter().find(|(_, mid, _)| *mid == id / 10) {
                    if owner != on {
                        batch += &format!("dispatch moveworkspacetomonitor {id} {owner};");
                    }
                }
            }
        }
    }
    // switch any monitor left on a foreign workspace (e.g. the auto-assigned
    // one) to its own first tag, then give focus back
    let focused = field(&request("j/activeworkspace"), "monitorID");
    let mut moved = false;
    for (_, id, active) in &mons {
        if !(1..=9).contains(&(active - id * 10)) {
            batch += &format!("dispatch workspace {};", id * 10 + 1);
            moved = true;
        }
    }
    if moved {
        if let Some((name, ..)) = mons.iter().find(|(_, id, _)| *id == focused) {
            batch += &format!("dispatch focusmonitor {name};");
        }
    }
    request(&format!("[[BATCH]]{batch}"));
}

// move every window on a workspace whose monitor is gone to tag id%10, then
// leave the active workspace if it is orphaned itself
fn adopt_orphans() {
    // workspace decades of the remaining monitors
    let valid: Vec<i64> = monitors().iter().map(|&(_, id, _)| id * 10).collect();
    let orphan = |id: i64| id > 10 && id % 10 != 0 && !valid.contains(&(id / 10 * 10));
    let mut batch = String::new();
    // drop persistence on the dead decade so its emptied tags disappear
    for line in request("workspaces").lines() {
        if let Some(rest) = line.strip_prefix("workspace ID ") {
            let id: i64 = rest.split_whitespace().next().unwrap().parse().unwrap();
            if orphan(id) {
                batch += &format!("keyword workspace {id},persistent:false;");
            }
        }
    }
    let mut addr = "";
    for line in request("clients").lines() {
        if let Some(rest) = line.strip_prefix("Window ") {
            addr = rest.split_whitespace().next().unwrap();
        } else if let Some(rest) = line.trim_start().strip_prefix("workspace: ") {
            let id: i64 = rest.split_whitespace().next().unwrap().parse().unwrap();
            if orphan(id) {
                batch += &format!("dispatch movetoworkspacesilent {},address:0x{addr};", id % 10);
            }
        }
    }
    if !batch.is_empty() {
        request(&format!("[[BATCH]]{batch}"));
    }
    let active = field(&request("j/activeworkspace"), "id");
    if orphan(active) {
        request(&format!("dispatch workspace {}", active % 10));
    }
}

fn watch() {
    sync_decades();
    let events = UnixStream::connect(socket(".socket2.sock")).unwrap();
    for line in BufReader::new(events).lines() {
        let line = line.unwrap();
        if line.starts_with("monitoradded>>") {
            // let hyprland finish assigning the new output a workspace
            std::thread::sleep(std::time::Duration::from_millis(100));
            sync_decades();
        } else if line.starts_with("monitorremoved>>") {
            // let hyprland finish reassigning the dead monitor's workspaces
            std::thread::sleep(std::time::Duration::from_millis(100));
            adopt_orphans();
            // waybar freezes and hyprpaper crashes when an output dies: restart
            // them (spawned by hyprland so the daemon holds no child to reap)
            for prog in ["waybar", "hyprpaper"] {
                let _ = std::process::Command::new("pkill").args(["-x", prog]).status();
            }
            std::thread::sleep(std::time::Duration::from_millis(200));
            request("[[BATCH]]dispatch exec waybar;dispatch exec hyprpaper");
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let target = match args[1].as_str() {
        "watch" => return watch(),
        "go" => {
            field(&request("j/activeworkspace"), "monitorID") * 10
                + args[2].parse::<i64>().unwrap()
        }
        "step" => {
            let id = field(&request("j/activeworkspace"), "id");
            let next = id + args[2].parse::<i64>().unwrap();
            let base = id / 10 * 10;
            if next < base + 1 || next > base + 9 {
                return;
            }
            next
        }
        cmd => panic!("unknown command {cmd}"),
    };
    let dispatcher = match args.get(3).map(String::as_str) {
        Some("move") => "movetoworkspace",
        _ => "workspace",
    };
    request(&format!("dispatch {dispatcher} {target}"));
}
