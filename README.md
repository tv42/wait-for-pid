# wait-for-pid -- Wait for processes to exit

`wait-for-pid PID` is similar to the bash built-in command `wait`, except it works even when the processes started from elsewhere.

For example, the following will prevent the machine from suspending while the given processes are still running:

```console
$ systemd-inhibit --what=sleep wait-for-pid 1234 56789
```

Note that since `wait-for-pid` is not the parent (or subreaper) of the processes it waits for, it cannot know their exit status.
`wait-for-pid` exits with success once there are no more processes left to wait for.

## License

Licensed under either of

 * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.
