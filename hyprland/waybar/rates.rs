#!{{trim (command_output "realpath ~")}}/.cargo/bin/rust-script
// waybar streaming module: fixed-width network/disk rates, one line per period
// usage: rates.rs net <iface> | rates.rs io <disk> | rates.rs cpu|mem|load
// net: SI units (1000); io: 1024-based, [1000;1023] saturates at 999 to keep 3 digits
// '999 B/s' -> '  1kB/s' -> '999kB/s' -> '  1MB/s'
// cpu/mem: '{:2}' percent (saturate 99); load: '{:5.2}' 1min avg (saturate 99.99)
// no heap allocation in the loop: /proc is read into a reused stack buffer and
// output is formatted into a stack Cursor before a single write

use std::io::{Read, Write};
use std::time::Duration;

const PERIOD: Duration = Duration::from_secs(3);

// slurp a small /proc file into a caller-owned stack buffer, no allocation
fn read_proc<'a>(path: &str, buf: &'a mut [u8]) -> &'a str {
    let mut f = std::fs::File::open(path).unwrap();
    let mut n = 0;
    while n < buf.len() {
        match f.read(&mut buf[n..]) {
            Ok(0) => break,
            Ok(k) => n += k,
            Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
            Err(e) => panic!("read {path}: {e}"),
        }
    }
    std::str::from_utf8(&buf[..n]).unwrap()
}

fn counters(mode: &str, dev: &str, buf: &mut [u8]) -> (u64, u64) {
    match mode {
        "net" => {
            // /proc/net/dev: "iface: rx_bytes ... [8 cols] tx_bytes ..."
            let data = read_proc("/proc/net/dev", buf);
            let line = data
                .lines()
                .find(|l| {
                    let t = l.trim_start();
                    t.strip_prefix(dev).is_some_and(|r| r.starts_with(':'))
                })
                .unwrap_or_else(|| panic!("no interface {dev}"));
            // counters may be glued to the colon, split on it first
            let mut it = line.split_once(':').unwrap().1.split_whitespace();
            let rx = it.next().unwrap().parse::<u64>().unwrap_or(0);
            let tx = it.nth(7).unwrap().parse::<u64>().unwrap_or(0);
            (rx, tx)
        }
        "io" => {
            // /proc/diskstats: "maj min dev ... sectors_read (6th) ... sectors_written (10th)"
            let data = read_proc("/proc/diskstats", buf);
            let line = data
                .lines()
                .find(|l| l.split_whitespace().nth(2) == Some(dev))
                .unwrap_or_else(|| panic!("no disk {dev}"));
            let mut it = line.split_whitespace();
            let read = it.nth(5).unwrap().parse::<u64>().unwrap_or(0) * 512;
            let written = it.nth(3).unwrap().parse::<u64>().unwrap_or(0) * 512;
            (read, written)
        }
        _ => panic!("usage: rates.rs net|io <device>"),
    }
}

fn write_human<W: Write>(w: &mut W, rate: u64, base: u64) {
    let mut x = rate as f64;
    for unit in [" B", "kB", "MB"] {
        if x < base as f64 {
            write!(w, "{:3}{unit}/s", (x as u64).min(999)).unwrap();
            return;
        }
        x /= base as f64;
    }
    write!(w, "{:3}GB/s", (x as u64).min(999)).unwrap();
}

// cumulative (busy_total, idle) jiffies from /proc/stat's aggregate "cpu" line
fn cpu_times(buf: &mut [u8]) -> (u64, u64) {
    let data = read_proc("/proc/stat", buf);
    let line = data.lines().next().unwrap();
    // idle + iowait (cols 3,4) vs. the sum of every column
    let (mut total, mut idle) = (0u64, 0u64);
    for (i, x) in line.split_whitespace().skip(1).enumerate() {
        let v = x.parse::<u64>().unwrap_or(0);
        total += v;
        if i == 3 || i == 4 {
            idle += v;
        }
    }
    (total, idle)
}

// used memory as a percentage, from MemTotal/MemAvailable in /proc/meminfo
fn mem_pct(buf: &mut [u8]) -> u64 {
    let data = read_proc("/proc/meminfo", buf);
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

fn load1(buf: &mut [u8]) -> f64 {
    let data = read_proc("/proc/loadavg", buf);
    data.split_whitespace()
        .next()
        .unwrap()
        .parse()
        .unwrap_or(0.0)
}

// one fixed-width stat per line: cpu% (busy over the period), mem%, or 1min load
fn run_stat(mode: &str) -> ! {
    let mut buf = [0u8; 16384];
    let mut out = std::io::stdout().lock();
    let mut prev = cpu_times(&mut buf);
    loop {
        std::thread::sleep(PERIOD);
        let mut line = [0u8; 16];
        let mut cur = std::io::Cursor::new(&mut line[..]);
        match mode {
            "cpu" => {
                let now = cpu_times(&mut buf);
                let total = now.0.saturating_sub(prev.0);
                let idle = now.1.saturating_sub(prev.1);
                prev = now;
                let cpu = if total == 0 {
                    0
                } else {
                    100 * (total - idle) / total
                };
                write!(cur, "{:2}", cpu.min(99)).unwrap();
            }
            "mem" => write!(cur, "{:2}", mem_pct(&mut buf).min(99)).unwrap(),
            _ => write!(cur, "{:5.2}", load1(&mut buf).min(99.99)).unwrap(),
        }
        let n = cur.position() as usize;
        out.write_all(&line[..n]).unwrap();
        out.write_all(b"\n").unwrap();
        out.flush().unwrap();
    }
}

fn main() {
    let mut args = std::env::args();
    let _ = args.next();
    let arg1 = args
        .next()
        .expect("usage: rates.rs net|io <device> | cpu|mem|load");
    if matches!(arg1.as_str(), "cpu" | "mem" | "load") {
        run_stat(&arg1);
    }
    let dev = args.next().expect("usage: rates.rs net|io <device>");
    let mode = arg1.as_str();
    let (labels, base) = match mode {
        "net" => (("D", "U"), 1000u64),
        _ => (("R", "W"), 1024u64),
    };
    let mut buf = [0u8; 16384];
    let mut out = std::io::stdout().lock();
    let mut prev = counters(mode, &dev, &mut buf);
    loop {
        std::thread::sleep(PERIOD);
        let now = counters(mode, &dev, &mut buf);
        let a = now.0.saturating_sub(prev.0) / PERIOD.as_secs();
        let b = now.1.saturating_sub(prev.1) / PERIOD.as_secs();
        prev = now;
        let mut line = [0u8; 32];
        let mut cur = std::io::Cursor::new(&mut line[..]);
        write!(cur, "{}", labels.0).unwrap();
        write_human(&mut cur, a, base);
        write!(cur, " {}", labels.1).unwrap();
        write_human(&mut cur, b, base);
        let n = cur.position() as usize;
        out.write_all(&line[..n]).unwrap();
        out.write_all(b"\n").unwrap();
        out.flush().unwrap();
    }
}
