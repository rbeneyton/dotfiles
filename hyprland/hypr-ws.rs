#!{{trim (command_output "realpath ~")}}/.cargo/bin/rust-script
// usage: hypr-ws.rs go <1-9> [move]     workspace N on the focused monitor
//        hypr-ws.rs step <+1|-1> [move] prev/next, clamped to the monitor's set
//        hypr-ws.rs watch               daemon: on monitor removal, adopt its
//                                       windows onto the remaining tags (Ei -> Mi)
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

// move every window on a workspace whose monitor is gone to tag id%10, then
// leave the active workspace if it is orphaned itself
fn adopt_orphans() {
    let mut valid = Vec::new(); // workspace decades of the remaining monitors
    for line in request("monitors").lines() {
        if let Some(rest) = line.split_once("(ID ").filter(|_| line.starts_with("Monitor ")) {
            let id: i64 = rest.1.split(')').next().unwrap().parse().unwrap();
            valid.push(id * 10);
        }
    }
    let orphan = |id: i64| id > 10 && id % 10 != 0 && !valid.contains(&(id / 10 * 10));
    let mut batch = String::new();
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
    let events = UnixStream::connect(socket(".socket2.sock")).unwrap();
    for line in BufReader::new(events).lines() {
        if line.unwrap().starts_with("monitorremoved>>") {
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
