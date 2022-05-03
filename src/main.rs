use anyhow::Context;
use clap::App;
use epoll_rs as epoll;
use std::collections::hash_map::HashMap;
use std::os::unix::io::{AsRawFd, FromRawFd, RawFd};
use std::{fs::File, io};

fn pidfd_open(pid: libc::pid_t, flags: libc::c_uint) -> io::Result<File> {
    let ret = unsafe { libc::syscall(libc::SYS_pidfd_open, pid, flags) };
    if ret == -1 {
        Err(io::Error::last_os_error())
    } else {
        let file = unsafe { std::fs::File::from_raw_fd(ret as RawFd) };
        Ok(file)
    }
}

struct State<'a> {
    pid: libc::pid_t,
    token: epoll::Token<'a, File>,
}

fn main() -> anyhow::Result<()> {
    let app = App::new("wait-for-pid").arg(
        clap::Arg::new("PID")
            .required(true)
            .multiple_occurrences(true),
    );
    let matches = app.get_matches();
    let pids: Vec<libc::pid_t> = matches.values_of_t_or_exit("PID");

    let mut remaining: HashMap<RawFd, State> = HashMap::with_capacity(pids.len());
    let poller = epoll::Epoll::new()?;

    for pid in pids {
        let pidfd = pidfd_open(pid, 0).with_context(|| format!("cannot add PID: {}", pid))?;
        let fd = pidfd.as_raw_fd();
        let token = poller.add(pidfd, epoll::Opts::IN)?;
        remaining.insert(fd, State { pid, token });
    }

    while !remaining.is_empty() {
        let maybe_event = poller.wait_one().map(Some).or_else(|error| {
            if error.kind() == std::io::ErrorKind::Interrupted {
                Ok(None)
            } else {
                Err(error)
            }
        })?;
        if let Some(event) = maybe_event {
            let fd = event.fd();
            let state = remaining.remove(&fd);
            match state {
                None => {
                    println!("unknown fd={}", fd)
                }
                Some(state) => {
                    poller.remove(state.token)?;
                    println!("exit {}", state.pid)
                }
            }
        }
    }
    Ok(())
}
