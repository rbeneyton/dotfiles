#!/usr/bin/env rust-script
// waybar streaming module: fixed-width network/disk rates, one line per period
// usage: rates.rs net <iface> | rates.rs io <disk> | rates.rs cpu|mem|load
// net: SI units (1000); io: 1024-based, [1000;1023] saturates at 999 to keep 3 digits
// '999 B/s' -> '  1kB/s' -> '999kB/s' -> '  1MB/s'
// cpu/mem: '{:2}' percent (saturate 99); load: '{:5.2}' 1min avg (saturate 99.99)

use std::io::Write;
use std::time::Duration;

const PERIOD: Duration = Duration::from_secs(3);

fn counters(mode: &str, dev: &str) -> (u64, u64) {
    match mode {
        "net" => {
            // /proc/net/dev: "iface: rx_bytes ... [8 cols] tx_bytes ..."
            let data = std::fs::read_to_string("/proc/net/dev").unwrap();
            let prefix = format!("{dev}:");
            let line = data
                .lines()
                .find(|l| l.trim_start().starts_with(&prefix))
                .unwrap_or_else(|| panic!("no interface {dev}"));
            // counters may be glued to the colon, split on it first
            let f: Vec<u64> = line
                .split_once(':')
                .unwrap()
                .1
                .split_whitespace()
                .map(|x| x.parse().unwrap_or(0))
                .collect();
            (f[0], f[8])
        }
        "io" => {
            // /proc/diskstats: "maj min dev ... sectors_read (6th) ... sectors_written (10th)"
            let data = std::fs::read_to_string("/proc/diskstats").unwrap();
            let f: Vec<&str> = data
                .lines()
                .map(|l| l.split_whitespace().collect::<Vec<_>>())
                .find(|f| f.get(2) == Some(&dev))
                .unwrap_or_else(|| panic!("no disk {dev}"));
            (
                f[5].parse::<u64>().unwrap_or(0) * 512,
                f[9].parse::<u64>().unwrap_or(0) * 512,
            )
        }
        _ => panic!("usage: rates.rs net|io <device>"),
    }
}

fn human(rate: u64, base: u64) -> String {
    let mut x = rate as f64;
    for unit in [" B", "kB", "MB"] {
        if x < base as f64 {
            return format!("{:3}{unit}/s", (x as u64).min(999));
        }
        x /= base as f64;
    }
    format!("{:3}GB/s", (x as u64).min(999))
}

// cumulative (busy_total, idle) jiffies from /proc/stat's aggregate "cpu" line
fn cpu_times() -> (u64, u64) {
    let data = std::fs::read_to_string("/proc/stat").unwrap();
    let v: Vec<u64> = data
        .lines()
        .next()
        .unwrap()
        .split_whitespace()
        .skip(1)
        .map(|x| x.parse().unwrap_or(0))
        .collect();
    // idle + iowait vs. the sum of every column
    (v.iter().sum(), v[3] + v.get(4).copied().unwrap_or(0))
}

// used memory as a percentage, from MemTotal/MemAvailable in /proc/meminfo
fn mem_pct() -> u64 {
    let data = std::fs::read_to_string("/proc/meminfo").unwrap();
    let field = |k: &str| {
        data.lines()
            .find(|l| l.starts_with(k))
            .and_then(|l| l.split_whitespace().nth(1))
            .and_then(|x| x.parse::<u64>().ok())
            .unwrap_or(0)
    };
    let total = field("MemTotal:");
    let avail = field("MemAvailable:");
    if total == 0 {
        0
    } else {
        100 * (total - avail) / total
    }
}

fn load1() -> f64 {
    let data = std::fs::read_to_string("/proc/loadavg").unwrap();
    data.split_whitespace().next().unwrap().parse().unwrap_or(0.0)
}

// one fixed-width stat per line: cpu% (busy over the period), mem%, or 1min load
fn run_stat(mode: &str) -> ! {
    let mut prev = cpu_times();
    loop {
        std::thread::sleep(PERIOD);
        let out = match mode {
            "cpu" => {
                let now = cpu_times();
                let total = now.0.saturating_sub(prev.0);
                let idle = now.1.saturating_sub(prev.1);
                prev = now;
                let cpu = if total == 0 { 0 } else { 100 * (total - idle) / total };
                format!("{:2}", cpu.min(99))
            }
            "mem" => format!("{:2}", mem_pct().min(99)),
            _ => format!("{:5.2}", load1().min(99.99)),
        };
        println!("{out}");
        std::io::stdout().flush().unwrap();
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if matches!(args[1].as_str(), "cpu" | "mem" | "load") {
        run_stat(&args[1]);
    }
    let (mode, dev) = (args[1].as_str(), args[2].as_str());
    let (labels, base) = match mode {
        "net" => (("D", "U"), 1000),
        _ => (("R", "W"), 1024),
    };
    let mut prev = counters(mode, dev);
    loop {
        std::thread::sleep(PERIOD);
        let now = counters(mode, dev);
        let a = now.0.saturating_sub(prev.0) / PERIOD.as_secs();
        let b = now.1.saturating_sub(prev.1) / PERIOD.as_secs();
        prev = now;
        println!(
            "{}{} {}{}",
            labels.0,
            human(a, base),
            labels.1,
            human(b, base)
        );
        std::io::stdout().flush().unwrap();
    }
}
