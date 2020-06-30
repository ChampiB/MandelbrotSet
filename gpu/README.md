Running the binary produced by those sources can lead the following errors on ARM architechture:

```dbus[29049]: arguments to dbus_message_new_method_call() were incorrect, assertion "path != NULL" failed in file ../../../dbus/dbus-message.c line 1362.
This is normally a bug in some application using the D-Bus library.

  D-Bus not built with -rdynamic so unable to print a backtrace
Aborted (core dumped)```

If this happens the following command should fix the problem:

```DBUS_FATAL_WARNINGS=0 ./my_binary.out```

This source file can be compiled and ran using:
```nvcc main.cu -lSDL2 && DBUS_FATAL_WARNINGS=0 ./a.out```
