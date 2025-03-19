# zig open containers

TODO: Doc

## Namespaces

```bash
man 7 namespaces
```

```
Namespace   Flag              Page                    Isolates
─────────────────────────────────────────────────────────────────────────────────────────
Cgroup      CLONE_NEWCGROUP   cgroup_namespaces(7)    Cgroup root directory
IPC         CLONE_NEWIPC      ipc_namespaces(7)       System V IPC, POSIX message queues
Network     CLONE_NEWNET      network_namespaces(7)   Network devices, stacks, ports, etc.
Mount       CLONE_NEWNS       mount_namespaces(7)     Mount points
PID         CLONE_NEWPID      pid_namespaces(7)       Process IDs
Time        CLONE_NEWTIME     time_namespaces(7)      Boot and monotonic clocks
User        CLONE_NEWUSER     user_namespaces(7)      User and group IDs
UTS         CLONE_NEWUTS      uts_namespaces(7)       Hostname and NIS domain name
```
